# slot_pool versus reusable

`reusable` and `reusable[]` remain deprecated but available. These comparisons
keep the builtins as baselines; removal is a separate change. Application
measurements and migration decisions are in [pool_workloads.md](pool_workloads.md).

The library uses the builtin’s LIFO free-index policy. Both versions allocate
initialized slots, retain stable addresses, and check indices. The workload
uses two local owners, calls the same `exercise` helper with each, and checks
allocation order and final contents.

## Current measurements

Measured 2026-10-25 on Windows, Ryzen 9 9950X3D, CPUs 16–31. Ratios are
library / builtin; smaller is better. Clang compiles the generated C at O2.
Each cell is the ratio of median process-cycle counts from seven interleaved
samples after two warmups, with identical checksums. The six-case means give
equal weight to each workload/size pair. These allocation-heavy loops have no
application work between operations.

| Workload | Bytes | O1 Clang | O1 TinyCC | O1 JIT total | O2 Clang | O2 TinyCC | O2 JIT total |
|---|---:|---:|---:|---:|---:|---:|---:|
| append | 8 | 1.033 | 1.081 | 1.030 | 1.041 | 1.097 | 1.038 |
| append | 128 | 0.981 | 1.047 | 1.100 | 0.993 | 1.069 | 1.048 |
| lifo | 8 | 0.923 | 1.199 | 1.135 | 0.916 | 1.143 | 1.138 |
| lifo | 128 | 0.938 | 0.922 | 1.004 | 0.949 | 1.011 | 0.956 |
| scattered | 8 | 0.916 | 1.154 | 1.127 | 0.893 | 1.175 | 1.131 |
| scattered | 128 | 0.951 | 1.080 | 0.968 | 0.947 | 1.112 | 1.011 |
| Geometric mean | | 0.956 | 1.077 | 1.059 | 0.955 | 1.100 | 1.052 |

Standalone TinyCC measures execution only. **JIT total** includes Goose
compilation, TinyCC compilation and execution, matching the default O1 command
path; it is not an allocation-only measurement. Process startup, initialization
and final checksumming are included on both sides. Wall times are also retained,
but were more sensitive to background activity than process cycles.

## Reproduce

```text
python bench/slot_pool.py --exe build-root/Release/goose.exe --levels 1 2 --calls natural --widths 1 16 --compilers clang tcc jit --reps 7 --warmups 2 --cpus 16-31 --out build-root/review-final-slot
```

The harness saves Goose/C snapshots, logs, checksums, compiler and library
fingerprints, sizes and all samples under `--out`. The checked-in
[current results](slot_pool_results.json) contain this matrix. `--levels 0`
is also supported. `--calls natural` leaves the emitted C unchanged;
`boundary` adds `GS_NOINLINE` to the native `exercise` function, while `inline`
requests inlining. JIT always uses the compiler's unmodified output. TinyCC is
discovered beside the Goose build or on PATH. MSVC is available via
`--compilers msvc`; timings here use Clang, standalone TinyCC and the JIT.

## Interpretation and remaining work

`alloc_ref` returns the append result directly. Index builders and reference
frees are available as `alloc_index_with` and `free_ref`; application results
using them are in [pool_workloads.md](pool_workloads.md). The library keeps its
index checks, and no occupancy tracking or private-field assumption was added.

Native Clang meets the general microbenchmark goal. TinyCC still has a modest
average gap and a larger gap for tightly repeated 8-byte reuse. A prototype
passing the canonical root descriptor plus separate component arguments did
not materially close that gap and was not retained. An escape-sensitive ABI
that also forwards component arguments remains a separate compiler project.
