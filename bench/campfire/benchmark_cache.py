#!/usr/bin/env python3
"""Compare this prototype's cached and uncached room reads, not language implementations."""

import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import html
import http.client
import json
import os
from pathlib import Path
import platform
import re
import secrets
import socket
import sqlite3
import statistics
import subprocess
import tempfile
import time

from test_server import cookie, fixture
from test_html import message_text


def affinity():
    available = sorted(os.sched_getaffinity(0))
    representatives = {}
    for cpu in available:
        topology = Path(f"/sys/devices/system/cpu/cpu{cpu}/topology")
        key = tuple((topology / part).read_text().strip() for part in ("physical_package_id", "core_id"))
        representatives.setdefault(key, cpu)
    cores = list(representatives.values())
    if len(cores) < 2:
        raise SystemExit("at least two separate CPU cores are required")
    count = min(4, len(cores) // 2)
    return cores[:count], cores[count:count * 2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("loadgen", type=Path, help="compiled once-campfire-verification Rust load generator")
    parser.add_argument("--duration", type=float, default=5)
    parser.add_argument("--rounds", type=int, default=3)
    parser.add_argument("--clients", type=int, default=16)
    parser.add_argument("--output", type=Path, default=Path(__file__).parent / "build/cache-benchmark.json")
    args = parser.parse_args()
    if platform.system() != "Linux":
        raise SystemExit("run this benchmark on Linux for CPU affinity and native temporary storage")
    if args.duration <= 0 or args.rounds < 1 or args.clients < 1:
        raise SystemExit("duration, rounds and clients must be positive")
    executable, loadgen = args.executable.resolve(), args.loadgen.resolve()
    server_cpus, client_cpus = affinity()
    cpu_list = lambda cpus: ",".join(map(str, cpus))
    cpu_model = next((line.split(":", 1)[1].strip() for line in Path("/proc/cpuinfo").read_text().splitlines()
                      if line.startswith("model name")), "unknown")
    report = {"scope": "Goose prototype cache comparison; synthetic fixture; not a Rust/Jai comparison",
              "measured_at": datetime.now(timezone.utc).isoformat(), "cpu_model": cpu_model,
              "platform": platform.platform(), "server_cpus": server_cpus, "client_cpus": client_cpus,
              "clients": args.clients, "duration_seconds": args.duration, "rounds": args.rounds,
              "executable_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
              "loadgen_sha256": hashlib.sha256(loadgen.read_bytes()).hexdigest(), "samples": []}
    with tempfile.TemporaryDirectory(prefix="campfire-benchmark-") as directory:
        work = Path(directory)
        database = work / "campfire.sqlite3"
        fixture(database)
        secret = secrets.token_hex(64)
        auth = cookie(secret, "test-session")
        with sqlite3.connect(database) as db:
            messages = db.execute("SELECT m.id,idx.body FROM (SELECT * FROM messages WHERE room_id=1 "
                                  "ORDER BY created_at DESC LIMIT 40) m JOIN message_search_index idx "
                                  "ON idx.rowid=m.id ORDER BY m.created_at").fetchall()
        expected_ids = [row[0] for row in messages]
        contract = {"kind": "room_show", "content_type": "text/html", "required": [],
                    "message_ids": expected_ids,
                    "message_content": [re.findall(r"[A-Za-z0-9_]+", row[1]) for row in messages]}
        canonical = None
        contract_file = work / "room.json"
        for round_number in range(args.rounds):
            for cached in ((False, True) if round_number % 2 == 0 else (True, False)):
                with socket.socket() as sock:
                    sock.bind(("127.0.0.1", 0))
                    port = sock.getsockname()[1]
                env = dict(os.environ, DATABASE_PATH=str(database), SECRET_KEY_BASE=secret, PORT=str(port),
                           CAMPFIRE_CACHE="1" if cached else "0", CAMPFIRE_CACHE_DIAGNOSTICS="0")
                with (work / "server.log").open("w+") as log:
                    server = subprocess.Popen(["taskset", "-c", cpu_list(server_cpus), str(executable)],
                                              env=env, stdout=log, stderr=log)
                    try:
                        for _ in range(200):
                            if server.poll() is not None:
                                raise RuntimeError(f"server exited: {server.returncode}")
                            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
                            try:
                                conn.request("GET", "/rooms/1", headers={"Cookie": auth, "Accept-Encoding": "gzip"})
                                response = conn.getresponse()
                                wire = response.read()
                                body = gzip.decompress(wire) if response.getheader("Content-Encoding") == "gzip" else wire
                                assert response.status == 200
                                break
                            except ConnectionRefusedError:
                                time.sleep(0.05)
                            finally:
                                conn.close()
                        else:
                            raise RuntimeError("server did not become ready")
                        text = body.decode()
                        assert list(map(int, re.findall(r'data-message-id="(\d+)"', text))) == expected_ids
                        assert message_text(text) == [(mid, " ".join(value.split())) for mid, value in messages]
                        assert text.startswith("<!DOCTYPE html>") and text.endswith("</html>")
                        if canonical is None:
                            canonical = body
                            contract["exact_body"] = list(body)
                            contract_file.write_text(json.dumps(contract))
                            report["decoded_body_bytes"] = len(body)
                            report["decoded_body_sha256"] = hashlib.sha256(body).hexdigest()
                        else:
                            assert body == canonical, "cached and uncached responses differ"
                        command = ["taskset", "-c", cpu_list(client_cpus), str(loadgen), "http",
                                   "--base", f"http://127.0.0.1:{port}", "--cookie", auth, "--path", "/rooms/1",
                                   "--conc", str(args.clients), "--gzip", "1", "--validate", str(contract_file)]
                        for duration, warmup in ((1, True), (args.duration, False)):
                            process = subprocess.run([*command, "--duration", str(duration)], capture_output=True, text=True)
                            if process.returncode != 0:
                                raise RuntimeError(process.stderr)
                            sample = json.loads(process.stdout)
                            assert sample["errors"] == 0 and sample["invalid_responses"] == 0, sample
                            assert sample["validation"] == "route-contract-v1" and sample["ok"] > 0, sample
                            assert sample["statuses"] == {"200": sample["ok"]}, sample
                            if not warmup:
                                sample.update(cached=cached, round=round_number + 1)
                                report["samples"].append(sample)
                                print(f"round {round_number + 1}, cache={cached}: {sample['rps']} valid requests/s", flush=True)
                    except BaseException:
                        log.seek(0)
                        print(log.read())
                        raise
                    finally:
                        server.terminate()
                        server.wait(timeout=10)
    report["median_rps"] = {str(cached).lower(): statistics.median(s["rps"] for s in report["samples"] if s["cached"] == cached)
                            for cached in (False, True)}
    report["speedup"] = report["median_rps"]["true"] / report["median_rps"]["false"]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"median_rps": report["median_rps"], "speedup": report["speedup"]}))


if __name__ == "__main__":
    main()
