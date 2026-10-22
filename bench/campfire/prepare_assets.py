"""Provision immutable frontend files from the pinned Rust image, checking every hash."""

import argparse
import hashlib
import json
from pathlib import Path

from reference_server import Server


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--runtime-root", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    assets = root / "build/reference-assets"
    assets.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((root / "views/assets.json").read_text())
    missing = [item for item in manifest.values()
               if not (assets / item["path"]).is_file()
               or hashlib.sha256((assets / item["path"]).read_bytes()).hexdigest() != item["sha256"]]
    if missing:
        with Server("rust", args.seed, args.runtime_root, root / "build/prepare-assets") as server:
            for item in missing:
                target = (assets / item["path"]).resolve()
                assert target.is_relative_to(assets.resolve())
                status, _, body = server.request("/assets/" + item["path"])
                assert status == 200 and hashlib.sha256(body).hexdigest() == item["sha256"], item["path"]
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(body)
    (assets / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Verified", len(manifest), "immutable assets; downloaded", len(missing))


if __name__ == "__main__":
    main()
