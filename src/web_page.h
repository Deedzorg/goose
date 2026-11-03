// Goose compiler — the page `goose build --target wasm64-web` writes beside
// prog.js and prog.wasm (docs/design/wasm.md §8, milestone 3): it loads the
// module Emscripten made (MODULARIZE, gooseProgram) and runs it on a click,
// with arguments and standard input from boxes, its output in the page and
// its exit code. @TITLE@ and @SCRIPT@ are filled in (WebPage).
#pragma once

namespace goose {

inline const char *const web_page_template = R"html(<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@TITLE@</title>
<!-- Written by `goose build --target wasm64-web`: the page that runs
     @SCRIPT@ (and its .wasm) in this browser. Serve the folder over http,
     for example `python -m http.server`, and open this page; a file:// page
     cannot load the module. ?run runs it as the page opens; ?args=["a","b"]
     and ?stdin=text fill in the boxes. -->
<style>
  :root {
    --bg: #f6f5f1; --panel: #ffffff; --ink: #1d1d1b; --muted: #6b6a64;
    --line: #dcdad2; --accent: #2f6f4e; --err: #b3261e; --mono-bg: #fbfaf7;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #161614; --panel: #1f1f1c; --ink: #ecebe6; --muted: #a09e96;
      --line: #34332e; --accent: #7cc49a; --err: #ff8a80; --mono-bg: #1a1a18;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: var(--bg); color: var(--ink);
    font: 15px/1.45 system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  main { max-width: 860px; margin: 0 auto; padding: 24px 16px 40px; }
  header { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; }
  h1 { font-size: 20px; margin: 0; }
  .sub { color: var(--muted); font-size: 13px; }
  .panel {
    background: var(--panel); border: 1px solid var(--line); border-radius: 10px;
    padding: 14px; margin-top: 16px;
  }
  label { display: block; font-size: 13px; color: var(--muted); margin: 0 0 4px; }
  input, textarea {
    width: 100%; font: 14px/1.4 ui-monospace, "Cascadia Mono", Consolas, monospace;
    color: var(--ink); background: var(--mono-bg); border: 1px solid var(--line);
    border-radius: 6px; padding: 7px 9px;
  }
  textarea { min-height: 64px; resize: vertical; }
  .row { display: flex; gap: 10px; align-items: center; margin-top: 12px; flex-wrap: wrap; }
  button {
    font: inherit; font-weight: 600; color: #fff; background: var(--accent); border: 0;
    border-radius: 6px; padding: 8px 18px; cursor: pointer;
  }
  button:disabled { opacity: .5; cursor: default; }
  #status { color: var(--muted); font-size: 13px; }
  #status.bad { color: var(--err); }
  pre {
    margin: 0; min-height: 120px; max-height: 60vh; overflow: auto; white-space: pre-wrap;
    word-break: break-word; font: 14px/1.45 ui-monospace, "Cascadia Mono", Consolas, monospace;
    background: var(--mono-bg); border: 1px solid var(--line); border-radius: 6px; padding: 10px;
  }
  pre .err { color: var(--err); }
</style>
</head>
<body>
<main>
  <header>
    <h1>@TITLE@</h1>
    <span class="sub">a Goose program, running as WebAssembly in this browser</span>
  </header>
  <div class="panel">
    <label for="args">Arguments</label>
    <input id="args" spellcheck="false" placeholder="words after the program name">
    <label for="stdin" style="margin-top:10px">Standard input</label>
    <textarea id="stdin" spellcheck="false" placeholder="what the program reads"></textarea>
    <div class="row">
      <button id="run" disabled>Run</button>
      <span id="status">Loading…</span>
    </div>
  </div>
  <div class="panel">
    <label>Output</label>
    <pre id="out" aria-live="polite"></pre>
  </div>
</main>
<script src="@SCRIPT@"></script>
<script>
"use strict";
const q = new URLSearchParams(location.search);
const $ = id => document.getElementById(id);
const out = $("out"), status = $("status"), runButton = $("run");

// Words as a shell splits them: spaces apart, quotes keep them together.
function splitArgs(text) {
  const words = [];
  const re = /"((?:[^"\\]|\\.)*)"|'([^']*)'|(\S+)/g;
  let m;
  while ((m = re.exec(text))) words.push(m[1] !== undefined ? m[1].replace(/\\(.)/g, "$1") : m[2] !== undefined ? m[2] : m[3]);
  return words;
}
function show(text, cls) {
  const span = document.createElement("span");
  if (cls) span.className = cls;
  span.textContent = text;
  out.appendChild(span);
  out.scrollTop = out.scrollHeight;
}

let stdoutText = "", stderrText = "";
async function run() {
  runButton.disabled = true;
  out.textContent = "";
  stdoutText = stderrText = "";
  status.className = "";
  status.textContent = "Running…";
  const input = new TextEncoder().encode($("stdin").value);
  let pos = 0, code = null;
  const started = performance.now();
  try {
    await gooseProgram({
      arguments: splitArgs($("args").value),
      print: t => { stdoutText += t + "\n"; show(t + "\n"); },
      printErr: t => { stderrText += t + "\n"; show(t + "\n", "err"); },
      stdin: () => (pos < input.length ? input[pos++] : null),
      onExit: c => { code = c; },
    });
    if (code === null) code = 0;
  } catch (e) {
    if (e && e.name === "ExitStatus") code = e.status;
    else { stderrText += String(e) + "\n"; show(String(e) + "\n", "err"); code = -1; }
  }
  const ms = Math.round(performance.now() - started);
  status.className = code === 0 ? "" : "bad";
  status.textContent = code === -1 ? `Stopped by an error (${ms} ms)` : `Exit code ${code} (${ms} ms)`;
  runButton.disabled = false;
  if (q.has("test-report")) {
    await fetch("goose-report", { method: "POST",
      body: JSON.stringify({ stdout: stdoutText, stderr: stderrText, code }) });
  }
}

if (q.has("args")) {
  try { $("args").value = JSON.parse(q.get("args")).map(a => /\s/.test(a) ? JSON.stringify(a) : a).join(" "); }
  catch (e) { $("args").value = q.get("args"); }
}
if (q.has("stdin")) $("stdin").value = q.get("stdin");
runButton.addEventListener("click", run);
if (typeof gooseProgram !== "function") {
  status.className = "bad";
  status.textContent = "Could not load @SCRIPT@: serve this folder over http (python -m http.server) and open the page from there.";
} else {
  runButton.disabled = false;
  status.textContent = "Ready";
  if (q.has("run")) run();
}
</script>
</body>
</html>
)html";

// The page for the module script `script`, titled `title`.
inline string WebPage(const string &title, const string &script) {
    auto escape = [](const string &s) {
        string out;
        for (auto c : s) {
            if (c == '&') out += "&amp;";
            else if (c == '<') out += "&lt;";
            else if (c == '>') out += "&gt;";
            else if (c == '"') out += "&quot;";
            else out += c;
        }
        return out;
    };
    string page = web_page_template;
    for (auto [key, value] : { pair<string, string>("@TITLE@", escape(title)),
                               pair<string, string>("@SCRIPT@", escape(script)) }) {
        for (size_t at = page.find(key); at != string::npos; at = page.find(key, at + value.size()))
            page.replace(at, key.size(), value);
    }
    return page;
}

}  // namespace goose
