#!/usr/bin/env python3
"""Compare Goose, Rust and published Jai images with the shared validator and write audit.

Run on Linux with Docker access. The repository and runtime directory must have
the same absolute paths inside this runner and on the Docker host. Contracts,
HTTP generation, image decoding and acknowledged-write validation come from an
unmodified checkout of once-campfire-verification.
"""

import argparse
from contextlib import closing
from datetime import datetime, timezone
import hashlib
import http.client
import json
import os
from pathlib import Path
import platform
import resource
import shutil
import socket
import sqlite3
import statistics
import subprocess
import tempfile
import time
import uuid

from benchmark_cache import affinity


def command(*args, check=True):
    result = subprocess.run([str(arg) for arg in args], capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(f"{args[0]} failed: {result.stderr[-4000:]}")
    return result


def json_command(*args):
    return json.loads(command(*args).stdout)


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def checksum(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def valid(value, label):
    if not (value["ok"] > 0 and value["errors"] == 0 and value["invalid_responses"] == 0
            and value["validation"] == "route-contract-v1" and value["statuses"] == {"200": value["ok"]}):
        raise RuntimeError(f"{label}: failed response validation; no throughput result accepted")


def metrics(container):
    result = {}
    cpu = command("docker", "exec", container, "cat", "/sys/fs/cgroup/cpu.stat", check=False)
    if cpu.returncode == 0:
        values = dict(line.split() for line in cpu.stdout.splitlines())
        if "usage_usec" in values:
            result["cpu_seconds"] = int(values["usage_usec"]) / 1e6
    if "cpu_seconds" not in result:
        cpu = command("docker", "exec", container, "cat", "/sys/fs/cgroup/cpuacct/cpuacct.usage", check=False)
        if cpu.returncode == 0:
            result["cpu_seconds"] = int(cpu.stdout.strip()) / 1e9
    memory = command("docker", "exec", container, "cat", "/sys/fs/cgroup/memory.stat", check=False)
    if memory.returncode != 0:
        memory = command("docker", "exec", container, "cat", "/sys/fs/cgroup/memory/memory.stat", check=False)
    if memory.returncode == 0:
        values = dict(line.split() for line in memory.stdout.splitlines())
        for field in ("anon", "total_rss", "rss"):
            if field in values:
                result["anonymous_bytes"] = int(values[field])
                break
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verification", type=Path, required=True)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--runtime-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--executable", type=Path, default=Path("bench/campfire/build/campfire"))
    parser.add_argument("--apps", default="goose,rust,jai")
    parser.add_argument("--goose-image", default="goose-campfire-toolchain:latest")
    parser.add_argument("--rust-image", default="ghcr.io/basecamp/once-campfire-rust:main")
    parser.add_argument("--jai-image", default="ghcr.io/lucasmeijer/once-campfire-jai:e56ba63")
    parser.add_argument("--rounds", type=int, default=3)
    parser.add_argument("--duration", type=int, default=8)
    parser.add_argument("--clients", type=int, default=16)
    parser.add_argument("--profiles", default="baseline,mixed")
    parser.add_argument("--routes", default="room_show,messages_page,sidebar,search,post_message")
    parser.add_argument("--preflight-only", action="store_true")
    parser.add_argument("--profile-writes", action="store_true", help="record Goose write-stage timings; adds instrumentation overhead")
    args = parser.parse_args()
    if platform.system() != "Linux":
        raise SystemExit("Run inside the Linux toolchain container")
    apps, profiles, selected = args.apps.split(","), args.profiles.split(","), args.routes.split(",")
    assert apps and len(set(apps)) == len(apps) and set(apps) <= {"goose", "rust", "jai"}
    assert profiles and set(profiles) <= {"baseline", "mixed"}
    assert args.duration > 0 and args.clients > 0 and (args.preflight_only or args.rounds >= 2)
    assert selected and set(selected) <= {"room_show", "messages_page", "sidebar", "search", "avatar", "static_css", "up", "post_message"}
    repo = Path(__file__).resolve().parents[2]
    verification, seed = args.verification.resolve(), args.seed.resolve()
    executable, output, runtime = args.executable.resolve(), args.output.resolve(), args.runtime_root.resolve()
    assert executable.is_relative_to(repo) and runtime.is_dir()
    output.mkdir(parents=True, exist_ok=False)
    loadgen = verification / "loadgen/target/release/loadgen"
    labels = json.loads((seed / "labels.json").read_text())
    fixture_env = dict(line.split("=", 1) for line in (seed / "reference.env").read_text().splitlines()
                       if line and not line.startswith("#"))
    room, write_room = labels["rooms.watercooler"], labels["rooms.hq"]
    server_cpus, client_cpus = affinity()
    cpu_list = lambda cpus: ",".join(map(str, cpus))
    images = {}
    for app in apps:
        inspected = json_command("docker", "image", "inspect", getattr(args, f"{app}_image"))[0]
        config = inspected["Config"]
        image_env = dict(value.split("=", 1) for value in config.get("Env", []))
        images[app] = {"id": inspected["Id"], "digests": inspected.get("RepoDigests", []),
                       "reference": getattr(args, f"{app}_image"), "labels": config.get("Labels", {}),
                       "revision": (config.get("Labels") or {}).get("org.opencontainers.image.revision", image_env.get("GIT_REVISION"))}
    # The checkout is shared with Windows; Git normalizes CRLF and ignores its synthetic executable bits.
    git = lambda directory, *rest: command("git", "-c", f"safe.directory={directory}", "-c", "core.autocrlf=true",
                                          "-c", "core.filemode=false", "-C", directory, *rest).stdout.strip()
    metadata = {
        "complete": False, "started_at": datetime.now(timezone.utc).isoformat(),
        "scope": "Shared HTTP contracts and audited plain-text posts; not complete application parity",
        "verification_revision": git(verification, "rev-parse", "HEAD"),
        "verification_dirty": bool(git(verification, "status", "--porcelain", "--untracked-files=no")),
        "goose_revision": git(repo, "rev-parse", "HEAD"), "goose_dirty": bool(git(repo, "status", "--porcelain")),
        "executable_sha256": checksum(executable), "loadgen_sha256": checksum(loadgen),
        "seed_sha256": checksum(seed / "db/production.sqlite3"), "seed_source": json.loads((seed / "source.json").read_text()),
        "images": images, "server_cpus": server_cpus, "client_cpus": client_cpus, "memory_limit_bytes": 2 * 1024**3,
        "platform": platform.platform(), "cpu_model": next(line.split(":", 1)[1].strip() for line in Path("/proc/cpuinfo").read_text().splitlines() if line.startswith("model name")),
        "duration_seconds": args.duration, "clients": args.clients, "rounds": args.rounds,
        "profile_writes": args.profile_writes, "profiles": profiles, "read_routes": selected, "mixed_write_rate": 10, "gzip": True, "preflight_only": args.preflight_only,
        "validator_sha256": checksum(verification / "loadgen/src/validation.rs"),
        "contracts_sha256": checksum(verification / "bench/contracts.rb"),
        "write_audit_sha256": checksum(verification / "bench/validate_acks.rb"),
    }
    assert not metadata["verification_dirty"], "verification checkout must be unmodified"
    save(output / "metadata.json", metadata)
    results = []
    sequence = 0
    for profile in (["baseline"] if args.preflight_only else profiles):
        for iteration in range(1 if args.preflight_only else args.rounds):
            # Rotating order gives each application each position in three rounds.
            order = apps[iteration % len(apps):] + apps[:iteration % len(apps)]
            for app in order:
                name = f"goose-campfire-{uuid.uuid4().hex[:10]}-{app}"
                with tempfile.TemporaryDirectory(prefix=f"{app}-{profile}-", dir=runtime) as temporary:
                    data = Path(temporary)
                    for folder in ("db", "logs", "contracts"):
                        (data / folder).mkdir()
                    shutil.copytree(seed / "storage", data / "files")
                    database = data / "db/production.sqlite3"
                    with closing(sqlite3.connect((seed / "db/production.sqlite3").as_uri() + "?mode=ro", uri=True)) as source:
                        with closing(sqlite3.connect(database)) as db:
                            source.backup(db)
                            db.executescript("UPDATE push_subscriptions SET endpoint='https://127.0.0.1:9/push/'||id; "
                                             "UPDATE webhooks SET url='http://127.0.0.1:9/hook/'||id;")
                            initial_count = db.execute("SELECT count(*) FROM messages WHERE room_id=?", (write_room,)).fetchone()[0]
                            initial_max = db.execute("SELECT max(id) FROM messages").fetchone()[0]
                    for folder in ("db", "logs"):
                        os.chmod(data / folder, 0o777)
                    os.chmod(database, 0o666)
                    # TemporaryDirectory is private to the runner; image uid 1000 needs traversal.
                    os.chmod(data, 0o755)
                    with socket.socket() as sock:
                        sock.bind(("127.0.0.1", 0))
                        port = sock.getsockname()[1]
                    config = dict(fixture_env, WEB_CONCURRENCY="3", JOB_CONCURRENCY="3", RAILS_MAX_THREADS="5",
                                  RAILS_LOG_LEVEL="warn", HTTP_PORT=str(port), TARGET_PORT=str(port + 1),
                                  PORT=str(port), DATABASE_PATH="/rails/storage/db/production.sqlite3",
                                  STORAGE_PATH="/rails/storage/files", CAMPFIRE_CACHE="1", CAMPFIRE_CACHE_DIAGNOSTICS="0",
                                  CAMPFIRE_RESPONSE_CACHE_MB="64", CAMPFIRE_PROFILE_WRITES="1" if args.profile_writes else "0")
                    env_file = data / "server.env"
                    env_file.write_text("".join(f"{key}={value}\n" for key, value in config.items()))
                    os.chmod(env_file, 0o600)
                    launch = ["docker", "run", "-d", "--name", name, "--network", "host",
                              "--cpuset-cpus", cpu_list(server_cpus), "--memory", str(metadata["memory_limit_bytes"]),
                              "--env-file", str(env_file)]
                    for folder, mount in (("db", "db"), ("files", "files"), ("logs", "logs")):
                        launch += ["-v", f"{data / folder}:/rails/storage/{mount}"]
                    if app == "goose":
                        launch += ["-v", f"{repo}:/app:ro", "--workdir", "/app"]
                    launch += [images[app]["id"]]
                    if app == "goose":
                        launch += ["/app/" + executable.relative_to(repo).as_posix()]
                    row = {"app": app, "round": iteration + 1, "profile": profile, "samples": []}
                    label = f"{app}-{profile}-{iteration + 1}"
                    audits, acknowledged = [], 0
                    try:
                        command(*launch)
                        base = f"http://127.0.0.1:{port}"
                        deadline = time.monotonic() + 90
                        while True:
                            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
                            try:
                                conn.request("GET", "/up")
                                response = conn.getresponse()
                                response.read()
                                if response.status == 200:
                                    break
                            except (OSError, http.client.HTTPException):
                                pass
                            finally:
                                conn.close()
                            if time.monotonic() >= deadline:
                                raise RuntimeError(f"{app}: startup timeout")
                            time.sleep(.1)
                        client = lambda *params: json_command("taskset", "-c", cpu_list(client_cpus), loadgen, *params)
                        auth = client("login", "--base", base, "--email", labels["emails.david"], "--password", labels["passwords.all"])["cookie"]
                        scrape = client("scrape", "--base", base, "--cookie", auth, "--room", room)
                        assert scrape["status"] == 200 and scrape["css"]
                        csrf = scrape.get("csrf") or ""
                        prepared = json_command("ruby", verification / "bench/contracts.rb", base, auth, database,
                                                seed / "labels.json", scrape["css"], data / "contracts")
                        row["preflight"] = prepared["preflight"]
                        contracts = prepared["contracts"]
                        routes = {"room_show": f"/rooms/{room}",
                                  "messages_page": f'/rooms/{room}/messages?before={labels["messages.busy_060"]}',
                                  "sidebar": "/users/me/sidebar", "search": "/searches?q=coffee",
                                  "avatar": f'/users/{labels["avatar_tokens.jason"]}/avatar',
                                  "static_css": scrape["css"], "up": "/up", "post_message": None}

                        def sample(route, duration, clients, phase, mixed=False, requests=None):
                            nonlocal sequence, acknowledged
                            sequence += 1
                            params = ["http", "--base", base, "--cookie", auth, "--gzip", "1",
                                      "--validate", contracts[route], "--duration", str(duration), "--conc", str(clients)]
                            if requests:
                                params += ["--requests", str(requests)]
                            if routes[route] is None:
                                audit = data / f"writes-{sequence}.jsonl"
                                audits.append(audit)
                                params += ["--post-room", str(write_room), "--csrf", csrf, "--audit-writes", str(audit)]
                            else:
                                params += ["--path", routes[route]]
                            if mixed:
                                audit = data / f"mixed-{sequence}.jsonl"
                                audits.append(audit)
                                params += ["--mixed-write-rate", "10", "--mixed-write-room", str(write_room),
                                           "--mixed-write-validate", contracts["post_message"],
                                           "--mixed-write-audit", str(audit), "--csrf", csrf]
                            before = resource.getrusage(resource.RUSAGE_CHILDREN)
                            started = time.monotonic()
                            value = client(*params)
                            elapsed = time.monotonic() - started
                            after = resource.getrusage(resource.RUSAGE_CHILDREN)
                            value.update(app=app, profile=profile, round=iteration + 1, route=route, phase=phase,
                                         generator_cpu_percent=100 * (after.ru_utime + after.ru_stime - before.ru_utime - before.ru_stime) / elapsed)
                            save(output / "raw" / f"{sequence:04}-{label}-{route}-{phase}.json", value)
                            valid(value, f"{label} {route} {phase}")
                            if routes[route] is None:
                                acknowledged += value["ok"]
                            if mixed:
                                valid(value["writer"], f"{label} mixed writer")
                                acknowledged += value["writer"]["ok"]
                            return value

                        for route in routes:
                            sample(route, 3, 1, "preflight", requests=1)
                        print(f"PASS {label}: all eight shared route contracts, including decoded avatar and POST", flush=True)
                        if not args.preflight_only:
                            # The mixed profile uses the shared 10-writes/s writer in a different room.
                            for route in (["room_show"] if profile == "mixed" else selected):
                                sample(route, 2, 4, "warmup", mixed=profile == "mixed")
                                before = metrics(name)
                                started = time.monotonic()
                                value = sample(route, args.duration, args.clients, "measured", mixed=profile == "mixed")
                                after = metrics(name)
                                if "cpu_seconds" in before and "cpu_seconds" in after:
                                    value["server_cpu_cores"] = (after["cpu_seconds"] - before["cpu_seconds"]) / (time.monotonic() - started)
                                value["server_anonymous_bytes_after"] = after.get("anonymous_bytes")
                                row["samples"].append(value)
                                print(f"{label} {route}: {value['rps']} valid requests/s", flush=True)
                        audited = json_command("ruby", verification / "bench/validate_acks.rb", database, write_room, acknowledged, *audits)
                        with closing(sqlite3.connect(database)) as db:
                            assert db.execute("SELECT count(*) FROM messages WHERE room_id=?", (write_room,)).fetchone()[0] - initial_count == acknowledged
                            assert db.execute("SELECT count(*) FROM messages WHERE id NOT IN (SELECT rowid FROM message_search_index)").fetchone()[0] == 0
                            assert db.execute("SELECT count(*) FROM messages m WHERE room_id=? AND id>? AND NOT EXISTS "
                                              "(SELECT 1 FROM action_text_rich_texts r WHERE r.record_type='Message' AND r.name='body' AND r.record_id=m.id)", (write_room, initial_max)).fetchone()[0] == 0
                            assert db.execute("PRAGMA integrity_check").fetchall() == [("ok",)]
                        row["post_write_audit"] = audited
                        for audit in audits:
                            shutil.copy2(audit, output / "raw" / f"{label}-{audit.name}")
                        results.append(row)
                        save(output / f"{label}.json", row)
                    except BaseException:
                        log = command("docker", "logs", name, check=False)
                        (output / f"{label}-server.log").write_text(log.stdout + log.stderr)
                        raise
                    finally:
                        if args.profile_writes:
                            log = command("docker", "logs", name, check=False)
                            (output / f"{label}-server.log").write_text(log.stdout + log.stderr)
                        command("docker", "rm", "-f", name, check=False)
    assert checksum(seed / "db/production.sqlite3") == metadata["seed_sha256"], "source seed changed"
    assert checksum(executable) == metadata["executable_sha256"], "executable changed during measurement"
    metadata["complete"] = True
    metadata["finished_at"] = datetime.now(timezone.utc).isoformat()
    summary = {}
    for profile in profiles:
        summary[profile] = {}
        for app in apps:
            entries = [sample for row in results if row["app"] == app and row["profile"] == profile for sample in row["samples"]]
            summary[profile][app] = {}
            for route in sorted({item["route"] for item in entries}):
                values = [item for item in entries if item["route"] == route]
                summary[profile][app][route] = {"median_rps": statistics.median(item["rps"] for item in values),
                                               "runs": [item["rps"] for item in values]}
    save(output / "metadata.json", metadata)
    save(output / "summary.json", {"metadata": metadata, "summary": summary})
    print("COMPLETE: every accepted response and acknowledged write validated", flush=True)


if __name__ == "__main__":
    main()
