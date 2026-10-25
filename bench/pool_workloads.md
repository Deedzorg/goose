# Pools in application benchmarks

`reusable` and `reusable[]` remain deprecated but available. Existing scalar
ports use `slot_pool`; slice ports use `slice_pool` except LangArena's
`Etc::CacheSimulation`, which remains on `reusable[]`. The candidate measured
here includes that remaining migration, so the whole-suite result answers the
cost of switching all LangArena slice users, including preparation.

## Current comparison

Measured 2026-10-25 on Windows x64, Ryzen 9 9950X3D, Clang 22.1.3. Both sides
use the same branch compiler at Goose O2. Builtin sources are from `94cc64da`;
scalar candidates are the current ports, and slice candidates mechanically
migrate those baseline sources. Algorithms, layouts, inputs and allocation
order are unchanged. Only the separately labeled `alloc_copy` trial replaces
allocate-then-copy with direct initialization.

Each side has three renamed executable copies, one warmup per copy and three
measured runs per copy, with alternating backend order. Ratios are library /
builtin, using medians of all nine samples. Single-thread cases use CPU 28;
the whole suite uses CPUs 0–15 so threaded cases retain sixteen logical CPUs.
LangArena and scalar builds align functions to 4096 bytes. The harness passes
that option through `/clang:` when using clang-cl. LangArena uses its native
O2 flags; kostya2 keeps its O3/native/LTO flags and TCP timing protocol.

| Workload | Observation | Builtin | Library | Ratio |
|---|---|---:|---:|---:|
| lru_indices | process cycles, millions | 1989.4 | 1959.0 | 0.985 |
| lru_nonopt | process cycles, millions | 1925.6 | 1925.2 | 1.000 |
| plb_lru_1 | process cycles, millions | 496.6 | 496.9 | 1.001 |
| plb_lru_2 | process cycles, millions | 204.9 | 206.1 | 1.006 |
| merkletrees | process cycles, millions | 522.6 | 545.7 | 1.044 |
| Etc::CacheSimulation | timed seconds | 0.9120 | 1.1620 | 1.274 |
| Graph::BFS | timed seconds | 0.8380 | 0.8660 | 1.033 |
| Graph::BFS | preparation seconds | 0.7365 | 0.8560 | 1.162 |
| Graph::BFS | whole-process seconds | 1.7620 | 1.9126 | 1.085 |
| kostya2/primes | timed seconds | 0.0322 | 0.0346 | 1.073 |
| LangArena, all 50 cases | sum of timed windows, seconds | 22.707 | 22.928 | 1.010 |
| LangArena, all 50 cases | whole-process seconds | 29.938 | 30.567 | 1.021 |
| LangArena, all 50 cases | whole-process cycles, billions | 169.215 | 171.654 | 1.014 |
| CacheSimulation, alloc_copy trial | timed seconds | 0.936 | 1.153 | 1.232 |

The full-suite run checks all 50 upstream results on every execution. Whole
process time includes constructors, preparation, warmup, timed work and teardown.
Its **+2.1% wall time / +1.4% process cycles** replaces the earlier component-based
estimate. The reported timed windows alone increase by about 1.0%; preparation
is 2.623 → 3.048 seconds. These are ratios of medians, not a weighted prediction
or a claim that every benchmark meets a 1% threshold.

Scalar ratios use Windows process cycles because background scheduling caused
large wall-time outliers in the short LRU runs; all samples of both metrics are
retained. `lru_nonopt` is 1.000× in this controlled run. Merkle remains about
4.4% slower. Capturing callbacks retain their recursive frame for correctness;
capture-free callbacks still permit leaf-call elimination. Both the old free
spelling and `free_ref` showed the same larger gap when that safe optimization
was disabled. Merkle's remaining gap is not explained by that wrapper.

CacheSimulation remains a real regression: +27.4% in its timed window and
process cycles for the mechanical migration. `alloc_copy` reduces the measured
gap to about 23%, but does not make it negligible. Its published source therefore
stays on the builtin. Graph's allocator runs during preparation (+16.2%), outside
its search timer; the search ranges overlap, while whole-process cost is +8.5%.
Primes is +7.3% in its short timed window (+4.1% whole process). Existing migrated
ports are retained; these measurements do not claim universal parity.

