"""Watching a program's data stacks (GOOSE_MEMORY_WATCH, runtime_impl.h):
with the variable naming a file, the runtime writes the main program's
stacks to it while it runs and once more as it ends. A `goose run` keeps
the tops in memory then, so an array growing in a loop shows its size; a
built program reports too, its globals named. Without the variable,
nothing is written."""
import os
import subprocess
import tempfile
from pathlib import Path

PROGRAM = """\
import os;

var notes: u8[>..];

fn hold(n: i64) -> i64 {
    var xs: i64[>..] = [];
    for i in n { xs.push(i); }
    sleep(0.3);
    xs.len
}

fn main() {
    format(notes, "held ", hold(1000000));
    print(notes);
}
"""


def read_report(path, label):
    """The report's state and its stacks as (used, peak, committed, name)."""
    if not path.exists():
        raise RuntimeError(f"memory watch: {label}: no report written")
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "goose memory 1" or lines[-1] != "end":
        raise RuntimeError(f"memory watch: {label}: not a whole report:\n" + "\n".join(lines))
    state = ""
    stacks = []
    for line in lines[1:-1]:
        w = line.split(" ", 4)
        if w[0] == "state":
            state = w[1]
        elif w[0].isdigit() and len(w) >= 4:
            stacks.append((int(w[1]), int(w[2]), int(w[3]), w[4] if len(w) > 4 else ""))
    return state, stacks


def run(cmd, root, env, label):
    r = subprocess.run(cmd, cwd=root, env=env, capture_output=True, text=True,
                       errors="replace", timeout=300)
    if r.returncode != 0 or "held 1000000" not in r.stdout:
        raise RuntimeError(f"memory watch: {label}: exit {r.returncode}:\n{r.stdout}{r.stderr}")


def check_memory_watch(exe, base):
    base = Path(base).resolve()
    base.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="memory-watch-", dir=base) as tmp:
        root = Path(tmp)
        source = root / "holds.goose"
        source.write_text(PROGRAM, newline="\n")
        report = root / "memory.txt"
        env = dict(os.environ, GOOSE_MEMORY_WATCH=str(report))

        # Run by the compiler: the million numbers are seen in use.
        run([str(exe), "run", str(source)], root, env, "goose run")
        state, stacks = read_report(report, "goose run")
        if state != "done":
            raise RuntimeError(f"memory watch: goose run: the report says {state!r}, not done")
        if not any(name == "notes" and used > 0 for used, _, _, name in stacks):
            raise RuntimeError(f"memory watch: goose run: no stack named notes in use: {stacks}")
        if not any(peak >= 8000000 and not name for _, peak, _, name in stacks):
            raise RuntimeError(f"memory watch: goose run: 8 MB never seen in use: {stacks}")
        if any(used > 0 for used, _, _, name in stacks if not name):
            raise RuntimeError(f"memory watch: goose run: the array is still in use at the end: "
                               f"{stacks}")

        # Built: it reports and names its globals.
        report.unlink()
        app = root / "holds"
        r = subprocess.run([str(exe), "build", "-o", str(app), str(source)], cwd=root,
                           capture_output=True, text=True, errors="replace", timeout=300)
        if r.returncode != 0:
            raise RuntimeError(f"memory watch: goose build:\n{r.stdout}{r.stderr}")
        built = app.with_suffix(".exe") if os.name == "nt" else app
        run([str(built)], root, env, "built")
        state, stacks = read_report(report, "built")
        if state != "done" or not any(name == "notes" for *_, name in stacks):
            raise RuntimeError(f"memory watch: built: {state!r}, {stacks}")

        # Not asked: nothing written.
        report.unlink()
        quiet = dict(os.environ)
        quiet.pop("GOOSE_MEMORY_WATCH", None)
        run([str(built)], root, quiet, "unwatched")
        if report.exists():
            raise RuntimeError("memory watch: a report was written without GOOSE_MEMORY_WATCH")
