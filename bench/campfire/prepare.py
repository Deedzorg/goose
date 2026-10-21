#!/usr/bin/env python3
"""Prepare a pinned SQLite package with Campfire's full-text-search support."""

from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
SQLITE = HERE / "build" / "sqlite"
SQLITE_REVISION = "739fa6af40ecaa48a59d032114e01975c53edd85"
GIT = ["git", "-c", f"safe.directory={SQLITE}"]


def main():
    if not (SQLITE / ".git").exists():
        subprocess.run([*GIT, "clone", "--no-checkout", "https://github.com/kaitk/goose-sqlite.git",
                        str(SQLITE)], check=True)
        subprocess.run([*GIT, "-C", str(SQLITE), "checkout", "--detach", SQLITE_REVISION], check=True)
    revision = subprocess.check_output([*GIT, "-C", str(SQLITE), "rev-parse", "HEAD"], text=True).strip()
    if revision != SQLITE_REVISION:
        raise SystemExit(f"unexpected SQLite package revision: {revision}")
    original = subprocess.check_output([*GIT, "-C", str(SQLITE), "show", "HEAD:sqlite.build"])
    expected = original.replace(b'c_defines = [', b'c_defines = [\n    "SQLITE_ENABLE_FTS5",', 1)
    sidecar = SQLITE / "sqlite.build"
    current = sidecar.read_bytes().replace(b"\r\n", b"\n")
    if current not in (original, expected):
        raise SystemExit("sqlite.build has other edits; refusing to overwrite them")
    if current != expected:
        sidecar.write_bytes(expected)
    print(f"SQLite package {revision}, FTS5 enabled")


if __name__ == "__main__":
    main()
