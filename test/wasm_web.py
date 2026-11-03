"""`goose build --target wasm64-web` (docs/design/wasm.md §8, milestone 3):
the page it writes runs the program in a real browser. Pages for a few
samples -- arguments, files packed with --web-files, standard input -- and a
data stack overrun are served from here and opened in a headless Chromium
browser (Chrome or Edge; GOOSE_TEST_BROWSER names another). Each page runs as
it opens (?run) and posts what the program printed and its exit code back
(?test-report), which is compared with what the native build prints.
Skipped where Emscripten or such a browser is missing."""
import http.server
import json
import os
import shutil
import subprocess
import tempfile
import threading
import urllib.parse
from pathlib import Path

import toolchain as tc
from wasm_target import missing_tools

SAMPLES = tc.REPO_ROOT / "samples"
GROWTH = tc.REPO_ROOT / "test" / "growth"


def find_browser():
    """A Chromium browser's path, or None."""
    env = os.environ.get("GOOSE_TEST_BROWSER")
    if env:
        return env if Path(env).is_file() or shutil.which(env) else None
    cands = []
    if tc.IS_WINDOWS:
        for root in (os.environ.get("ProgramFiles", r"C:\Program Files"),
                     os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"),
                     os.environ.get("LOCALAPPDATA", "")):
            cands += [Path(root, "Google", "Chrome", "Application", "chrome.exe"),
                      Path(root, "Microsoft", "Edge", "Application", "msedge.exe")]
    elif tc.IS_MACOS:
        cands += [Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
                  Path("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge")]
    for c in cands:
        if c.is_file():
            return str(c)
    for name in ("google-chrome", "chromium", "chromium-browser", "microsoft-edge", "chrome"):
        if shutil.which(name):
            return shutil.which(name)
    return None


class Reports:
    """The results pages post back, by page name."""

    def __init__(self):
        self.lock = threading.Condition()
        self.got = {}

    def put(self, page, data):
        with self.lock:
            self.got[page] = data
            self.lock.notify_all()

    def wait(self, page, timeout):
        with self.lock:
            self.lock.wait_for(lambda: page in self.got, timeout)
            return self.got.get(page)


def serve(root, reports):
    """A server for `root` on a free local port, taking the pages' reports."""
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kw):
            super().__init__(*args, directory=str(root), **kw)

        def do_POST(self):
            n = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(n)
            page = Path(urllib.parse.urlsplit(self.headers.get("Referer", "")).path).stem
            reports.put(page, json.loads(body))
            self.send_response(204)
            self.end_headers()

        def guess_type(self, path):
            return "application/wasm" if str(path).endswith(".wasm") else super().guess_type(path)

        def log_message(self, *args):
            pass

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def build(exe, src, out, extra=(), cwd=None):
    argv = [str(exe), "build", "--target", "wasm64-web", *extra, str(src), "-o", str(out)]
    r = subprocess.run(argv, capture_output=True, cwd=cwd, timeout=300)
    if r.returncode != 0:
        raise RuntimeError(f"{' '.join(argv)} failed:\n{tc.decode(r.stdout + r.stderr)}")
    for f in (out, out.with_suffix(".wasm"), out.with_suffix(".html")):
        if not f.exists():
            raise RuntimeError(f"goose build --target wasm64-web wrote no {f.name}")


def check_wasm_web(exe, gendir):
    """None when everything checked out, or the reason it was skipped;
    raises RuntimeError on a failure."""
    why = missing_tools()
    if why:
        return why
    browser = find_browser()
    if not browser:
        return "no Chrome or Edge to open the pages (GOOSE_TEST_BROWSER names one)"
    work = Path(gendir) / "wasm_web"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)

    calc_in = (SAMPLES / "data" / "calc.stdin").read_text()
    # page name: (source, build flags, arguments, stdin, expected stdout or
    # None for an overrun, expected exit code)
    pages = {
        "tour": (SAMPLES / "01_tour.goose", [], [], "",
                 (SAMPLES / "expected" / "tour.out").read_bytes(), 0),
        "word_freq": (SAMPLES / "15_word_freq.goose", ["--web-files", "data"], [], "",
                      (SAMPLES / "expected" / "word_freq.out").read_bytes(), 0),
        "calc": (SAMPLES / "17_calc.goose", [], [], calc_in,
                 (SAMPLES / "expected" / "calc.out").read_bytes(), 0),
        "push": (GROWTH / "push.goose", ["--stack-reserve", "256K"], ["x"], "", None, 1),
    }
    for name, (src, flags, _, _, _, _) in pages.items():
        build(exe, src, work / f"{name}.js", flags, cwd=SAMPLES)

    reports = Reports()
    server = serve(work, reports)
    profile = Path(tempfile.mkdtemp(prefix="goose-web-"))
    try:
        for name, (_, _, args, stdin, expected, code) in pages.items():
            query = urllib.parse.urlencode({"args": json.dumps(args), "stdin": stdin})
            url = f"http://127.0.0.1:{server.server_port}/{name}.html?{query}&run&test-report"
            proc = subprocess.Popen([browser, "--headless=new", "--disable-gpu", "--no-first-run",
                                     "--no-default-browser-check", f"--user-data-dir={profile}", url],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            try:
                got = reports.wait(name, 90)
            finally:
                proc.kill()
                proc.wait()
            if got is None:
                raise RuntimeError(f"{name}.html sent no result within 90 s ({browser})")
            if got["code"] != code:
                raise RuntimeError(f"{name}.html exited {got['code']}, not {code}:\n"
                                   f"{got['stdout']}{got['stderr']}")
            if expected is None:
                if "data stack overflow" not in got["stderr"] or "a Goose bug" in got["stderr"] \
                        or got["stdout"]:
                    raise RuntimeError(f"{name}.html was not stopped by a growth check:\n"
                                       f"{got['stdout']}{got['stderr']}")
            elif got["stdout"].rstrip("\n") != tc.decode(expected).rstrip("\n"):
                raise RuntimeError(f"{name}.html printed something else:\n{got['stdout'][:2000]}"
                                   f"{got['stderr'][:1000]}")
    finally:
        server.shutdown()
        shutil.rmtree(profile, ignore_errors=True)
    return None
