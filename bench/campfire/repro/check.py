#!/usr/bin/env python3
"""Confirm the field-reference limitation and its two reduced controls."""

import argparse
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("compiler", type=Path)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    for optimization in ("-O0", "-O1", "-O2"):
        for name in ("field_reference", "direct_reference", "value_holder"):
            result = subprocess.run([str(compiler), "check", optimization, str(HERE / f"{name}.goose")],
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if name == "field_reference":
                assert result.returncode != 0, "The limitation no longer reproduces; review the cache design."
                assert "cannot clear reusable pool unrelated (which cache.bytes may point at)" in result.stdout, result.stdout
            else:
                assert result.returncode == 0, result.stdout
            print(f"PASS: {name} {optimization} has the expected result")


if __name__ == "__main__":
    main()
