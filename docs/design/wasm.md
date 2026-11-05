# Running Goose on WebAssembly

<details>
<summary>Table of contents</summary>

- [1. The problem](#1-the-problem)
- [2. What every option needs: growth checks](#2-what-every-option-needs-growth-checks)
- [3. Fixed partitions](#3-fixed-partitions)
- [4. Relocating stacks](#4-relocating-stacks)
- [5. Options that do not work today](#5-options-that-do-not-work-today)
- [6. Where relocation's changes fall](#6-where-relocations-changes-fall)
- [7. Wasm costs outside the data stacks](#7-wasm-costs-outside-the-data-stacks)
- [Recommendation](#recommendation)
- [8. Status and staged plan](#8-status-and-staged-plan)

</details>

Milestones 1 to 4 of the plan in [§8](#8-status-and-staged-plan) are
implemented on the fork branch `feature/wasm`: `goose build --target wasm64`
with fixed partitions, the growth checks of §2 (`GS_GROWTH_CHECKS`),
`--target wasm64-web` with a page that runs the program in a browser, and
threads on both and the gfx package on the web, through WebGPU. The rest is a
proposal. Spec §10.4 says that platforms
without address-space reservation fall back to "index-based references +
bounds-checked growth", and leaves the details open (open issue 15). This
note works them out. Its cost figures are estimates, not measurements.

## 1. The problem

Each data stack is a region of reserved address space, committed as it is
touched ([spec §1.2](../goose_spec.md#12-memory-model),
[§10.4](../goose_spec.md#104-runtime-environment),
[implementation §7](../implementation.md#7-the-runtime)). Growth is a
pointer bump with no capacity check, and a guard gap past each region turns
an overrun into an abort. References into a stack are plain addresses and
stay valid across growth because a stack's base never moves, a property the
language is built around ([tutorial](../tutorial.md#nothing-moves-so-references-survive-growth)).

WebAssembly has none of this. A module's linear memory grows only at its end,
has no unmapped pages inside it, and in wasm32 holds at most 4 GB. A port that
gives each of a few stacks a small fixed size works, but only toy programs
fit.

## 2. What every option needs: growth checks

Linear memory has no guard pages, so a region that overruns writes into the
next one. Every approach therefore checks growth, `if (lim - top < n)`,
including a port that keeps fixed regions. The options differ in what a
failed check does: abort, or move the stack. Only moving forces a different
pointer representation.

The checks go wherever a stack's top moves up:

* pushes, appends and `resize` (`EmitPush`, `EmitAppend`);
* in-place construction: `str()`, `to_bytes()`, `print`'s rendering, a
  length prefix reserved and patched afterwards (`OpenRzDest`,
  `EmitReprefix`, `EmitSlidePrefix`, varint prefixes), frame objects, the
  `_er` twins, the generated walkers;
* the runtime: a slice pool's freelist, which grows on a stack of its own
  (`gs_spans_*`), `gs_bld_append` in `goose.h`, and the helpers that write at
  a top with no bound, such as `gs_fmt_i64(top, v)` (up to 20 bytes). Each of
  these needs a reservation first: a worst case for a scalar, a check per
  chunk when rendering a nested value.

The top caches ([implementation §6.10](../implementation.md#610-loop-invariant-views-and-stack-top-caching))
become (top, limit) pairs, synchronized at the same points. A loop with a
known trip count can reserve once before it.

## 3. Fixed partitions

Each stack gets a fixed slice of linear memory, and a failed check aborts
with the overrun message native builds give. This is mostly configuration of
the existing runtime: `GS_STACK_RESERVE` is the linear memory divided by the
region count, and `GS_STACK_BUDGET` is the linear memory, which the runtime
already uses to cap `hardware_threads()`.

* **RAM.** On 64-bit desktop engines, linear memory that is grown but never
  touched is generally not backed by RAM (Windows charges commit for it), so
  growing to the maximum at startup wastes address space, not memory.
  Browsers may refuse a large memory on small devices, and Wasm cannot give
  pages back after a peak (there is no `memory.discard`).
* **Capacity.** The real limit is each stack's size. Programs need few
  regions: `--stacks` reports 5 for `samples/14_bst`, 6 for
  `12_huffman`, 10 for `18_json` (8 stacks and 2 globals' stacks), and 6
  for `23_mandelbrot_threads` plus 2 per worker. 4 GB over 10 regions is
  400 MB per stack. Workers multiply the count.
* **Sizing from a profile.** The high-water mark of each stack index in a
  representative run could be used to give the partitions different sizes.
  On Windows the fault handler commits on demand and so can report each
  region's depth (its commit mark). macOS and Linux would need explicit
  instrumentation to track the highest top across stack rewinds.
  `GS_STACK_STATS` reports only counts today. Stack numbering is
  specific to one build, and a profile fits only the input it came from,
  while the inputs that overflow are the large ones.
* **The open end.** The partition at the end of linear memory can keep
  growing with `memory.grow`. If the stack most likely to hold the
  program's large resizable is placed there, the common case (one big
  growing array) is limited only by the memory's own maximum.
* **wasm64** removes the 4 GB address limit in principle, but browsers still cap
  memory64 (V8 at 16 GB), and each access needs an explicit bounds check.
  wasmtime can reserve much more and commit it lazily. Fixed partitions under
  wasm64 therefore work much like the native model and are a practical choice
  for WASI and server-side targets.

## 4. Relocating stacks

Each stack is a heap block that moves to a block twice its size when a
growth check fails. Since a stack can move, a reference cannot hold an
address: it holds a handle.

* **Encoding.** A handle is one `u64`: the stack's id in the high bits and the
  offset in the low bits. A handle with id 0 holds a plain address, for
  static data, C memory and clang's shadow stack (where address-taken fixed
  locals live). Its base table entry is 0. References stay 8 bytes, so every
  layout stays the same as on the 64-bit hosts the C backend targets
  (implementation §6.1). The base table belongs to the thread program, like
  `gs_stks`, and also covers the globals' dedicated stacks.
* **Arithmetic is unchanged.** `base + i * size`, field offsets, the
  cursors that walk variable-size fields (`FieldPtr`), differences within a
  stack and a pool's range test all work on the integer. Only loads, stores
  and the `mem*` calls decode a handle; in wasm32 the decode is
  `bases[h >> 32] + (uint32_t)h`.
* **Relative references and pools need no change.** They are offsets within
  one stack, and a stack moves as a whole.
* **Decodes can be hoisted.** A decoded pointer stays valid until its stack
  grows. A decode can be hoisted over an extent with no growth of that stack
  and no call that can reach it, and top caching already computes those
  extents (`SyncReach`, `PlanTopCaches`). Array loops through hoisted views
  (`AddView`) then run as they do natively. The cost falls on pointer chasing
  (a decode per hop through a `T&`) and on pushes, whose check fixed
  partitions need too. The estimated time is 1.1 to 1.5 times that under
  fixed partitions, worst on tree and list code. The doubling amortizes the
  copying on relocation. Counting the old and new blocks and fragmentation,
  peak memory is up to two to three times the live data.
* **Threads.** Each thread program has its own base table, thread-local. A
  spawn copies flat images, so no handle crosses threads.

## 5. Options that do not work today

* **Multi-memory.** A memory per stack would keep offsets stable across
  `memory.grow`, but a load names its memory as an immediate. Stacks are
  chosen at run time (`gs_sp + k`, a fat reference's `stk`), and C cannot
  target several memories.
* **The memory-control proposal** (`memory.discard`, protect, map) would bring
  back reserve, commit and guard pages, and with them the native model. It
  has not shipped.
* **GC arrays** cannot grow, so they relocate as heap blocks would, and C
  cannot reach them.
* **A Wasm dialect that forbids references across growth** breaks the
  property the language is built around.

## 6. Where relocation's changes fall

In order of risk, not size:

1. **In-place construction while the same stack grows** (the list in §2).
   Natively, a held pointer to a slot's start or to a prefix still to be
   patched survives growth. Under relocation it must be a handle, or be
   derived again after the growth.
2. **The assumption that the base never moves.** View hoisting relies on it
   (its safety argument is that growth writes only the length), and so do
   the top caches, reference aliases (`refalias`) and `let first .=
   v.push(...)`. Little code depends on this assumption, but that code holds
   most of the potential bugs. The rule that contains them is to use handles
   everywhere, and decoded pointers only over extents that the sync analysis
   proves.
3. **The C boundary**: the runtime, `extern fn`s, the blessed packages and
   `goose.h`. The C ABI can stay on plain pointers. Slices and references are
   decoded at the call, since a C callee can grow a Goose stack only through
   a builder. A builder parameter gets a staging stack whose contents are
   appended after the call returns. Packages then recompile unchanged, with
   `gs_bld_append` gaining its capacity check.
4. **The way codegen writes memory accesses**, which is mechanical work to
   change. A rough count is 35 `*(T *)` dereferences, 140 emitted `->`, 26
   `mem*` calls and 21 `->top`, mostly through `LoadLoc`, `IndexLoc`,
   `DerefLoc`, `PointeeLv` and `VarLoc`.
5. **Unchanged**: the parser, the typechecker, the optimizer, BCE apart from
   view hoisting, and the standard library, which is Goose source the same
   codegen compiles. The library's only contact with C is its externs: math on
   scalars, `find_any` and `find_pair` on slices, `os`'s builders, and
   `json`'s `frexp` with an `i32&`.

## 7. Wasm costs outside the data stacks

* **Native call stack overflow.** The runtime reports it as a runtime error
  (implementation §7). Wasm has no vectored handler or `sigaltstack`, so the
  engine traps instead. Clang's shadow stack (64 KB by default) overflows
  silently unless checked (`-z stack-size`, Emscripten's
  `STACK_OVERFLOW_CHECK`).
* **The OS layer** (`runtime_os.h`) maps onto WASI or Emscripten.
* **Threads** need shared memory, which browsers give only to
  cross-origin-isolated pages.

## Recommendation

1. Add the growth checks of §2 as a configuration of their own. Native
   builds can run with them, so the existing test suite covers them. Fixed
   partitions are then only a matter of configuration, and they make a
   working port for programs whose stacks fit.
2. If that is not enough, add relocation as a native configuration first:
   stacks in heap blocks that move on growth. Give it a stress setting that
   moves a stack on every growth, so the test suite exposes every stale
   decoded pointer, and use the benchmark suite to measure the cost. Only
   then bring in a Wasm toolchain.

## 8. Status and staged plan

### Why wasm64 first

The C backend lays out a reference as 8 bytes and a slice as 16
([implementation §6.1](../implementation.md#61-values)), and references can be
fields, so wasm32's 4-byte pointers would change layouts throughout codegen.
64-bit WebAssembly (memory64) keeps every layout as it is, and the generated C
compiled unchanged on the first try. Memory64 runs in Node 24, Chrome and
Firefox, but not in WASI runtimes, whose preview 1 interface is 32-bit. So the
first target is Emscripten's `wasm64`, run by Node. wasm32 needs the handles
of §4 or 4-byte references, and is a later milestone.

### Milestone 1: `goose build --target wasm64` under Node (done)

```
goose build --target wasm64 prog.goose     # prog.js + prog.wasm
node prog.js args...
```

* **Toolchain.** Emscripten, found by `--cc` (emcc, emcc.py or an emsdk
  directory), else `EMSDK`, else `emcc` on PATH (`FindEmscripten`,
  toolchain.h). On Windows Goose runs `emcc.py` with the emsdk's Python
  rather than the batch file. The runtime object is cached per Emscripten
  version, as for any C compiler.
* **Flags** (build.h): `-m64` for compiling, and for linking
  `-sENVIRONMENT=node -sNODERAWFS=1` (the real file system, for `os`),
  `-sEXIT_RUNTIME=1`, memory that grows to Node's 16 GB memory64 cap, and an
  8 MB native stack.
* **Data stacks: fixed partitions (§3) without growth checks.** Each
  region is 64 MB by default (`--stack-reserve` changes it), taken from the
  end of linear memory with `sbrk`, untouched. Emscripten's `mmap` would
  zero all of it. A region's 1 MB gap is zeroed instead of protected, and the
  runtime reports a region whose gap is no longer zero as the program ends
  (`gs_gaps_overrun`, at `gs_end` and `atexit`): the same message as a
  native overflow, exit code 1. This finds an overrun late, not as it
  happens: the program has already run on, and a write that skipped the gap
  or wrote zeros goes unseen. Milestone 2's growth checks now stop the
  overrun as it happens; the gap scan stays behind them, and reports what
  no check stopped as a Goose bug.
* **Refused with a message:** threads (`cg.usesthreads`), packages with
  native parts (gfx, physics, ui, audio), `--target` outside `goose build`.
  Milestone 4 lifted the first two.
* **Test:** `test/wasm_target.py`, run by `test/run_tests.py`; skipped
  without Emscripten or Node. It builds six samples that cover arguments,
  stdin, files, a C header and JSON, compares them with `samples/expected/`,
  checks that an overrun of a 256 KB stack is reported and that the same
  program fits in 64 MB, and checks the refusals.
* **Result on Windows (Emscripten 6.0.13, Node 24.19):** 25 of the 31 samples
  build and print their expected output byte for byte. The other six are
  the threads sample and the five gfx/physics/ui samples, all refused as
  above. Rough speed against the native clang-cl build: sieve 64 vs 57 ms,
  raytrace 12 vs 5.7 ms, image filters 5.8 vs 0.47 ms (no SIMD yet).

### Milestone 2: growth checks (done)

`GS_GROWTH_CHECKS` (§2, recommendation 1): on by default in wasm64 builds,
and natively with `-DGS_GROWTH_CHECKS=1`. The compiler writes the checks only
into code built with it, so native builds without it are unchanged. A failed
check ends the program with the native overflow message as the overrun
happens, which is what makes wasm64 builds memory-safe for stacks that
outgrow their partition.

* **A limit beside each top.** `gs_stack` gains `lim`, which
  `gs_reserve_region` sets `GS_GROW_SLACK` (64 KB, at most half the region)
  short of the region's end under the checks, and at the end otherwise.
* **Checked after, or before.** Most growth moves a top by a small constant
  after writing at it. `Bump` checks the top against the limit after every
  move (`GS_GROWN`): a step of at most 32 KB (`GROW_STEP`) cannot have
  written past the slack. A write of a run-time or larger size is checked
  before anything is written (`GS_ROOM`): copies and fills at a top, a
  resize's fill, whole appends, received messages, `to_bytes` and
  `from_bytes`, rendered text. A count times an element size is checked by
  division (`GS_ROOM_ELEMS`), since the product of a count the program chose
  can wrap. `gs_fmt_quoted`, at most two bytes per byte, is checked for its
  worst case.
* **The runtime** checks C's builder appends (`gs_bld_append`, in the
  runtime and in `goose.h`, which prints and exits where a JIT run's library
  has no runtime to call) before copying, and a slice pool's freelist after
  each 512-byte node (`gs_top_grown`, by the region the top is in).
  `from_bytes`'s scratch bitmap stays a `false` result, not an abort, when
  the stack's limit cannot hold it.
* **A missed check shows itself.** In a native build with the checks, the
  slack means no checked growth can reach the guard gap, so a fault there is
  a check the compiler left out: its report adds "no growth check stopped
  it: a Goose bug". wasm64's gap scan at exit says the same.
* **Tests.** `test/growth_checks.py` builds the seven programs of
  `test/growth/` (pushes, a resize, whole appends, in-place text, a whole
  array rendered and its `to_bytes`, records built field by field and copied,
  `read_file` into a builder) natively with the checks: on a 256 KB stack
  each is stopped by a check, and on the default stack each prints its
  result. `test/wasm_target.py` builds the same programs as wasm64 and checks
  that each is stopped before it prints. `run_tests.py --growth-checks`
  compiles every fixture with the checks: with them, the whole suite passed
  on Windows (2026-11-02), except `extern dylib`, which fails the same way
  without them (its test library build passes `-fPIC` to clang on Windows).
* **Cost, native** (clang-cl 19 `-O2`, best of 5, the middle size of
  `bench/run_bench.py`): geometric mean ×1.028 over 18 benchmarks, worst
  `graph_csr` ×1.16, `calc` ×1.10 and `graph` ×1.09, most within a few
  percent. Every one printed the same output with and without the checks.
* **Cost, wasm64** (Emscripten 6.0.13 under Node 24, the same runs, whole
  process including Node's start of about 0.15 s): geometric mean ×1.024,
  worst `graph_csr` ×1.10 and `particles` ×1.09.
* **Not checked**, as natively: a worker restoring its copy of the globals,
  which came from stacks with the same limits.

### Milestone 3: the browser (done)

```
goose build --target wasm64-web --web-files data prog.goose   # prog.js, .wasm, .html, .data
python -m http.server                                         # then open prog.html
```

* **The build** (build.h): `-sENVIRONMENT=web -sMODULARIZE=1
  -sEXPORT_NAME=gooseProgram`, with the same memory, stack, growth checks
  and runtime object as `wasm64`. Files live in Emscripten's memory file
  system: `--web-files dir[@to]` packs a directory into it
  (`--preload-file`, `prog.data` beside the page) for a program that reads
  files, at the same relative path by default, so `--web-files data` lets
  `data/alice.txt` open as it does natively.
* **The page** (`prog.html`, from `web_page.h`): boxes for the arguments
  (split as a shell splits them) and standard input, a Run button, the
  output with standard error in red, and the exit code and time. Every run
  calls `gooseProgram` again, a fresh instance, as a new process would be.
  `?run` runs it as the page opens, and `?args=[...]` and `?stdin=...` fill
  the boxes, so a link can show a program running. Light and dark follow
  the system. A page opened from `file://` cannot load the module, and says
  to serve the folder over http.
* **Test:** `test/wasm_web.py`, run by `test/run_tests.py`: pages for the
  tour, `word_freq` (files from `--web-files data`), `calc` (standard input)
  and an overrun of a 256 KB stack, served from a local server and opened in
  headless Chrome or Edge (`GOOSE_TEST_BROWSER` names another). Each runs
  as it opens and, with `?test-report`, posts its output and exit code back
  to the server, which compares them with `samples/expected/`; the overrun
  must be stopped by a growth check. Skipped without Emscripten or such a
  browser. Passes on Windows with Chrome 156 (about 20 s).
* **Not yet:** no page can hand the program a file of the viewer's own, and
  `goose build` does not serve the page itself; both are small additions.

### Milestone 4: threads and gfx (done)

```
goose build --target wasm64 23_mandelbrot_threads.goose        # node 23_mandelbrot_threads.js
goose build --target wasm64-web 27_gfx_cube.goose               # draws on the page's canvas
```

**Threads.** A program that starts threads or uses queues (`cg.usesthreads`)
builds and links with `-pthread`: each Goose thread is a pthread on a Web
Worker (a Node worker under Node) over shared memory, with the runtime's
POSIX path unchanged.

* **Main on a worker** (`-sPROXY_TO_PTHREAD`): `thread_wait` and queue waits
  block, which a browser's own thread may not, so `main` runs on a worker
  and the browser's thread stays free to start the others. A pool of
  workers, one per core and one for main
  (`-sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency+1`), loads with the
  module: a Web Worker takes milliseconds to start, which on demand made
  the threads sample slower than its serial run. A worker's native stack
  is 2 MB (`-sDEFAULT_PTHREAD_STACK_SIZE`).
* **Ending.** `_Exit` from a pthread ends only that worker, so `gs_end`
  calls `emscripten_force_exit`, which ends the program on the browser's
  thread, every worker with it: aborts in main or in a worker exit as they
  do natively.
* **Regions are reused.** Linear memory is never given back, and a worker
  takes its own regions, so a released region goes on a free list for the
  next reservation of its size (`gs_os_reserve`), its guard gap scanned
  first: a worker's gap is now checked as it ends, where before only
  main's was, at exit. Without reuse, 300 threads one after another would
  need 39 GB of a 16 GB memory. What a region held stays in it; Goose has no
  read path to a slot that was never written (spec §5.3).
* **Budget.** `GS_STACK_BUDGET` is 12 GB for wasm64 (the rest of the 16 GB
  for the C heap, native stacks and the module), which is what caps
  `hardware_threads()` there, and the runtime object is cached apart for
  `-pthread` builds (`-mt`).
* **Pages.** Shared memory needs a cross-origin isolated page (headers
  `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp`). `python -m http.server`
  sends neither, so a threaded build writes `goose-coi.js` beside the page,
  a service worker that adds them; the page registers it and loads once
  more under it. A server that sends the headers makes it unneeded. Either
  way the page waits for `onExit`, not the module's promise, since main
  runs on.
* **Tests.** `test/wasm_target.py` runs the threads sample and every
  `test/threads` fixture under Node and compares them with
  `test/expected/` (stdout, the exit, and stderr for those that abort), all
  but two: `thread_cap` (its budget is sized for native 2 GB regions) and
  `thread_stack_overflow` (V8 ends a native recursion that deep with its own
  "Maximum call stack size exceeded" before the runtime can report it; the
  same holds for main without threads). It also starts 300 threads one
  after another and checks the last still gets 64 MB regions.
  `test/wasm_web.py` opens the threads sample twice, served with the
  headers and without them (the service worker's way).
* **Speed.** Starting 12 threads that do nothing takes about 1 ms under Node
  (0.7 ms native). But on this PC (Ryzen 5 2600, 6 cores) compute does not
  scale under Node 24: 12 threads each running the same loop take about
  2.5 times as long as one, where natively they take about the same, and
  the threads sample's pool takes ~180 ms against 50 ms serial (native: 5
  ms against 35). Nothing is shared in the loop; it looks like V8's, not
  Goose's, and is worth measuring in browsers and on other machines.

**gfx.** SDL 3.4 has no WebGPU driver for SDL_GPU, so the compiler carries
one: `src/web/SDL_gpu_webgpu.c` (an SDL_GPU backend, about 1,500 lines)
and `src/web/sdl_gpu_webgpu.js` (its JavaScript half over `navigator.gpu`, about 570),
embedded at the compiler's build (CMakeLists.txt) and written under
`GOOSE_HOME/build/web/<hash>/` on use. The gfx package itself is unchanged.

* **Shaders.** A web build compiles each `embed_shader` with cute_spirv's
  WGSL backend (`gs_shaderc_compile_web`), and the blob carries, where the
  SPIR-V goes, a `GSWG` payload: the bindings and the WGSL (`gfx_blob.h`).
  The package hands those bytes to `SDL_CreateGPUShader` as SPIR-V, unread,
  and the backend reads them. MSL and HLSL are left out. Native blobs are
  unchanged.
* **The build.** The package's C (SDL, the gfx, ui and audio layers;
  physics too) is built by Emscripten through its CMake toolchain file and
  Ninja, as 64-bit wasm (`BuildCMakePart`); for a package that builds SDL,
  the wrapper adds the backend to `SDL3-static` and defines
  `SDL_GPU_PRIVATE`, which makes SDL_GPU take it as its private driver
  (`PrivateGPUDriver`). SDL's own validation stays in front of it. About
  75 s the first time, cached after.
* **Waiting** without blocking the page: the device, every frame and every
  read back are asynchronous in WebGPU, so the program is linked with
  `-sJSPI` and those calls suspend it (JavaScript Promise Integration,
  Chrome 137 and later): `SDL_WaitAndAcquireGPUSwapchainTexture` waits for
  the browser's next animation frame, which paces the loop to the display
  and lets the page deliver input, and `gfx::frame()` loops run as they do
  natively.
* **Binding.** SDL_GPU's sets are the WGSL's groups (vertex 0 and 1,
  fragment 2 and 3, compute 0 to 2). Resource groups become bind groups
  made at the draw that needs them; uniform pushes go to a 4 MB ring, 256
  bytes apart, written to the GPU as their command buffer is submitted and
  bound with dynamic offsets. Uploads and downloads go through staging
  buffers in the command encoder, in order with the rest, rows padded to
  WebGPU's 256 bytes; a download lands in its transfer buffer when its
  submission's fence settles, which `SDL_WaitForGPUFences`, `WaitForGPUIdle`
  and mapping a download buffer wait for. Blits and mipmaps are a triangle
  through a small WGSL pipeline.
* **The page** shows a canvas (`#canvas`, SDL's) when the program uses gfx,
  and waits for `onExit`. A browser with no WebGPU adapter gets gfx's own
  message (`gfx: no GPU device: ...`).
* **Refused:** gfx for `--target wasm64` (Node has no canvas), and gfx with
  threads in one program (JSPI and a main on a worker do not mix yet).
* **Not done:** read-write storage images that WebGPU cannot bind as one
  (cute_spirv splits them; the backend refuses such a shader), compute
  samplers' fine points, MSAA beyond 4 samples, `rgba32float` filtering
  without the device feature, wireframe fill.
* **Tests.** `test/wasm_web.py`'s `check_wasm_web_gfx`: the five samples
  that draw (cube, physics boxes, ui to-do, mini Minecraft with its own
  checks, mini Doom with the Freedoom map packed by `--web-files`), each run
  with its native test arguments in headless Chrome with WebGPU, print
  their `samples/expected/` output, which for each includes reading the
  last frame back from the GPU and saving it as a PNG; and the two
  refusals. Skipped where the browser gives no adapter. All pass on Windows
  with Chrome 156 on the Radeon RX 580.

### Still to do

* `-msimd128`, and a look at what keeps the image filters slow.
* `goose toolchain` reporting Emscripten, and `--target` in Goose Studio
  (build for the web from the IDE).
* gfx with threads; files a program writes offered to the viewer to save.

### Milestone 5: wasm32 and WASI

Relocating stacks with handles (§4), or 4-byte references, so the same
programs run as wasm32 under wasmtime and other WASI runtimes, and in Safari.
