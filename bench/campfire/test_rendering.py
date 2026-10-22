"""Differential HTML checks against the pinned, running reference applications."""

import argparse
import hashlib
from contextlib import closing
import json
from pathlib import Path
import re
import sqlite3
from urllib.parse import urlencode

from compare_rendering import compare
from reference_server import Server


def capture(server, output, extended):
    labels = server.labels
    routes = {
        "room": f'/rooms/{labels["rooms.watercooler"]}',
        "page": f'/rooms/{labels["rooms.watercooler"]}/messages?before={labels["messages.busy_060"]}',
        "sidebar": "/users/me/sidebar", "search": "/searches?q=coffee",
    }
    if extended:
        routes.update({name: f'/rooms/{labels["rooms." + name]}' for name in ("hq", "quiet", "broken", "group_direct", "david_and_jason", "designers")})
    names = []
    if server.app == "goose":
        manifest = json.loads((Path(__file__).parent / "views/assets.json").read_text())
        for asset in manifest.values():
            status, headers, body = server.request("/assets/" + asset["path"])
            assert status == 200 and hashlib.sha256(body).hexdigest() == asset["sha256"], asset["path"]
            assert headers["Content-Type"] == asset["content_type"], asset["path"]
        print("PASS", len(manifest), "served static assets match pinned hashes", flush=True)

    def save(name, path, data=None, headers=None):
        status, _, body = server.request(path, data, headers)
        assert status == 200, (server.app, name, status, body[:200])
        if data is not None:
            text = body.decode()
            text = re.sub(r'((?:data-message-timestamp|data-message-updated-at|data-sort-value)="-)\d+', r'\1TIME', text)
            text = re.sub(r'((?:data-message-timestamp|data-message-updated-at|data-sort-value)=")\d+', r'\1TIME', text)
            text = re.sub(r'(datetime=")[^"]+', r'\1TIME', text)
            body = text.encode()
        (output / f"{name}.html").write_bytes(body)
        names.append(name)

    for name, path in routes.items():
        save(name, path)
        save(name + "_warm", path)
    save("room_host", routes["room"], headers={"Host": "render.example.test"})
    save("room_chrome", routes["room"], headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"})
    # Foreign edits deliberately do not touch version timestamps: both renderers must
    # invalidate their caches when content changes through another connection.
    with closing(sqlite3.connect(server.database)) as db:
        db.execute("UPDATE rooms SET name=? WHERE id=?", ('Render & <Room>', labels["rooms.watercooler"]))
        db.execute("UPDATE users SET name=?,bio=? WHERE id=?", ('Writer & <Name>', 'A "quoted" biography', labels["users.david"]))
        mid = db.execute("SELECT id FROM messages WHERE room_id=? ORDER BY created_at DESC LIMIT 1", (labels["rooms.watercooler"],)).fetchone()[0]
        db.execute("UPDATE action_text_rich_texts SET body=? WHERE record_type='Message' AND record_id=?", ('<p>Fresh <strong>bold</strong> &amp; <em>italic</em>.</p>', mid))
        db.execute("UPDATE message_search_index SET body=? WHERE rowid=?", ('Fresh bold & italic.', mid))
        db.execute("UPDATE memberships SET unread_at='2026-01-01 12:00:00' WHERE user_id=?", (labels["users.david"],))
        db.commit()
    save("room_edited", routes["room"])
    save("sidebar_edited", routes["sidebar"])
    for index, text in enumerate(("A plain write & quoted text", "👍", "普通のテキスト")):
        data = urlencode({"message[client_message_id]": f"parity-write-{index}", "message[body]": text})
        save(f"post_{index}", f'/rooms/{labels["rooms.hq"]}/messages', data=data,
             headers={"Accept": "text/vnd.turbo-stream.html"})
    (output / "source.json").write_text(json.dumps({"base": server.base}))
    return names


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--runtime-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--binary", default="campfire-render")
    parser.add_argument("--reference", choices=("rust", "jai"), default="rust")
    parser.add_argument("--extended", action="store_true")
    parser.add_argument("--no-cache", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    for app in (args.reference, "goose"):
        folder = args.output / app
        folder.mkdir()
        with Server(app, args.seed, args.runtime_root, folder, cache=not args.no_cache, binary=args.binary) as server:
            names = capture(server, folder, args.extended)
    results = [compare(args.output / args.reference, args.output / "goose", name) for name in names]
    (args.output / "result.json").write_text(json.dumps(dict(zip(names, results)), indent=2))
    assert all(results), "HTML parity differences"
    print("PASS", len(results), "rendered responses")


if __name__ == "__main__":
    main()
