"""Capture live reference responses and immutable static assets for renderer development."""

import argparse
import hashlib
import json
from pathlib import Path
import re

from reference_server import Server, IMAGES


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--runtime-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--app", choices=IMAGES, default="rust")
    parser.add_argument("--binary", default="campfire")
    parser.add_argument("--assets", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    with Server(args.app, args.seed, args.runtime_root, args.output, binary=args.binary) as server:
        routes = {
            "room": f'/rooms/{server.labels["rooms.watercooler"]}',
            "page": f'/rooms/{server.labels["rooms.watercooler"]}/messages?before={server.labels["messages.busy_060"]}',
            "sidebar": "/users/me/sidebar", "search": "/searches?q=coffee",
        }
        for name, path in routes.items():
            status, _, body = server.request(path)
            assert status == 200, (name, status)
            (args.output / f"{name}.html").write_bytes(body)
            print(name, len(body), flush=True)
        (args.output / "source.json").write_text(json.dumps({"image": IMAGES[args.app], "base": server.base}, indent=2))
        if args.assets:
            args.assets.mkdir(parents=True, exist_ok=False)
            status, _, body = server.request("/assets/.manifest.json")
            assert status == 200
            manifest = json.loads(body)
            assets = {}
            for logical, entry in manifest.items():
                path = entry["digested_path"]
                assert not Path(path).is_absolute() and ".." not in Path(path).parts
                status, headers, content = server.request("/assets/" + path)
                assert status == 200, (path, status)
                target = args.assets / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(content)
                assets[logical] = dict(path=path, sha256=hashlib.sha256(content).hexdigest(),
                                       content_type=next(v for k,v in headers.items() if k.lower()=="content-type"))
            (args.assets / "manifest.json").write_text(json.dumps(assets, indent=2) + "\n")
            print("assets",len(assets),flush=True)


if __name__ == "__main__":
    main()
