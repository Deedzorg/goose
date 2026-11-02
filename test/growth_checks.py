"""Growth checks (GS_GROWTH_CHECKS, docs/design/wasm.md §2): the programs in
test/growth/ grow a data stack in different ways -- pushes, a resize, whole
appends, text rendered in place, records built field by field and copied, C
appending to a builder -- and, built with the checks on a 256 KB stack, each
is stopped by a check with the usual overflow message. A check that is
missing shows: the overrun reaches the guard gap, whose report then says no
check stopped it. With the default stack each prints what it computes."""
import subprocess
from pathlib import Path

import toolchain as tc

GROWTH = tc.REPO_ROOT / "test" / "growth"
WAD = tc.REPO_ROOT / "samples" / "data" / "freedoom1-e1m1.wad"

# What each prints with room to run (the argument is the file read_file reads).
EXPECTED = {
    "append": "1000000",
    "format": "688890",
    "push": "200000",
    "read_file": "true 4789358",
    "records": "48000",
    "render": "300884 192003",
    "resize": "800000",
}

OVERFLOW = "goose runtime error: data stack overflow"
MISSED = "no growth check stopped it"


def run(argv, timeout=300):
    return subprocess.run(argv, capture_output=True, timeout=timeout)


def text(r):
    return tc.decode(r.stdout + r.stderr).strip()


def check_overflow(name, r, what):
    """Raises unless r is a run a growth check stopped."""
    err = tc.decode(r.stderr)
    if r.returncode != 1 or OVERFLOW not in err or MISSED in err or r.stdout.strip():
        raise RuntimeError(f"{name} {what} was not stopped by a growth check "
                           f"(exit {r.returncode}):\n{text(r)[:1500]}")


def check_growth(exe, gendir):
    """Raises RuntimeError on a failure."""
    work = Path(gendir) / "growth_checks"
    work.mkdir(parents=True, exist_ok=True)
    names = sorted(f.stem for f in GROWTH.glob("*.goose"))
    if names != sorted(EXPECTED):
        raise RuntimeError(f"test/growth holds {names}, EXPECTED names {sorted(EXPECTED)}")
    for name in names:
        src = GROWTH / f"{name}.goose"
        for how, flags in (("small", ["--stack-reserve", "256K"]), ("roomy", [])):
            out = work / f"{name}-{how}{tc.EXE_SUFFIX}"
            argv = [str(exe), "build", "-DGS_GROWTH_CHECKS=1", *flags, str(src), "-o", str(out)]
            b = run(argv)
            if b.returncode != 0:
                raise RuntimeError(f"{' '.join(argv)} failed:\n{text(b)}")
            r = run([str(out), str(WAD)])
            if how == "small":
                check_overflow(name, r, "on a 256 KB stack")
            elif r.returncode != 0 or tc.decode(r.stdout).strip() != EXPECTED[name]:
                raise RuntimeError(f"{name} with the checks and the default stack (exit "
                                   f"{r.returncode}) should print {EXPECTED[name]}:\n{text(r)}")
    return len(names)
