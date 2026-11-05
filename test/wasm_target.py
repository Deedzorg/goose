"""`goose build --target wasm64` (docs/design/wasm.md, milestones 1, 2 and 4):
samples built as 64-bit WebAssembly with Emscripten and run under Node print
what their native builds print, files and standard input included; the growth
checks stop a data stack that outgrows its fixed slice of linear memory as
it does (test/growth's programs); the thread fixtures (test/threads) print
and abort as they do natively, workers being pthreads over shared memory, and
a program that starts thread after thread reuses their stacks' memory; and
what the target cannot do (a --target outside goose build, an unknown
target) is refused with a message. Skipped where Emscripten (EMSDK, or emcc
on PATH) or Node is missing."""
import concurrent.futures
import os
import re
import shutil
import subprocess
from pathlib import Path

import toolchain as tc
from growth_checks import GROWTH, WAD, check_overflow

SAMPLES = tc.REPO_ROOT / "samples"
TESTDIR = tc.REPO_ROOT / "test"

# Arguments, standard input, a C header and files read through the os module
# between them; and a pool of worker threads.
CHECKED_SAMPLES = ["01_tour", "15_word_freq", "17_calc", "18_json", "24_call_c", "26_file_tree",
                   "23_mandelbrot_threads"]

# test/threads fixtures that do not hold for wasm64, and why.
THREAD_FIXTURES_SKIPPED = {
    # Its budget is sized for native 2 GB regions; wasm64's are 64 MB.
    "thread_cap",
    # V8 ends a native recursion that deep with its own "Maximum call stack
    # size exceeded" before the runtime can report it (as for main).
    "thread_stack_overflow",
}

# Thread after thread, each with stacks of its own: without their regions
# reused, 300 of them would take 39 GB of a 16 GB memory.
MANY_THREADS = """import std;

thread_fn worker(n: i64) {
    var parts: u8[>..] = [];
    for i in n { parts.append("ab"); }
    qput(parts.len);
}

fn main() {
    var total = 0;
    for i in 300 {
        let id = thread_spawn(worker, i % 7);
        total += qget<i64>();
        thread_wait(id);
    }
    print(total);
}
"""

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


def check_thread_fixtures(exe, work):
    """Every test/threads fixture but THREAD_FIXTURES_SKIPPED, as wasm64 under
    Node: its stdout as expected/<name>.out, and where expected/<name>.aborts
    says it aborts, a failing exit with expected/<name>.stderr's text."""
    expected = TESTDIR / "expected"

    def one(src):
        first = src.read_text(encoding="utf-8").split("\n", 1)[0]
        defines = ["-D" + d for d in re.findall(r"^// runtime-define: (\w+=\w+)$", first)]
        js = work / f"threads_{src.stem}.js"
        _build(exe, src, js, defines)
        r = _run(["node", str(js)], cwd=src.parent, timeout=120)
        out, err = tc.decode(r.stdout), tc.decode(r.stderr)
        aborts = (expected / f"{src.stem}.aborts").exists()
        wrong = []
        want = expected / f"{src.stem}.out"
        if want.exists() and out != tc.decode(want.read_bytes()):
            wrong.append("stdout is not expected/" + want.name)
        if aborts != (r.returncode != 0):
            wrong.append(f"exit code {r.returncode}")
        stderr = expected / f"{src.stem}.stderr"
        if aborts and stderr.exists() and tc.decode(stderr.read_bytes()).strip() not in err:
            wrong.append("stderr lacks expected/" + stderr.name)
        if wrong:
            raise RuntimeError(f"test/threads/{src.name} as wasm64: {', '.join(wrong)}:\n"
                               f"{(out + err)[:2000]}")

    fixtures = [f for f in sorted((TESTDIR / "threads").glob("*.goose"))
                if f.stem not in THREAD_FIXTURES_SKIPPED]
    with concurrent.futures.ThreadPoolExecutor(max(1, min(6, (os.cpu_count() or 2) // 2))) as ex:
        for f in ex.map(one, fixtures):
            pass


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

    check_thread_fixtures(exe, work)
    many = work / "many_threads.goose"
    many.write_text(MANY_THREADS)
    _build(exe, many, work / "many_threads.js", ["-DGS_STACK_STATS=1"])
    r = _run(["node", str(work / "many_threads.js")])
    expected = str(sum(2 * (i % 7) for i in range(300)))
    if r.returncode != 0 or tc.decode(r.stdout).strip() != expected:
        raise RuntimeError(f"300 threads one after another (exit {r.returncode}) did not print "
                           f"{expected}:\n{_text(r)[:2000]}")
    # Memory that ran out would have halved the regions instead (gs_reserve_region).
    last = [l for l in tc.decode(r.stderr).splitlines() if l.startswith("goose stack stats: worker 299:")]
    if not last or "reserving 64 MB each" not in last[0]:
        raise RuntimeError(f"the 300th thread did not get 64 MB regions:\n{last or _text(r)[-2000:]}")

    refusals = [
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
