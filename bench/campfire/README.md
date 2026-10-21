# Campfire in Goose: experimental prototype

This is a partial Campfire implementation on `codex/campfire-experiment`.
Its bounded response cache was built, tested and measured with compiler
`8511ae34`. The branch is now rebased onto `master` at `a17e84d8`; that compiler
exposes the HTTP-package build blocker below. There is no measured Rust/Jai
comparison and no claim of feature parity.
The files are contained under `bench/campfire` so the experiment can be moved to
its own repository later. It is not on `master`.

## Current build blocker

Compiler `a17e84d8` rejects goose-http `v0.4.3` at `uring.goose:329`:

```text
cannot call h2_answer: it shrinks h2fields while h is still used,
and h may refer into h2fields (§5.1)
```

The preceding master, `f605b5a0`, successfully typechecks the complete server
at O2. After the holder-reference cherry-pick, even the minimal server in
`repro/http_compatibility.goose` is rejected. It contains no Campfire code or
cache. This is an integration regression introduced by the compiler change;
whether the rejected path is actually unsafe still needs a smaller analysis
of the reference effects. Runtime HTTP/1.1 configuration does not avoid
typechecking this HTTP/2 path.

Performance work is paused. The preferred next step is to reduce and correct
the compiler regression, retaining the safety rejection tests and adding this
external-package check. Alternatives are restructuring the HTTP package's
scratch-buffer ownership, or using a compatible compiler for the experiment
temporarily. No safety checks have been disabled and no package files were
patched to suppress the error. The measurements below belong to the earlier
working compiler and have not been repeated on this rebased branch.

The integrated compiler passed 1,261 parse/type checks, 599 native checks,
692 JIT checks and 1,923 rejection checks, plus the other baseline sections.
One command-line path check initially failed because the copied test tree and
the compiler's tree differed; rerunning that check in the matching layout
passed. All three reduced cache APIs also build and run at O0/O1/O2.

## Context

The three posts, oldest first:

