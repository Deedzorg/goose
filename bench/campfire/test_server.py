#!/usr/bin/env python3
"""Independent protocol and database checks for the Campfire port."""

import argparse
import base64
import concurrent.futures
import ctypes
import ctypes.util
import gzip
import hashlib
import hmac
import http.client
import json
import os
from pathlib import Path
import re
import secrets
import socket
import sqlite3
import subprocess
import tempfile
import time
from urllib.parse import quote, urlencode


def cookie(secret, token, purpose="cookie.session_token", expiry="2099-01-01T00:00:00.000Z"):
    message = base64.b64encode(json.dumps(token).encode()).decode()
    payload = base64.b64encode(json.dumps({"_rails": {
        "message": message, "exp": expiry, "pur": purpose,
    }}, separators=(",", ":")).encode())
    key = hashlib.pbkdf2_hmac("sha256", secret.encode(), b"signed cookie", 1000, 64)
    mac = hmac.new(key, payload, hashlib.sha1).hexdigest()
    return "session_token=" + quote(payload.decode() + "--" + mac, safe="")


def fixture(path):
    db = sqlite3.connect(path)
    db.executescript("""
        PRAGMA journal_mode=WAL;
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, status INTEGER, email_address TEXT, password_digest TEXT);
        CREATE TABLE sessions (id INTEGER PRIMARY KEY, user_id INTEGER, token TEXT,
                               created_at TEXT, updated_at TEXT, last_active_at TEXT);
        CREATE TABLE rooms (id INTEGER PRIMARY KEY, name TEXT, type TEXT,
                            updated_at TEXT, messages_count INTEGER DEFAULT 0);
        CREATE TABLE memberships (room_id INTEGER, user_id INTEGER, involvement TEXT,
                                  unread_at TEXT, updated_at TEXT);
        CREATE TABLE messages (id INTEGER PRIMARY KEY, room_id INTEGER, creator_id INTEGER,
                               client_message_id TEXT, created_at TEXT, updated_at TEXT);
        CREATE TABLE action_text_rich_texts (id INTEGER PRIMARY KEY, name TEXT, record_type TEXT,
                                             record_id INTEGER, body TEXT, created_at TEXT, updated_at TEXT);
        CREATE VIRTUAL TABLE message_search_index USING fts5(body, tokenize=porter);
        CREATE INDEX messages_order ON messages(room_id, created_at);
        INSERT INTO users(id,name,status,email_address) VALUES (1, 'Alice & Bob', 0, 'alice@example.test'), (2, 'Hidden user', 0, 'hidden@example.test');
        INSERT INTO sessions(id,user_id,token) VALUES (1, 1, 'test-session'), (2, 2, 'hidden-session');
        INSERT INTO rooms(id,name,type) VALUES (1, 'Watercooler & news', 'Rooms::Open'),
                                               (2, 'Private room', 'Rooms::Closed');
        INSERT INTO memberships(room_id,user_id,involvement) VALUES (1, 1, 'mentions'), (2, 2, 'mentions');
    """)
    for i in range(1, 101):
        db.execute("INSERT INTO messages(id,room_id,creator_id,client_message_id,created_at) VALUES (?,1,1,?,?)",
                   (i, f"client-{i}", f"2026-10-01T00:{i // 60:02}:{i % 60:02}"))
        db.execute("INSERT INTO message_search_index(rowid,body) VALUES (?,?)",
                   (i, f"Coffee message {i}: <script>alert('x')</script> & text" if i % 3 == 0
                    else f"Message number {i}"))
    db.execute("INSERT INTO messages(id,room_id,creator_id,client_message_id,created_at) VALUES (101,2,2,'hidden','2026-10-01T01:00:00')")
    db.execute("INSERT INTO message_search_index(rowid,body) VALUES (101,'Coffee secret')")
    if os.name != "nt":
        crypt = ctypes.CDLL(ctypes.util.find_library("crypt"))
        crypt.crypt.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        crypt.crypt.restype = ctypes.c_char_p
        password_digest = crypt.crypt(b"test-password", b"$2b$04$abcdefghijklmnopqrstuu").decode()
        db.execute("UPDATE users SET password_digest=? WHERE id=1", (password_digest,))
    db.commit()
    db.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--fixture-root", type=Path,
                        help="fixture parent directory (default: operating-system temporary storage)")
    args = parser.parse_args()
    executable = args.executable.resolve()
    with tempfile.TemporaryDirectory(prefix="campfire-integration-", dir=args.fixture_root) as directory:
        work = Path(directory)
        database = work / "campfire.sqlite3"
        fixture(database)
        secret = secrets.token_hex(64)
        auth = cookie(secret, "test-session")
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = dict(os.environ, DATABASE_PATH=str(database), SECRET_KEY_BASE=secret, PORT=str(port))
        with (work / "server.log").open("w+") as log:
            server = subprocess.Popen([str(executable)], env=env, stdout=log, stderr=log,
                                      creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
            try:
                def request(path, credential=auth, method="GET", gzip_body=True, data=None, extra_headers=None):
                    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
                    headers = {"Accept-Encoding": "gzip" if gzip_body else "identity"}
                    if credential:
                        headers["Cookie"] = credential
                    if extra_headers:
                        headers.update(extra_headers)
                    try:
                        conn.request(method, path, body=data, headers=headers)
                        response = conn.getresponse()
                        body = response.read()
                        if method != "HEAD" and response.getheader("Content-Encoding") == "gzip":
                            body = gzip.decompress(body)
                        return response.status, body.decode(), dict(response.getheaders())
                    finally:
                        conn.close()

                for _ in range(200):
                    if server.poll() is not None:
                        raise AssertionError(f"server exited {server.returncode}")
                    try:
                        assert request("/up", credential=None)[0] == 200
                        break
                    except ConnectionRefusedError:
                        time.sleep(0.05)
                else:
                    raise AssertionError("server did not start")

                def ids(body):
                    return list(map(int, re.findall(r'data-message-id="(\d+)"', body)))

                if os.name != "nt":
                    form = urlencode({"email_address": "alice@example.test", "password": "test-password"})
                    login_headers = {"Content-Type": "application/x-www-form-urlencoded", "Sec-Fetch-Site": "same-origin"}
                    status, _, headers = request("/session", credential=None, method="POST", data=form, extra_headers=login_headers)
                    assert status == 302, status
                    session = headers["Set-Cookie"].split(";", 1)[0]
                    assert request("/rooms/1", credential=session)[0] == 200
                    bad_form = urlencode({"email_address": "alice@example.test", "password": "incorrect"})
                    assert request("/session", credential=None, method="POST", data=bad_form, extra_headers=login_headers)[0] == 422
                    print("PASS: bcrypt login creates a usable signed session; wrong password rejected")

                status, body, _ = request("/rooms/1")
                assert status == 200, (status, body)
                assert ids(body) == list(range(61, 101)), ids(body)
                assert "&lt;script&gt;" in body and "<script>alert('x')</script>" not in body
                assert "Alice &amp; Bob" in body
                assert "Watercooler &amp; news" in body
                assert request("/rooms/1", gzip_body=False)[1] == body
                assert request("/rooms/1", method="HEAD")[1] == ""
                status, body, _ = request("/rooms/1/messages?before=60")
                assert status == 200 and ids(body) == list(range(20, 60)), (status, ids(body))
                status, body, _ = request("/searches?q=coffee")
                assert status == 200 and ids(body) == list(range(3, 101, 3)), (status, ids(body))
                status, body, _ = request("/users/me/sidebar")
                assert status == 200 and 'id="shared_rooms"' in body
                assert "Watercooler &amp; news" in body and "Private room" not in body
                assert request("/rooms/2")[0] == 404
                for bad in (None, auth[:-1] + ("a" if auth[-1] != "a" else "b"),
                            cookie(secret, "test-session", purpose="cookie.other"),
                            cookie(secret, "test-session", expiry="2000-01-01T00:00:00.000Z"),
                            cookie(secret, "missing-session")):
                    assert request("/rooms/1", credential=bad)[0] == 302
                print("PASS: authenticated pages, SQL result windows, gzip, escaping, HEAD and access denial")

                def concurrent_read(_):
                    for _ in range(10):
                        status, body, _ = request("/rooms/1")
                        assert status == 200 and ids(body) == list(range(61, 101))
                with concurrent.futures.ThreadPoolExecutor(max_workers=8) as clients:
                    list(clients.map(concurrent_read, range(8)))
                print("PASS: concurrent reads from 8 clients")

                db = sqlite3.connect(database)
                posted = "bench write a123beef"
                encoded = urlencode({"message[body]": posted, "message[client_message_id]": "new-client"})
                fields = {"Content-Type": "application/x-www-form-urlencoded", "Sec-Fetch-Site": "same-origin"}
                status, result, headers = request("/rooms/1/messages", method="POST", data=encoded, extra_headers=fields)
                assert status == 200, (status, result)
                assert headers["Content-Type"].startswith("text/vnd.turbo-stream.html")
                created = ids(result)
                assert len(created) == 1 and posted in result
                row = db.execute("SELECT m.room_id,m.creator_id,m.client_message_id,rt.body,idx.body FROM messages m "
                                 "JOIN action_text_rich_texts rt ON rt.record_id=m.id AND rt.record_type='Message' "
                                 "JOIN message_search_index idx ON idx.rowid=m.id WHERE m.id=?", created).fetchone()
                assert row == (1, 1, "new-client", f"<div>{posted}</div>", posted), row
                assert ids(request("/rooms/1")[1])[-1] == created[0]
                assert ids(request("/searches?q=a123beef")[1]) == created
                denied = dict(fields, **{"Sec-Fetch-Site": "cross-site"})
                assert request("/rooms/1/messages", method="POST", data=encoded, extra_headers=denied)[0] == 422
                assert request("/rooms/2/messages", method="POST", data=encoded, extra_headers=fields)[0] == 404
                db.executescript("CREATE TRIGGER fail_insert BEFORE INSERT ON action_text_rich_texts "
                                 "BEGIN SELECT RAISE(ABORT,'test rollback'); END;")
                count = db.execute("SELECT COUNT(*) FROM messages").fetchone()[0]
                assert request("/rooms/1/messages", method="POST", data=encoded, extra_headers=fields)[0] == 500
                assert db.execute("SELECT COUNT(*) FROM messages").fetchone()[0] == count
                db.execute("DROP TRIGGER fail_insert")
                db.commit()
                print("PASS: acknowledged message persisted atomically with rich text and FTS; failed write rolled back")

                def concurrent_post(n):
                    value = f"parallel message {n}"
                    data = urlencode({"message[body]": value, "message[client_message_id]": f"parallel-{n}"})
                    status, result, _ = request("/rooms/1/messages", method="POST", data=data, extra_headers=fields)
                    assert status == 200, (status, result)
                    return ids(result)[0], value
                with concurrent.futures.ThreadPoolExecutor(max_workers=8) as clients:
                    acknowledged = list(clients.map(concurrent_post, range(32)))
                assert len({entry[0] for entry in acknowledged}) == 32
                for message_id, value in acknowledged:
                    saved = db.execute("SELECT m.room_id,idx.body FROM messages m JOIN message_search_index idx ON idx.rowid=m.id WHERE m.id=?", (message_id,)).fetchone()
                    assert saved == (1, value), saved
                print("PASS: 32 concurrent acknowledged writes have distinct IDs and exact persisted bodies")

                db.execute("UPDATE users SET status=2 WHERE id=1")
                db.commit()
                assert request("/rooms/1")[0] == 302
                db.execute("UPDATE users SET status=0 WHERE id=1")
                db.execute("DELETE FROM memberships WHERE room_id=1 AND user_id=1")
                db.commit()
                assert request("/rooms/1")[0] == 404
                db.close()
                print("PASS: foreign database changes revoke sessions and room access")
            except BaseException:
                log.flush()
                log.seek(0)
                print(log.read())
                raise
            finally:
                server.terminate()
                server.wait(timeout=10)


if __name__ == "__main__":
    main()
