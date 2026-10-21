#!/usr/bin/env python3
"""Check the prototype's implemented routes against a copy of the shared Rails seed.

This is a protocol/database integration check, not full UI parity or a benchmark.
--loadgen additionally requires the unmodified shared room-response contract.
"""

import argparse
import concurrent.futures
from contextlib import closing
import gzip
import html
import http.client
import json
import os
from pathlib import Path
import re
import socket
import sqlite3
import subprocess
import tempfile
import time
from urllib.parse import urlencode
import uuid


def message_ids(body):
    return [int(value) for value in re.findall(r'data-message-id="(\d+)"', body)]


def check_messages(body, expected):
    assert message_ids(body) == [row[0] for row in expected], "message window differs from SQL"
    rendered = re.findall(r'<article\b[^>]*data-message-id="(\d+)"[^>]*>.*?'
                          r'<div class="message__body">(.*?)</div></article>', body, re.S)
    assert [(int(mid), html.unescape(text)) for mid, text in rendered] == expected, "message bodies differ from SQL"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("seed", type=Path, help="unmodified output of once-campfire-verification/bin/seed")
    parser.add_argument("--no-cache", action="store_true")
    parser.add_argument("--loadgen", type=Path, help="also enforce the shared room HTML contract; fails until rendering is compatible")
    args = parser.parse_args()
    executable, seed = args.executable.resolve(), args.seed.resolve()
    labels = json.loads((seed / "labels.json").read_text())
    provenance = json.loads((seed / "source.json").read_text())
    environment = dict(line.split("=", 1) for line in (seed / "reference.env").read_text().splitlines()
                       if line and not line.startswith("#"))
    user, room, write_room = (labels[key] for key in ("users.david", "rooms.watercooler", "rooms.hq"))
    with tempfile.TemporaryDirectory(prefix="campfire-shared-") as temporary:
        work = Path(temporary)
        database = work / "production.sqlite3"
        with closing(sqlite3.connect((seed / "db/production.sqlite3").as_uri() + "?mode=ro", uri=True)) as source:
            with closing(sqlite3.connect(database)) as target:
                source.backup(target)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = dict(os.environ, DATABASE_PATH=str(database), SECRET_KEY_BASE=environment["SECRET_KEY_BASE"],
                   PORT=str(port), CAMPFIRE_CACHE="0" if args.no_cache else "1")
        with (work / "server.log").open("w+") as log:
            server = subprocess.Popen([str(executable)], env=env, stdout=log, stderr=log,
                                      creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
            credential = ""

            def request(path, data=None, authenticated=True):
                conn = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
                headers = {"Accept-Encoding": "gzip"}
                if authenticated:
                    headers["Cookie"] = credential
                if data is not None:
                    headers.update({"Content-Type": "application/x-www-form-urlencoded", "Sec-Fetch-Site": "same-origin"})
                try:
                    conn.request("GET" if data is None else "POST", path, body=data, headers=headers)
                    response = conn.getresponse()
                    body = response.read()
                    if response.getheader("Content-Encoding") == "gzip":
                        body = gzip.decompress(body)
                    return response.status, dict(response.getheaders()), body.decode()
                finally:
                    conn.close()

            try:
                for _ in range(200):
                    if server.poll() is not None:
                        raise RuntimeError(f"server exited: {server.returncode}")
                    try:
                        if request("/up", authenticated=False)[0] == 200:
                            break
                    except ConnectionRefusedError:
                        time.sleep(.05)
                else:
                    raise RuntimeError("server did not start")
                status, headers, _ = request("/session", urlencode({"email_address": labels["emails.david"],
                                                                   "password": labels["passwords.all"]}), authenticated=False)
                assert status == 302, f"fixture password login returned {status}"
                credential = headers["Set-Cookie"].split(";", 1)[0]
                assert request(f"/rooms/{room}", authenticated=False)[0] == 302
                print(f"PASS: real Rails seed {provenance['revision']}; bcrypt login and authenticated session", flush=True)

                with closing(sqlite3.connect(database)) as db:
                    def rows(ids):
                        return [(mid, db.execute("SELECT body FROM message_search_index WHERE rowid=?", (mid,)).fetchone()[0])
                                for mid in ids]

                    room_ids = [row[0] for row in db.execute("SELECT id FROM messages WHERE room_id=? ORDER BY created_at DESC LIMIT 40", (room,))][::-1]
                    identities = ['id="message_' + db.execute("SELECT client_message_id FROM messages WHERE id=?", (mid,)).fetchone()[0] + '"'
                                  for mid in room_ids]
                    anchor = labels["messages.busy_060"]
                    page_ids = [row[0] for row in db.execute("SELECT id FROM messages WHERE room_id=? AND created_at < "
                                "(SELECT created_at FROM messages WHERE id=?) ORDER BY created_at DESC LIMIT 40", (room, anchor))][::-1]
                    search_ids = [row[0] for row in db.execute("SELECT m.id FROM messages m JOIN message_search_index idx ON idx.rowid=m.id "
                                  "JOIN memberships mm ON mm.room_id=m.room_id WHERE mm.user_id=? AND idx.body MATCH 'coffee' "
                                  "ORDER BY m.id DESC LIMIT 100", (user,))][::-1]
                    expected_room = rows(room_ids)
                    for path, expected in ((f"/rooms/{room}", expected_room),
                                           (f"/rooms/{room}/messages?before={anchor}", rows(page_ids)),
                                           ("/searches?q=coffee", rows(search_ids))):
                        status, _, body = request(path)
                        assert status == 200, (path, status)
                        check_messages(body, expected)
                    status, _, body = request("/users/me/sidebar")
                    assert status == 200 and 'id="shared_rooms"' in body
                    for name, in db.execute("SELECT r.name FROM rooms r JOIN memberships m ON m.room_id=r.id "
                                           "WHERE m.user_id=? AND r.type='Rooms::Open' AND m.involvement<>'invisible'", (user,)):
                        assert html.escape(name, quote=True) in body
                    denied_room = db.execute("SELECT id FROM rooms WHERE id NOT IN (SELECT room_id FROM memberships WHERE user_id=?) LIMIT 1", (user,)).fetchone()[0]
                    assert request(f"/rooms/{denied_room}")[0] == 404
                    print("PASS: shared room, pagination, search and sidebar agree with independent SQL; membership enforced", flush=True)

                    initial_count = db.execute("SELECT count(*) FROM messages").fetchone()[0]
                    initial_touch = db.execute("SELECT updated_at FROM rooms WHERE id=?", (write_room,)).fetchone()[0]
                    run = uuid.uuid4().hex

                    def post(number):
                        client_id = f"shared-{run}-{number}"
                        text = f"bench write {run} {number} <script> & text"
                        status, _, body = request(f"/rooms/{write_room}/messages", urlencode({"message[body]": text,
                                                                "message[client_message_id]": client_id}))
                        assert status == 200, (status, body)
                        assert body.startswith('<turbo-stream action="append"') and body.endswith("</turbo-stream>")
                        mids = message_ids(body)
                        assert len(mids) == 1 and html.escape(text, quote=True) in body
                        return mids[0], client_id, text

                    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as clients:
                        acknowledged = list(clients.map(post, range(32)))
                    assert len({mid for mid, _, _ in acknowledged}) == 32
                    assert db.execute("SELECT count(*) FROM messages").fetchone()[0] == initial_count + 32
                    for mid, client_id, text in acknowledged:
                        stored = db.execute("SELECT m.room_id,m.creator_id,m.client_message_id,idx.body,rt.body "
                                            "FROM messages m JOIN message_search_index idx ON idx.rowid=m.id "
                                            "JOIN action_text_rich_texts rt ON rt.record_id=m.id "
                                            "AND rt.record_type='Message' AND rt.name='body' WHERE m.id=?", (mid,)).fetchall()
                        assert stored == [(write_room, user, client_id, text, "<div>" + html.escape(text, quote=True) + "</div>")], stored
                    assert db.execute("SELECT updated_at FROM rooms WHERE id=?", (write_room,)).fetchone()[0] != initial_touch
                    assert set(message_ids(request(f"/searches?q={run}")[2])) == {mid for mid, _, _ in acknowledged}
                    print("PASS: 32 concurrent acknowledgements have distinct IDs and exact message, Action Text and FTS rows; room touched", flush=True)

                    db.executescript("CREATE TRIGGER campfire_test_failure BEFORE INSERT ON action_text_rich_texts "
                                     "BEGIN SELECT RAISE(ABORT,'test rollback'); END;")
                    before = tuple(db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
                                   for table in ("messages", "action_text_rich_texts", "message_search_index"))
                    status, _, _ = request(f"/rooms/{write_room}/messages", urlencode({"message[body]": "failed write", "message[client_message_id]": "failed"}))
                    assert status == 500
                    after = tuple(db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
                                  for table in ("messages", "action_text_rich_texts", "message_search_index"))
                    assert before == after
                    db.execute("DROP TRIGGER campfire_test_failure")
                    db.commit()
                    for _ in range(8):
                        assert request(f"/rooms/{room}")[0] == 200
                    db.execute("DELETE FROM memberships WHERE user_id=? AND room_id=?", (user, room))
                    db.commit()
                    for _ in range(8):
                        assert request(f"/rooms/{room}")[0] == 404
                    db.execute("UPDATE users SET status=2 WHERE id=?", (user,))
                    db.commit()
                    for _ in range(8):
                        assert request(f"/rooms/{write_room}")[0] == 302
                    db.execute("UPDATE users SET status=0 WHERE id=?", (user,))
                    db.execute("INSERT INTO memberships(room_id,user_id,involvement,created_at,updated_at) VALUES (?,?,'mentions',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", (room, user))
                    db.commit()
                    print("PASS: failed writes roll back; foreign commits revoke cached room access and authentication", flush=True)

                if args.loadgen:
                    contract = {"kind": "room_show", "content_type": "text/html", "required": identities, "message_ids": room_ids,
                                "message_content": [re.findall(r"[A-Za-z0-9_]+", body) for _, body in expected_room]}
                    contract_file = work / "room.json"
                    contract_file.write_text(json.dumps(contract))
                    result = subprocess.run([str(args.loadgen.resolve()), "http", "--base", f"http://127.0.0.1:{port}",
                                             "--cookie", credential, "--path", f"/rooms/{room}", "--conc", "1", "--duration", "1",
                                             "--gzip", "1", "--validate", str(contract_file)], capture_output=True, text=True)
                    assert result.returncode == 0, "shared load generator failed"
                    checked = json.loads(result.stdout)
                    print("Shared room contract:", {key: checked[key] for key in ("ok", "errors", "invalid_responses", "invalid_reasons")}, flush=True)
                    assert checked["ok"] > 0 and checked["errors"] == 0 and checked["invalid_responses"] == 0, "shared room contract failed"
                print("PASS: shared-seed protocol/database checks; full UI parity and cross-language performance are not established")
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