## Compiler and allocator costs

The slice allocator has the same augmented B+ tree as `reusable[]`: first fit
in address order, adjacent-span coalescing, tail reuse, node recycling and root
collapse. The tree-maintenance changes from `1ab1d26d` are on both sides.
Differential tests compare placement and contents, including the 60,000-operation
model. No bounds, containment, overflow or initialization checks were disabled.

Tree helpers now take `nodes` and `tree` independently of the element type.
LangArena emits one body each for `place`, `fix` and `delete`, instead of one per
item type. Its C grows from 2,611,464 to 2,694,704 bytes (+3.2%), and its executable
from 1,272,320 to 1,293,312 bytes (+1.7%). An interleaved five-sample compile-only
rerun after one warmup measured 1.012 → 1.062 billion process cycles (+4.9%), or
0.242 → 0.254 seconds. Both emitted C files exactly match the runtime measurement
builds; the initial noisier compilation samples are also retained in the JSON.

Bulk zero defaults, uniform fixed-array initialization and overlap-safe
`move_from` remove element loops where their semantics permit it. `alloc_copy`
also avoids default-initializing values that the source immediately replaces.
The [slot matrix](slot_pool.md) and [slice matrix](slice_pool.md) cover Goose
O1/O2 with native Clang, standalone TinyCC and compile-plus-run JIT timings.
The final compiler and libraries reproduce all 48 microbenchmark C files except
source paths/diagnostic line numbers; their original measurement fingerprints
remain in the results. Native slot allocation is around parity. Slice allocation
is about 6% slower on average at Clang O2 and 34% at TinyCC O2, with larger gaps
in fragmented allocation and resize. Append is close on both backends.

## Reproduce

The upstream checkout paths below supply LangArena configurations and kostya2's
measurement helpers; the Goose sources come from this repository. See the JSON
for configuration/source hashes and exact compiler flags.

```text
python bench/slot_pool_users.py --exe build-root/Release/goose.exe --baseline 94cc64da --out build-root/review-final-slot-users --copies 3 --reps 3 --warmups 1 --cpus 28
python bench/pool_workloads.py --exe build-root/Release/goose.exe --arena C:/W/LangArena --kostya C:/W/kostya-benchmarks --out build-root/review-final-apps-measured --construct-timer --only Etc::CacheSimulation Graph::BFS kostya2/primes --copies 3 --reps 3 --warmups 1 --cpus 28
python bench/pool_workloads.py --exe build-root/Release/goose.exe --arena C:/W/LangArena --kostya C:/W/kostya-benchmarks --out build-root/review-final-apps-measured --reuse-builds --results whole.json --only LangArena::All --copies 3 --reps 3 --warmups 1 --cpus 0-15
```

Use `--whole-suite` to append the complete LangArena run to a selected set, or
`--alloc-copy` in a separate output directory for the direct-copy candidate.
`--compile-reps` defaults to five interleaved samples. `--reuse-builds` intentionally
uses the saved binaries and their metadata, even if compiler or source files have
since changed. [Current raw results](pool_workloads_results.json) contain the
application, whole-suite, scalar, compile-only and direct-copy measurements.

## Remaining work

- A root-reference ABI that forwards component headers/stacks directly through
  calls while retaining descriptor identity for stored, captured and optional
  references. The prototype passing both a descriptor and split fields did not
  materially improve TinyCC and was discarded; it does not rule out a more
  complete escape-sensitive design.
- Further reduction of checked tree metadata accesses, scratch initialization
  and Goose-generated temporaries/helper calls, especially under TinyCC.
  Scratch remains initialized; broad forced inlining did not improve the trials.
- Compile-time diagnostics for provably wrong-pool slice frees. Runtime
  containment remains checked; `free_ref` retains compile-time provenance checks.
- Automatic root-owner worker transfer. A tested flat snapshot recipe is in
  [the worker sample](../samples/32_pool_worker_snapshots.goose); the
  [migration guide](../docs/stdlib.md#migrating-from-reusable) explains the gaps.

These Windows measurements do not replace Linux/macOS or sanitizer CI, nor the
public suites' cross-language results. Builtin removal and final history
consolidation are separate review/landing decisions.
