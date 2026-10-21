#!/usr/bin/env python3
"""Check and execute the three reduced cache APIs, or reproduce the old limitation."""

import argparse
import os
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("compiler", type=Path)
    parser.add_argument("--expect-limitation", action="store_true",
                        help="expect the field-reference rejection from compiler 8511ae34")
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    with tempfile.TemporaryDirectory(prefix="campfire-reference-") as directory:
        for optimization in ("-O0", "-O1", "-O2"):
            for name in ("field_reference", "direct_reference", "value_holder"):
                source = str(HERE / f"{name}.goose")
                if name == "field_reference" and args.expect_limitation:
                    result = subprocess.run([str(compiler), "check", optimization, source],
                                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    assert result.returncode != 0, "The limitation no longer reproduces."
                    assert "cannot clear reusable pool unrelated (which cache.bytes may point at)" in result.stdout, result.stdout
                    print(f"PASS: {name} {optimization} has the historical rejection")
                    continue
                executable = Path(directory) / (name + (".exe" if os.name == "nt" else ""))
                result = subprocess.run([str(compiler), "build", optimization, "-o", str(executable), source],
                                        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                assert result.returncode == 0, result.stdout
                result = subprocess.run([str(executable)], text=True, stdout=subprocess.PIPE,
                                        stderr=subprocess.STDOUT,
                                        creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
                assert result.returncode == 0, result.stdout
                print(f"PASS: {name} {optimization} builds and runs")


if __name__ == "__main__":
    main()
