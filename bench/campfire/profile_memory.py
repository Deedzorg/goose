"""Sample resident mappings before and after a fixed set of shared-fixture reads."""

import argparse
import json
from pathlib import Path
import re

from benchmark_shared import checksum, command, metrics
from reference_server import Server


def snapshot(server):
    mappings, current = [], None
    smaps = command("docker", "exec", server.name, "cat", "/proc/1/smaps").stdout
    for line in smaps.splitlines():
        if re.match(r"^[0-9a-f]+-[0-9a-f]+ ", line):
            current = {"mapping": line}
            mappings.append(current)
        elif current is not None and ":" in line:
            key, value = line.split(":", 1)
            if key in ("Size", "Rss", "Anonymous", "Private_Dirty", "AnonHugePages"):
                current[key + "_kib"] = int(value.split()[0])
    return {"cgroup": metrics(server.name),
            "rss_kib": sum(m.get("Rss_kib", 0) for m in mappings),
            "anonymous_kib": sum(m.get("Anonymous_kib", 0) for m in mappings),
            "anonymous_huge_kib": sum(m.get("AnonHugePages_kib", 0) for m in mappings),
            "largest_anonymous_mappings": sorted(mappings, key=lambda m: m.get("Anonymous_kib", 0), reverse=True)[:16]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--runtime-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--binary", default="campfire")
    parser.add_argument("--no-cache", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    executable = Path(__file__).parent / "build" / args.binary
    result = {"executable_sha256": checksum(executable), "cache": not args.no_cache, "snapshots": {}}
    with Server("goose", args.seed, args.runtime_root, args.output, cache=not args.no_cache, binary=args.binary) as server:
        result["snapshots"]["after_login"] = snapshot(server)
        labels = server.labels
        routes = [f'/rooms/{labels["rooms.watercooler"]}',
                  f'/rooms/{labels["rooms.watercooler"]}/messages?before={labels["messages.busy_060"]}',
                  "/users/me/sidebar", "/searches?q=coffee"]
        for name, paths in (("room", routes[:1]), ("all_reads", routes)):
            for _ in range(64):
                for path in paths:
                    status, _, body = server.request(path)
                    assert status == 200 and body, (path, status)
            result["snapshots"][name] = snapshot(server)
    (args.output / "memory.json").write_text(json.dumps(result, indent=2) + "\n")
    for phase, sample in result["snapshots"].items():
        print(phase, "anonymous MiB", round(sample["anonymous_kib"] / 1024, 2),
              "resident MiB", round(sample["rss_kib"] / 1024, 2), flush=True)


if __name__ == "__main__":
    main()