- [DHH's Express rewrite announcement](https://x.com/dhh/status/2107077808182976817),
  linking [once-campfire-express](https://github.com/basecamp/once-campfire-express).
- [DHH's invitation to other languages and optimizations](https://x.com/dhh/status/2107078328247267725).
- [Lucas Meijer's Jai result](https://x.com/lucasmeijer/status/2112245228870762770),
  linking [verification PR 11](https://github.com/basecamp/once-campfire-verification/pull/11).

The [verification repository](https://github.com/basecamp/once-campfire-verification)
and [Jai implementation](https://github.com/lucasmeijer/once-campfire-jai) are the
comparison references. The published 3x Rust / 1.8x C / 56x Rails ratios concern
the room-read workload; they are not general application-speed ratios. The
published message-write advantage over Rust is smaller. These are the authors'
measurements, not measurements from this prototype.

## What works

The server listens on loopback with four workers and a SQLite connection per
worker. It implements signed Rails-style session cookies, active-user checks,
Linux bcrypt login, room membership checks, the latest 40 messages and older
windows, FTS search, an open-room sidebar, gzip responses and plain-text posting.
Writes update messages, Action Text, FTS, room counts and membership unread state
in a transaction before acknowledging success. A small browser UI polls for new
messages.

Each worker caches up to 128 pages and 16 MiB of URL/plain/gzip data, with a 1 MiB
limit per entry. Keys contain the authenticated user ID and complete request
target. Buffers are passed directly; entries contain offsets into a fixed byte
array. Invalidation resets counters, so no live array needs to shrink. A full
cache starts a new generation rather than individually evicting pages.

Each cached read opens a SQLite read transaction, checks `PRAGMA data_version`,
then authenticates and reads the page within that snapshot. A change made by any
other connection invalidates the whole worker cache. Local writes invalidate it
both before and after the handler. The most recent verified session is also
cached within that database generation, keyed by the exact signed cookie and
bounded by its expiry. No TTL delays session revocation or room-access changes.
The pinned SQLite implementation executes `OP_Transaction` before reading its
data-version cookie; see `sqlite3.c`'s `PragTyp_HEADER_VALUE` and
`sqlite3BtreeGetMeta`. SQLite documents the version's per-connection scope and
its exclusion of local writes in [PRAGMA data_version](https://www.sqlite.org/pragma.html#pragma_data_version).

The independent Python integration test creates a synthetic database, generates
cookies independently and checks decoded output, denied access, concurrent reads,
32 concurrent acknowledged writes, exact persisted bodies, rollback after an
injected SQL failure, and access revocation after another connection edits the
database. It passes on Windows and Linux; bcrypt login is exercised on Linux.
The same checks run with caching disabled. Cache-specific checks verify actual
hits, identity/gzip equality, cross-user isolation, cookie expiry, revocation,
external content changes, local SQL-trigger changes and entry eviction. A
separate small-buffer test checks byte-capacity eviction and oversized entries.
The HMAC-SHA1 vector test also covers the cookie-signing primitive separately.
Tests use operating-system temporary storage for the database; `--fixture-root`
selects another filesystem. A Linux run on the Windows-mounted `/mnt/c` filesystem
failed some concurrent writes with `SQLITE_BUSY` at the one-second lock timeout.
The server returns an error for those unacknowledged writes. Storage latency and
write contention still need characterization before any performance comparison.

This is not a full Rails replacement: only plain message text is rendered;
rich formatting, attachments and Action Cable/WebSocket delivery are unsupported.
Account administration, uploads, notifications and the wider UI are not
implemented. There is no TLS
configuration or deployment setup. Windows password login returns 501; signed
sessions still work. Browser automation and the official shared benchmark have
not passed or been run to completion. The simpler rendered pages make a timing
comparison misleading until compatibility is completed and verified.

## Dependencies

- [goose-http](https://github.com/kaitk/goose-http) `v0.4.3`: HTTP/event loops.
- [goose-hash](https://github.com/kaitk/goose-hash) `v0.0.4`: SHA, PBKDF2, RNG.
- [goose-compress](https://github.com/kaitk/goose-compress) `v0.1.1`: compression.
- [goose-sqlite](https://github.com/kaitk/goose-sqlite)
  `739fa6af40ecaa48a59d032114e01975c53edd85`: SQLite bindings/amalgamation.

`prepare.py` creates a private SQLite package checkout under `build/` and enables
`SQLITE_ENABLE_FTS5` in its build sidecar. It refuses to overwrite other sidecar
edits. All other packages are fetched by Goose. TLS and REST are not required for
this loopback prototype; PostgreSQL would change the reference application's
SQLite storage model.

Application routing, signing, queries and rendering are Goose. `platform.c` is a
small UTC-clock/libcrypt bcrypt adapter; SQLite, HTTP OS interfaces and hashing
also use the external packages' native components.

## Reference-analysis regression checks

The original issue was reproduced with compiler `8511ae34` at O0/O1/O2 on
Windows and Linux. The three reduced cache APIs require no external package.
With the integrated compiler, they now all build and execute their assertions:

```sh
python3 bench/campfire/repro/check.py /path/to/goose
```

For the historical compiler, add `--expect-limitation`. That mode expects
`field_reference.goose` to produce this diagnostic and executes the two controls:

```text
cannot clear reusable pool unrelated (which cache.bytes may point at):
its slots stay live for the freelist (§5.4)
```

`Cache.bytes` actually points to a separate ordinary local byte array, and there
is no assignment or call that makes it point to `unrelated`. In the server the
unrelated pool is goose-http's `gathered` request-body storage. A helper receiving
`Cache&` lost enough information about the field's referent to admit that pool
as a candidate, so shrinking was rejected. This followed the conservative
read-back-root rules for reference parameters in specification §9.5; it is a
precision limitation, not evidence of an unsafe compiled program or a measured
performance ceiling.

Two reduced controls compile and run with assertions that the local buffer is
cleared and the unrelated pool retains all four bytes:

- `direct_reference.goose` passes `u8[>..]&` directly to the helper.
- `value_holder.goose` passes the small `Cache` holder by value. This copies the
  reference, not the buffer; clearing still affects the caller's byte array.

The reduced examples preserve the original issue and now test its resolution.
The full HTTP callback also produced conservative alias errors with a by-value
holder and with direct parameters to grow-only arrays. The bounded cache uses
fixed buffers and scalar offsets, so it does not depend on improving those cases.

## Reference-analysis approaches

1. **Adapt the cache API to current Goose.** Pass array references directly, or
   pass a small holder of references by value, with mutable scalar metadata
   handled separately. Both reduced forms are verified. This is the smallest
   route back to the server experiment. The full callback needed fixed buffers
   and logical lengths as well; the reduced controls alone did not establish
   that the complete cache could shrink its arrays.
2. **Improve Goose's reference analysis.** Preserve per-field referents through
   aggregate reference parameters and calls. Keep rejecting real aliases to
   reusable pools, including rebinding and aliases introduced in loops. The
   change from `76200a27` was cherry-picked onto `master` as `a17e84d8`, and its
   source branch was deleted. It implements a narrower improvement: a
   referenced holder whose contents share one exact
   root retains that root across calls. The original reduced `Cache&` example
   now runs at O0 and O2. Holders containing several roots remain conservative,
   and the full HTTP callback's Reply/entries alias errors are unchanged. This
   compiler change is included in the rebased server branch, whose bounded
   cache does not require it. Its Linux baseline checks passed, with new
   rejection cases for actual aliases, rebindings,
   callbacks, loops, live references and growth hazards. Windows Defender
   quarantined the new Windows compiler; final compiler validation used Linux,
   without changing security settings.
3. **Use the existing `reusable[]` slice pool for cache storage.** `alloc_slice`,
   `free_slice` and `realloc_slice` already implement run allocation, reuse and
   coalescing. No custom free-list allocator is needed. The application still
   owns cache keys, byte limits, eviction and invalidation. Offsets are optional;
   slices can be kept directly, provided a freed entry is no longer served.

For example, a byte arena could hold page A at `[0, 2000)` and page B at
`[2000, 5000)`. Evicting A records its 2,000 bytes as free; a new 1,200-byte page
can reuse the beginning, leaving an 800-byte free run. This is precisely the
allocation behavior of `reusable[]`. Generation numbers or explicit ownership
prevent stale entries from naming recycled data. Goose keeps a stale slice
memory-safe, but it can observe a later occupant's bytes; cache correctness is
still the application's responsibility. The underlying array retains
its allocation and only grows when no suitable free run remains. A sender that
keeps a reference into the arena must delay recycling until transmission ends;
the current HTTP package copies the response into its output buffer. The bounded
cache here uses the simpler variant: reset the entire arena when full, with no
individual eviction or free-list allocator.

Changing to `reusable[]` would primarily affect cache misses, memory use and
eviction-heavy traffic. It would not itself remove work from the repeated-hit
path measured below.

After resolving the compiler blocker, the next server work is completing
rendering compatibility, then running the common correctness and write audits
before comparing implementations. This includes complete message presentation,
rich text and attachments, real avatars, and the shared fixture's result windows
and persisted-write checks; a simpler page is not an equivalent workload.
Any comparison must use the same fixture, workload, compression, CPU/memory
limits and machine for Goose, Rust and the published Jai binary.
Run both repeated reads and the shared profile with ten writes per second, and
record latency, CPU use and memory alongside validated throughput. Pin all
implementation revisions rather than comparing against figures from another
machine. Only then profile and prioritize changes: per-hit SQLite work, shared
handle-table locking, response copying and cache behavior under writes are
current candidates, not demonstrated bottlenecks. A faster replay path must
still enforce database-generation changes, cookie expiry and permissions.

## Build and test

From the repository root on Linux with Docker:

```sh
docker build -t goose-campfire-toolchain -f bench/campfire/Dockerfile.toolchain bench/campfire
docker run --rm -v "$PWD:/workspace" goose-campfire-toolchain sh bench/campfire/build_linux.sh
```

The script prepares SQLite, builds the compiler and server, then runs the
integration, HMAC and compiler-reproducer checks. Build outputs and downloaded
packages are ignored. Windows users can run these commands in WSL from the
repository's `/mnt/c/...` path.

Native Windows build (Python 3, Git, CMake and a supported C/C++ compiler on PATH):

```powershell
python bench/campfire/prepare.py
cmake -S . -B build/campfire/compiler -DGOOSE_BUILTIN_LIBS=none
cmake --build build/campfire/compiler --config Release --parallel 4
$env:GOOSE_HOME = Join-Path $PWD 'build/campfire/home'
& build/campfire/compiler/Release/goose.exe build -o bench/campfire/build/campfire.exe bench/campfire/campfire.goose
python bench/campfire/test_server.py bench/campfire/build/campfire.exe
python bench/campfire/test_server.py bench/campfire/build/campfire.exe --no-cache
python bench/campfire/repro/check.py build/campfire/compiler/Release/goose.exe
```

To run manually, use a disposable copy of a Campfire SQLite database and set
`DATABASE_PATH` to it, `SECRET_KEY_BASE` to that database's Rails signing secret,
and optionally `PORT` (default 3000). Run the built executable on its target OS.
The program opens an existing database; the integration test creates and cleans
up its own fixture automatically. The prototype writes to whichever database it
is given.

`CAMPFIRE_CACHE=0` disables response and session caching. Set
`CAMPFIRE_CACHE_DIAGNOSTICS=1` for `X-Campfire-Cache: hit/miss` on cached-format
HTML responses; diagnostics are disabled by default and during measurements.

## Cache comparison

`benchmark_cache.py` measures only this prototype against itself. It uses the
shared verification project's Rust HTTP load generator, a synthetic 100-message
room, 16 persistent clients, gzip, disjoint CPU affinity sets, one-second warmups
and alternating cache-off/on rounds. Preflight independently checks message IDs
and exact per-message text against SQL, then every measured response must match
the complete decoded bytes. Raw reports include the executable hash, CPU sets,
latencies and response validation counts and stay under ignored `build/`.

On 2026-10-21, using an AMD Ryzen 9 9950X3D under WSL2, three five-second rounds
produced these results. Server affinity was CPUs 0/2/4/6 and load-generator
affinity 8/10/12/14, using separate cores as reported by the guest topology.

| Mode | Requests/second, three rounds | Median |
| --- | --- | --- |
| Cache disabled | 33,644.5 / 38,673.3 / 40,469.5 | 38,673.3 |
| Cache enabled | 143,356.5 / 150,972.3 / 150,762.1 | 150,762.1 |

The ratio of medians was **3.90x**. All measured responses passed validation,
with zero transport errors or invalid responses. The decoded page was 8,334
bytes and the reported average response size was 1,529 bytes in both modes.
The executable SHA-256 was
`00224d13dca0714fb0b57c99450dc1b6c536c874af76b73130ac222a589c5ee2`.
The local receipt is `build/cache-benchmark.json`. This short repeated-read
measurement does not characterize mixed users, writes, eviction-heavy traffic
or tail latency over a sustained run.

With the verification load generator already built, run inside the Linux
toolchain container:

```sh
python3 bench/campfire/benchmark_cache.py bench/campfire/build/campfire \
  build/campfire/reference/verification/loadgen/target/release/loadgen
```

This is not the shared Campfire fixture or a comparison with Rust/Jai servers.
Do not compare its throughput with published results on other machines or with
more complete rendered pages.
