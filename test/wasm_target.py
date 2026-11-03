"""`goose build --target wasm64` (docs/design/wasm.md, milestones 1 and 2): samples
built as 64-bit WebAssembly with Emscripten and run under Node print what
their native builds print, files and standard input included; the growth
checks stop a data stack that outgrows its fixed slice of linear memory as
it does (test/growth's programs); and what the target cannot do yet (threads, a
--target outside goose build, an unknown target) is refused with a message.
Skipped where Emscripten (EMSDK, or emcc on PATH) or Node is missing."""
import os
import shutil
import subprocess
from pathlib import Path

import toolchain as tc
from growth_checks import GROWTH, WAD, check_overflow

SAMPLES = tc.REPO_ROOT / "samples"

# Arguments, standard input, a C header and files read through the os module
# between them.
CHECKED_SAMPLES = ["01_tour", "15_word_freq", "17_calc", "18_json", "24_call_c", "26_file_tree"]

OVERRUN = """import std;
import os;

fn main() {
    var bytes: u8[>..] = [];
    bytes.resize(arg_count() * 300000, 1);
    print(bytes.len);
}
"""


def missing_tools():
    """Why the check cannot run here, or None."""
    emsdk = os.environ.get("EMSDK")
    if not (emsdk and Path(emsdk, "upstream", "emscripten").is_dir()) and not shutil.which("emcc"):
        return "no Emscripten: set EMSDK or put emcc on PATH"
    if not shutil.which("node"):
        return "no Node to run the modules"
    return None


def _run(argv, cwd=None, stdin=b"", timeout=300):
    return subprocess.run(argv, cwd=cwd, input=stdin, capture_output=True, timeout=timeout)


def _text(r):
    return tc.decode(r.stdout + r.stderr).strip()


def _build(exe, src, out, extra=()):
    argv = [str(exe), "build", "--target", "wasm64", *extra, str(src), "-o", str(out)]
    r = _run(argv)
    if r.returncode != 0:
        raise RuntimeError(f"{' '.join(argv)} failed:\n{_text(r)}")
    for f in (out, out.with_suffix(".wasm")):
        if not f.exists():
            raise RuntimeError(f"goose build --target wasm64 wrote no {f.name}")


def check_wasm_target(exe, gendir):
    """None when everything checked out, or the reason it was skipped;
    raises RuntimeError on a failure."""
    why = missing_tools()
    if why:
        return why
    work = Path(gendir) / "wasm_target"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)

    for stem in CHECKED_SAMPLES:
        name = stem.split("_", 1)[1]
        header = SAMPLES / f"{name}.h"
        extra = ["--include", str(header)] if header.exists() else []
        js = work / f"{stem}.js"
        _build(exe, SAMPLES / f"{stem}.goose", js, extra)
        argsfile, stdinfile = SAMPLES / "data" / f"{name}.args", SAMPLES / "data" / f"{name}.stdin"
        args = argsfile.read_text().split() if argsfile.exists() else []
        stdin = stdinfile.read_bytes() if stdinfile.exists() else b""
        r = _run(["node", str(js), *args], cwd=SAMPLES, stdin=stdin)
        expected = tc.decode((SAMPLES / "expected" / f"{name}.out").read_bytes())
        if r.returncode != 0 or tc.decode(r.stdout) != expected:
            raise RuntimeError(f"{stem} as wasm64 (exit {r.returncode}) does not print "
                               f"expected/{name}.out:\n{_text(r)[:2000]}")

    # Growth checks are on in wasm64 builds: each program of test/growth that
    # outgrows a 256 KB stack is stopped as it does, before it prints, as
    # native builds stop at the guard gap; with the default 64 MB it fits.
    for prog in sorted(GROWTH.glob("*.goose")):
        js = work / f"growth_{prog.stem}.js"
        _build(exe, prog, js, ["--stack-reserve", "256K"])
        check_overflow(prog.stem, _run(["node", str(js), str(WAD)]), "as wasm64 on a 256 KB stack")
    src = work / "overrun.goose"
    src.write_text(OVERRUN)
    _build(exe, src, work / "fits.js")
    r = _run(["node", str(work / "fits.js")])
    if r.returncode != 0 or tc.decode(r.stdout).strip() != "300000":
        raise RuntimeError(f"300000 bytes in a 64 MB stack failed (exit {r.returncode}):\n{_text(r)}")

    refusals = [
        ([str(exe), "build", "--target", "wasm64", str(SAMPLES / "23_mandelbrot_threads.goose"),
          "-o", str(work / "threads.js")], "does not support threads"),
        ([str(exe), "run", "--target", "wasm64", str(src)], "--target is for goose build"),
        ([str(exe), "build", "--target", "wasm32", str(src)],
         "--target takes native, wasm64 or wasm64-web"),
        ([str(exe), "build", "--target", "wasm64", "--web-files", "data", str(src)],
         "--web-files is for --target wasm64-web"),
    ]
    for argv, says in refusals:
        r = _run(argv)
        if r.returncode == 0 or says not in _text(r):
            raise RuntimeError(f"{' '.join(argv[1:])} should fail saying {says!r}, but "
                               f"(exit {r.returncode}):\n{_text(r)}")
    return None
