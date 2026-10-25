# slice_pool versus reusable[]

`reusable` and `reusable[]` remain deprecated but available. These comparisons
keep the builtins as baselines; removal is a separate change. Application
measurements and migration decisions are in [pool_workloads.md](pool_workloads.md).

The library uses the builtin’s augmented B+ tree: first fit in address order,
adjacent-span coalescing, tail reuse, the same split points, node recycling and
root collapse. The tree-maintenance changes from `1ab1d26d` are included on
both sides. Differential tests check placement as well as contents.

## Current measurements

Measured 2026-10-25 on Windows, Ryzen 9 9950X3D, CPUs 16–31. Ratios are
library / builtin; smaller is better. Clang compiles the generated C at O2.
Each cell is the ratio of median process-cycle counts from seven interleaved
samples after two warmups, with identical checksums. The six-case means give
equal weight to each workload/size pair. These allocation-heavy loops have no
application work between operations.

| Workload | Bytes | O1 Clang | O1 TinyCC | O1 JIT total | O2 Clang | O2 TinyCC | O2 JIT total |
|---|---:|---:|---:|---:|---:|---:|---:|
| append | 8 | 0.938 | 1.015 | 1.189 | 0.902 | 1.022 | 1.179 |
| append | 128 | 1.019 | 0.989 | 1.063 | 0.990 | 0.992 | 1.006 |
| fragmented | 8 | 1.104 | 1.517 | 1.522 | 1.115 | 1.608 | 1.537 |
| fragmented | 128 | 1.129 | 1.553 | 1.488 | 1.133 | 1.483 | 1.461 |
| resize | 8 | 1.162 | 1.767 | 1.579 | 1.142 | 1.605 | 1.615 |
| resize | 128 | 1.149 | 1.495 | 1.460 | 1.106 | 1.480 | 1.370 |
| Geometric mean | | 1.081 | 1.357 | 1.370 | 1.061 | 1.338 | 1.344 |

Standalone TinyCC measures execution only. **JIT total** includes Goose
compilation, TinyCC compilation and execution, matching the default O1 command
path; it is not an allocation-only measurement. Process startup, initialization
and final checksumming are included on both sides. Wall times are also retained,
but were more sensitive to background activity than process cycles.

## Reproduce

```text
python bench/slice_pool.py --exe build-root/Release/goose.exe --levels 1 2 --calls natural --widths 1 16 --compilers clang tcc jit --reps 7 --warmups 2 --affinity 0xffff0000 --out build-root/review-final-slice
```

The harness saves Goose/C snapshots, logs, checksums, compiler and library
fingerprints, sizes and all samples under `--out`. The checked-in
[current results](slice_pool_results.json) contain this matrix. `--levels 0`
is also supported. `--calls natural` leaves the emitted C unchanged;
`boundary` adds `GS_NOINLINE` to the native `exercise` function, while `inline`
requests inlining. JIT always uses the compiler's unmodified output. TinyCC is
discovered beside the Goose build or on PATH. MSVC is available via
`--compilers msvc`; timings here use Clang, standalone TinyCC and the JIT.

## Interpretation and remaining work

Tree helpers take `nodes` and `tree` independently of the item type and live
in `slice_pool_detail`. Default runs, default aggregates and uniform fixed
arrays use bulk initialization where their semantics permit it. Slice moves
use checked `move_from`; `alloc_copy` initializes directly from existing values.
Path scratch remains initialized: no uninitialized storage or unchecked metadata
access was introduced.

The initial 8-byte O1 TinyCC measurements were about 1.76× for append, 2.41×
for fragmentation and 2.15× for resize. The current table shows a substantial
reduction, but fragmented allocation and resize still miss the general goal.
Clang O2 is close on average, with roughly 10–14% gaps on reuse/resize. Remaining
work includes metadata checks, path initialization and TinyCC’s handling of
Goose-generated temporaries and helper calls; these are not algorithm changes.
