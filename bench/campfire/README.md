# Campfire in Goose: experimental prototype

This is a partial Campfire implementation on `codex/campfire-experiment`.
The experiment is rebased onto `master` at `d9573d81`, which fixes the
HTTP-package compiler regression. Goose, Rust and the published Jai image now
pass all eight shared HTTP preflight contracts, including decoded avatars and
audited message writes. The current renderer also matches the pinned Rust and
published Jai responses in 27 differential cases each. This establishes parity
for the tested rendered responses, not the complete application.
The files are contained under `bench/campfire` so the experiment can be moved to
its own repository later. It is not on `master`. The active worktree is
`C:\Users\woute\.codex\worktrees\campfire-experiment\goose`; the primary
checkout is free of this experiment.

## Compiler status

Compiler `a17e84d8` rejected goose-http `v0.4.3` at `uring.goose:329`:

```text
cannot call h2_answer: it shrinks h2fields while h is still used,
and h may refer into h2fields (§5.1)
```

The preceding master, `f605b5a0`, typechecked the complete server at O2. The
regression also affected the minimal server in `repro/http_compatibility.goose`,
which contains no Campfire code or cache. Nested helper stores lost the
annotation that a reference came from a holder's contents. A later call then
treated the holder as an arbitrary lifetime bound, admitting unrelated scratch
buffers as possible aliases.

The repair was cherry-picked separately onto `master` as `d9573d81`; its source
branch was deleted and this experiment rebased. It preserves the contents
annotation so call sites can consult actual stores. Dependency-free regressions
cover nested helpers and callbacks; real aliases and loop-carried rebindings
remain rejected. Neither safety checks nor HTTP-package sources were weakened.
This repair does not change the separate dynamic-cache limitations below.

The repaired compiler passed the full Linux baseline: 1,263 parse/type checks,
600 native checks, 693 JIT checks and 1,925 rejection checks, plus all remaining
sections with the usual unavailable-backend/module skips. Both the minimal HTTP
server and complete Campfire server passed O2 checks and native builds. The
build script also checks the minimal HTTP case before building the application.
Local validation receipts are under `build/campfire/compiler-holder-http/` at
the repository root.

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
windows, FTS search, shared and direct-room sidebars, gzip responses and plain-text posting.
Writes update messages, Action Text, FTS, the room timestamp and membership
unread state in a transaction before acknowledging success. Native Goose view
functions render the full pinned reference templates, including layout, editor,
message actions, reactions, user details and media markup.

Message writers enter a process-local FIFO gate before acquiring SQLite's write
lock, waking only the next queued writer. This prevents one worker's continuous transactions from starving other
workers through SQLite's busy-handler retry schedule. External writers still
use SQLite's locking and five-second timeout. The gate is released after commit
or rollback, before rendering the acknowledgement. Each worker reuses eight
prepared write statements and resets all of them on both success and failure.
Connections use WAL, synchronous NORMAL, a 64 MiB journal size
limit and a 2,000-page SQLite cache, matching the reference defaults. NORMAL
preserves committed writes across process crashes but a power failure can lose
writes since the last WAL sync. The pinned
[Rust database](https://github.com/basecamp/once-campfire-rust/blob/6dae2fd3c1a2dce61ca11beb731bcce2b42b67ad/crates/db/src/database.rs)
and [Jai connection](https://github.com/lucasmeijer/once-campfire-jai/blob/e56ba63/src/framework/db/connection.jai)
document these durability settings. A dedicated Goose thread performs PASSIVE
checkpoints after each additional 1,000 WAL pages; at 10,000 pages the writer
requests a RESTART checkpoint, matching the pinned Rust thresholds. A bounded
queue coalesces notifications, and a mutex prevents overlapping checkpoints.
Busy checkpoints can delay WAL reclamation. No durability setting was weakened.

Messages render stored Action Text, attachment metadata, signed Active Storage
URLs, mentions, OpenGraph cards, sound messages and Unicode emoji presentation.
Rich HTML passes through a conservative allowlist. Unknown tags and
attributes are removed, links are restricted, text is escaped and retained tags
are balanced. Signed avatar IDs enforce purpose and expiry; stored square WebP
variants are served with content type, length, ETag and HEAD support. Users
without an image get an initials SVG. Unread timestamps are replaced for
disconnected, visible members other than the author; recent connections and
invisible memberships retain their state.

Each worker caches up to 128 pages and 16 MiB of URL/plain/gzip data, with a 1 MiB
limit per entry. Keys contain the authenticated user ID and complete request
target, Host, User-Agent, Turbo-Frame and Cookie headers. Buffers are passed
directly; entries contain offsets into a grow-only byte array. Storage starts
empty and grows only to the largest occupied prefix, up to the same 16 MiB limit
per worker. Invalidation resets counters and reuses that storage without
shrinking it. A full cache starts a new generation rather than individually
evicting pages. Unused capacity consumes no resident pages; storage already
touched remains available to that worker until it exits.

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
database. Current validation runs on Linux, including bcrypt login.
The same checks run with caching disabled. Cache-specific checks verify actual
hits, identity/gzip equality, cross-user isolation, cookie expiry, revocation,
external content changes, local SQL-trigger changes and entry eviction. A
separate small-buffer test checks byte-capacity eviction and oversized entries.
The HMAC-SHA1 vector test also covers the cookie-signing primitive separately.
Tests use operating-system temporary storage for the database; `--fixture-root`
selects another filesystem. A Linux run on the Windows-mounted `/mnt/c` filesystem
failed some concurrent writes with `SQLITE_BUSY` at the one-second lock timeout.
The server returns an error for those unacknowledged writes. Storage latency and
write contention depend on the filesystem. The shared comparison uses native
WSL temporary storage for all implementations.

This is not a full Rails replacement. Rich formatting supports a subset of HTML.
Attachment markup is rendered, but the blob/representation download routes and
on-demand transformations are not implemented. Action Cable/WebSocket delivery,
message editing/deletion/reactions, account administration, uploads, notifications
and other UI actions remain unimplemented; matching their rendered controls
does not implement those actions.
POST accepts plain text, not the complete rich-text editor protocol. Image
avatars require an existing preprocessed WebP variant and return 501 if it is
missing; on-demand image transformation is not implemented. Bot fallback SVGs
are simpler than Rails'. There is no TLS configuration or deployment setup.
Windows password login returns 501; signed sessions still work. Full browser/UI
behavior parity has not been established. Shared HTTP validation supports a scoped
workload comparison, not a claim that these applications do equivalent work
outside those contracts or that a measured difference comes from the language.

## Shared Rails fixture checks

The prototype now runs against a real shared fixture generated by the unmodified
verification `bin/seed`, using Rails revision
`90b330024dec3e757c79b6a7e6568f93da8e3148` and verification revision
`ec02debb3e44f40b8778a6a42db3c4515b2f9eaf`. The local reference image is
`goose-campfire-reference:90b3300`. Its exported Dockerfile uses an equivalent
root-owned `COPY` plus `chmod` for hooks because the local legacy builder lacks
`COPY --chmod`; application and seed code were unchanged. Seed files and
disposable credentials remain in ignored build storage.

`test_shared.py` opens the source database read-only and uses SQLite backup to
make a disposable copy in native temporary storage. With caching enabled and
disabled, it passes bcrypt login, exact SQL-derived room/pagination/search
windows and plain text, sidebar visibility, denied room access, 32 concurrent
writes with exact message/Action Text/FTS rows, room timestamp updates, rollback
after an injected database failure, and access revocation after foreign commits.
They also check retained rich text, exact stored avatar bytes and actual image
decoding, independently signed current/legacy avatar IDs, invalid signatures,
purpose and expiry, initials, HEAD and ETag. Another write checks disconnected,
recently connected, invisible and author membership timestamps independently.
The real schema has no `rooms.messages_count` column; both fixture tests use
that schema for the write path.

Inside the Linux toolchain container, using an existing seed:

```sh
python3 bench/campfire/test_shared.py bench/campfire/build/campfire \
  build/campfire/reference/shared-seed
python3 bench/campfire/test_shared.py bench/campfire/build/campfire \
  build/campfire/reference/shared-seed --no-cache
```

These are checks of the implemented protocol and database behavior, not full
Campfire parity. Adding `--loadgen /path/to/loadgen` also runs the shared
verification project's unmodified room validator with SQL-derived expected
identities and content. The full preflight in `benchmark_shared.py` passes all
eight routes for all three servers: room, pagination, sidebar, search, avatar,
CSS, health and POST. It uses unmodified `contracts.rb`, the shared load
generator's route validator and `validate_acks.rb`. No exact-body override
replaces the message contracts. Avatar preflight uses the verification
project's real image decoder. Every acknowledged write is audited against SQL.
Logs are under the repository-root `build/campfire/` directory as
`shared-final-on.log`, `shared-final-off.log` and `shared-preflight-3.log`;
the complete preflight receipt is `bench/campfire/build/shared-preflight-3/`.

## Dependencies

- [goose-http](https://github.com/kaitk/goose-http) `v0.4.3`: HTTP/event loops.
- [goose-hash](https://github.com/kaitk/goose-hash) `v0.0.4`: SHA, PBKDF2, RNG.
- [goose-compress](https://github.com/kaitk/goose-compress) `v0.1.1`: compression.
- [goose-sqlite](https://github.com/kaitk/goose-sqlite)
  `739fa6af40ecaa48a59d032114e01975c53edd85`: SQLite bindings/amalgamation.

`prepare.py` creates a private SQLite package checkout under `build/`, enables
`SQLITE_ENABLE_FTS5` and appends `sqlite_wal.c` to the package shim. That adapter
installs SQLite's WAL hook using the package's validated connection handle and
records the committed frame count; checkpoint policy remains Goose code. The
preparer refuses to overwrite other sidecar or shim edits. All other packages
are fetched by Goose. TLS and REST are not required for
this loopback prototype; PostgreSQL would change the reference application's
SQLite storage model.

Application routing, signing, queries and rendering are Goose. `platform.c` is a
UTC-clock/libcrypt bcrypt, native writer/checkpoint synchronization and optional
write-timing adapter;
SQLite, HTTP OS interfaces and hashing
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
holder and with direct parameters to arrays that could shrink. The original
bounded cache used fixed buffers and scalar offsets. The current cache keeps
offsets but grows storage with push operations and never shrinks the underlying
array, including at generation changes. This compiles with the same d9573d81
compiler; a general resize call is unsuitable because it admits shrinking.

## Reference-analysis approaches

1. **Adapt the cache API to current Goose.** Pass array references directly, or
   pass a small holder of references by value, with mutable scalar metadata
   handled separately. Both reduced forms are verified. This is the smallest
   route back to the server experiment. The initial full callback used fixed
   buffers and logical lengths; it now uses a grow-only buffer with those same
   logical lengths. The reduced controls do not establish that the complete
   cache could shrink its arrays.
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

The shared HTTP contracts now pass. A faster cached path must still enforce
database-generation changes, cookie expiry and permissions. Remaining browser
actions and attachment serving are separate from the validated HTTP workload.

## Rendering parity and write profiles, 2026-10-22

`views/templates/` contains 26 unmodified MIT-licensed templates from Rust
`6dae2fd3c1a2dce61ca11beb731bcce2b42b67ad`. `views/source.json` records their
hashes. `compile_views.py` verifies those hashes and compiles the supported
Askama subset into eight native Goose functions; unsupported expressions fail
the build. Database presenters, helpers, rich HTML and attachment rendering are
implemented in Goose. No rendered response is replayed from a reference capture.

The frontend manifest records 315 immutable assets from the pinned image.
`prepare_assets.py` provisions them into ignored build storage and verifies every
hash. `compile_assets.py` generates asset lookup functions and static layout tags.
The server serves only paths in this manifest.

`test_rendering.py` compares parsed HTML structure, attributes and text, preserving
whitespace in preformatted/script/style content. It normalizes attribute order,
ordinary whitespace, the server's base URL and POST-generated timestamps. The
27 cases cover cold/warm room, pagination, search and sidebar responses, direct
and empty rooms, rich content, attachments, missing authors, mentions, sounds,
Host and Chrome variants, foreign database edits without timestamp changes,
and plain-text/emoji/Japanese POST markup. It also verifies the content hash and
MIME type of all 315 assets served by Goose.

The optimized binary passed all 27 comparisons against each reference, with
Goose caching disabled for Rust and enabled for Jai. Receipts are
`bench/campfire/build/parity-final-rust/result.json` and
`bench/campfire/build/parity-final-jai/result.json`; these use the exact binary
measured below. Synthetic and shared fixture
tests also passed with caching enabled and disabled, including concurrent writes,
rollback and subsequent writes, revocation and unread membership semantics.

Two audited 10-second POST rounds at each stage gave these instrumented medians:

| Write implementation | Requests/s | Mean SQL, microseconds | Mean commit, microseconds |
| --- | ---: | ---: | ---: |
| Full rendering, original writer | 2,865 | 174.81 | 73.12 |
| Reused statements, render after commit, smaller context | 3,691 | 107.46 | 67.16 |
| Background WAL checkpoints and wake-one FIFO | 8,241 | 59.50 | 21.89 |

Receipts are `write-profile-before-2`, `write-profile-after` and
`write-profile-wal` under `bench/campfire/build`. Set
`CAMPFIRE_PROFILE_WRITES=1`, or pass `--profile-writes` to the shared benchmark,
to aggregate context/wait/SQL/render/commit/cleanup durations every 1,024 writes
per worker. These measurements include instrumentation and do not isolate each
change within a stage. The completed three-way comparison below disables profiling.

## Demand-grown cache storage, 2026-10-22

The per-worker cache is now a grow-only array with logical offsets, retaining
its original 128-entry, 16 MiB and 1 MiB-per-entry limits. No page content,
compression policy, authentication, invalidation rule, SQLite setting or worker
count was changed. Cache-off requests leave this buffer empty.

The previous fixed-array initializer produced both a 16 MiB value and a 16 MiB
initialization temporary on each worker's data stacks. Those touched pages
remained resident after initialization. Four workers therefore touched roughly
128 MiB just for these arrays, with additional page-granularity overhead.
Appending cache storage on demand removes that initialization and keeps only
storage actually used. The application uses existing Goose features; no compiler
or package change is involved.

`profile_memory.py` compares process mappings and cgroup memory after login,
after 64 room requests, and after 64 passes over all four read routes. On the
shared fixture it measured anonymous process memory as follows:

| Phase | Previous cache, MiB | Demand-grown cache, MiB |
| --- | ---: | ---: |
| After login | 138.28 | 2.33 |
| After room reads | 149.92 | 15.70 |
| After all read routes | 150.74 | 18.84 |

These are retained-memory probes, not throughput measurements. Receipts are
`bench/campfire/build/memory-before/memory.json` and
`bench/campfire/build/memory-lazy/memory.json`, with executable hashes and mapping
breakdowns. A cache that fills its full capacity can still retain 64 MiB across
four workers; this change preserves capacity instead of choosing a smaller
fixture-specific cache.

Cache unit checks cover growth, retained contents, identity separation,
byte/entry eviction, oversized-entry rejection and reuse after invalidation.
Synthetic and shared fixture integrations pass with caching on and off.
`parity-memory-rust` and `parity-memory-jai` under `bench/campfire/build` each
contain 27 passing differential rendering checks and all 315 static-asset checks,
with caching enabled for Rust and disabled for Jai.

## Build and test

From the repository root on Linux with Docker:

```sh
docker build -t goose-campfire-toolchain -f bench/campfire/Dockerfile.toolchain bench/campfire
mkdir -p /tmp/goose-campfire-comparison
docker run --rm --network host \
  -v "$PWD:$PWD" -v /tmp/goose-campfire-comparison:/tmp/goose-campfire-comparison \
  -v /usr/bin/docker:/usr/local/bin/docker:ro \
  -v /var/run/docker.sock:/var/run/docker.sock --workdir "$PWD" \
  goose-campfire-toolchain python3 bench/campfire/prepare_assets.py \
  --seed build/campfire/reference/shared-seed --runtime-root /tmp/goose-campfire-comparison
docker run --rm -v "$PWD:/workspace" goose-campfire-toolchain sh bench/campfire/build_linux.sh
```

Asset provisioning requires the shared seed and pinned Rust image described
above. The script prepares SQLite and generates the native views/assets, builds the compiler, checks the HTTP-package
reproducer, builds the server, then runs the integration, HMAC, rich-text
sanitizer and reduced cache-API checks. Build outputs and downloaded packages are ignored. Windows
users can run these commands in WSL from the
repository's `/mnt/c/...` path.

Native Windows build (Python 3, Git, CMake and a supported C/C++ compiler on PATH):

```powershell
python bench/campfire/prepare.py
python bench/campfire/compile_views.py
python bench/campfire/compile_assets.py
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
`STORAGE_PATH` to its Active Storage files, and optionally `PORT` (default 3000).
Run the built executable on its target OS.
The program opens an existing database; the integration test creates and cleans
up its own fixture automatically. The prototype writes to whichever database it
is given.

`CAMPFIRE_CACHE=0` disables response and session caching. Set
`CAMPFIRE_CACHE_DIAGNOSTICS=1` for `X-Campfire-Cache: hit/miss` on cached-format
HTML responses; diagnostics are disabled by default and during measurements.

## Shared comparison

`benchmark_shared.py` runs all implementations on the same machine, with fresh
copies of the same Rails seed, gzip, four server cores, four separate generator
cores and a 2 GiB container limit. Three rounds rotate server order. Each route
gets a two-second warmup followed by eight seconds at 16 persistent clients.
The baseline measures room, pagination, sidebar, search and POST. The mixed
profile reads a room while the shared writer posts ten messages per second in
another room. Source/image/executable hashes, payload sizes, raw latencies,
generator CPU and write audits are retained. Server CPU/memory are recorded
when the container exposes supported cgroup counters.

Any transport error, invalid response, missing/duplicate write, failed SQL
audit or changed source seed fails the entire run. Only a report with
`metadata.complete: true` is accepted. The runner never modifies the shared
verification sources. It requires the Linux repository and runtime directory
to have the same absolute paths in the runner and Docker host. For this machine:

```sh
mkdir -p /tmp/goose-campfire-comparison
docker run --rm --network host \
  -v /mnt/c/Users/woute/.codex/worktrees/campfire-experiment/goose:/mnt/c/Users/woute/.codex/worktrees/campfire-experiment/goose \
  -v /mnt/c/W/goose/.git:/mnt/c/W/goose/.git:ro \
  -v /tmp/goose-campfire-comparison:/tmp/goose-campfire-comparison \
  -v /usr/bin/docker:/usr/local/bin/docker:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --workdir /mnt/c/Users/woute/.codex/worktrees/campfire-experiment/goose goose-campfire-toolchain:latest \
  python3 bench/campfire/benchmark_shared.py \
  --verification build/campfire/reference/verification \
  --seed build/campfire/reference/shared-seed \
  --runtime-root /tmp/goose-campfire-comparison \
  --output bench/campfire/build/shared-comparison-new
```

Add `--preflight-only` for validation without timing. Use a new output directory
for every run. Windows-managed worktrees also need the main repository Git
directory mounted at its WSL path, as above, so revision and cleanliness checks
can follow the worktree pointer. Published defaults are Rust `main` (resolved to an immutable
image before starting) and Jai `e56ba63`, the image linked by its README;
unpublished Jai changes are outside this comparison.

### Historical results before demand-grown storage, 2026-10-22

The completed receipt is `bench/campfire/build/shared-render-parity-1/summary.json`,
from clean revision `8d3da3fb2d9fcc22ec31625da40d83c318cf3670`, executable SHA-256
`e8e8618bbbd66384afca87370a7bb4e5f253d516158f2e0f883c8e3ef924b7d9`.
The log is `build/campfire/shared-render-parity-1.log` in this worktree.
The compiler remains `d9573d81`; no compiler change was needed for this work.

The same AMD Ryzen 9 9950X3D / WSL2 machine, native WSL SQLite storage, four server
cores (0/2/4/6), separate generator cores (8/10/12/14), 2 GiB container limit,
gzip and 16 persistent clients were used for all implementations. Each of three
rotating rounds used a two-second warmup and eight-second sample. No builds or
other tests from this task ran concurrently. Profiling was disabled. References
were pinned by immutable image ID:

- Rust `6dae2fd3c1a2dce61ca11beb731bcce2b42b67ad`,
  `sha256:98ba156f688c3fe856afd71655f613a6620bc03754f456ed2ef08fb2e5527e6e`.
- Published Jai `e56ba63`,
  `sha256:014651a89f16953fab46cc3f322019d932d37ff1a098d98fb71bdf2e976caf92`.

All **54 timed samples** passed. Including preflights and warmups, **35,026,917
responses** were validated with **zero transport errors or invalid responses**.
The shared SQL audit verified **540,060 acknowledged writes**: 261,262 Goose,
120,550 Rust and 158,248 Jai. All 18 disposable databases passed row-count, FTS,
Action Text and SQLite integrity checks. The source seed and executable hashes
were unchanged. Each eight-second mixed sample acknowledged 79 writes at its
configured ten-posts/s rate.

Median valid requests per second:

| Workload | Goose | Rust | Jai |
| --- | ---: | ---: | ---: |
| Room | 166,343 | 29,446 | 72,269 |
| Older messages | 170,286 | 28,582 | 74,004 |
| Sidebar | 179,281 | 31,021 | 76,046 |
| Search | 171,635 | 31,415 | 75,543 |
| POST message | 8,599 | 4,215 | 5,301 |
| Room with ten posts/s in another room | 163,171 | 28,039 | 71,075 |

Goose's room-read ratios are **5.65x Rust / 2.30x Jai**; write ratios are
**2.04x / 1.62x**; mixed-room ratios are **5.82x / 2.30x**. Goose room rounds were
148,366 / 168,836 / 166,343 requests/s, and write rounds were
8,621 / 8,525 / 8,599. These short measurements have visible variation and do not
establish maximum capacity or sustained production performance.

Median per-run latency and sampled resources:

| Metric | Goose | Rust | Jai |
| --- | ---: | ---: | ---: |
| Room p99, ms | 0.242 | 1.143 | 0.463 |
| POST p99, ms | 7.291 | 8.823 | 7.555 |
| Mixed room p99, ms | 0.247 | 1.355 | 0.485 |
| Server CPU cores used, room | 2.05 | 3.32 | 2.76 |
| Server CPU cores used, POST | 1.75 | 2.90 | 2.31 |
| Anonymous resident MiB after room | 150.5 | 22.1 | 44.9 |
| Anonymous resident MiB after POST | 154.2 | 91.9 | 108.3 |

Memory is an anonymous-resident cgroup sample after a route, not peak or total
resident memory. Goose uses more memory, including its fixed 64 MiB response
cache. Generator CPU for room reads was 3.25 / 1.14 / 1.87 cores respectively;
this comparison includes each application's response and caching strategies.

The first-round room responses were 416,155 / 416,121 / 416,121 decoded bytes
and about 28.5 / 24.2 / 20.6 KB compressed. Goose now emits equivalent tested
markup and content; remaining byte differences include ordinary whitespace,
base URLs and compression choices. The separate differential tests above check
structure, attributes and text beyond the shared benchmark contracts. They also
exercise cache invalidation after foreign content edits without timestamp changes.

This is a lead for these validated workloads and pinned implementations. It is
not evidence that Goose is intrinsically faster as a language or that the full
applications are equivalent: the unimplemented browser actions and attachment
serving listed above remain outside this comparison. The experiment remains on
`codex/campfire-experiment` in its own worktree, with nothing landed on master.

### Historical results before rendering parity, 2026-10-21

The completed receipt is `bench/campfire/build/shared-comparison-2/summary.json`.
It records a clean Goose revision `f8d28251bf1a47e63287afbf2764505d9bf49855`,
unmodified verification revision `ec02debb3e44f40b8778a6a42db3c4515b2f9eaf`,
and executable SHA-256
`31dbad741231eebc24458bcb1dd245eb257db96e4bcc68200d84ce993b4f9056`.
Rust was revision `6dae2fd3c1a2dce61ca11beb731bcce2b42b67ad`, image
`sha256:98ba156f688c3fe856afd71655f613a6620bc03754f456ed2ef08fb2e5527e6e`.
Jai was published tag `e56ba63`, image
`sha256:014651a89f16953fab46cc3f322019d932d37ff1a098d98fb71bdf2e976caf92`.
Fixture, generator, validator and toolchain image hashes are in the receipt.

The machine was an AMD Ryzen 9 9950X3D under WSL2 Ubuntu. Each server used
CPUs 0/2/4/6 and the generator used 8/10/12/14, separate cores according to the
guest topology. All used native WSL database storage, host networking, gzip,
the same 2 GiB limit and the settings above. The runner measured one server at
a time; this task ran no builds during the measurements.

All 54 timed samples passed. Including warmups and preflights, the generator
validated **33,261,762 responses** with zero transport errors or invalid
responses. The shared audit verified **360,912 acknowledged writes**: 94,852
Goose, 111,214 Rust and 154,846 Jai. Each of the 18 disposable databases passed
additional row-count, FTS, Action Text and SQLite integrity checks. The source
seed and executable were unchanged. The mixed writer targeted ten posts/s and
acknowledged 79 posts in each eight-second timed sample.

Median valid requests per second across three rounds:

| Workload | Goose | Rust | Jai |
| --- | ---: | ---: | ---: |
| Room | 160,361 | 28,169 | 67,471 |
| Older messages | 166,429 | 27,720 | 68,780 |
| Sidebar | 166,741 | 29,285 | 70,561 |
| Search | 160,512 | 29,368 | 70,150 |
| POST message | 2,992 | 3,848 | 5,102 |
| Room with ten posts/s in another room | 162,413 | 26,254 | 66,622 |

The room ratio is 5.69x Rust and 2.38x Jai; mixed-room ratios are 6.19x and
2.44x. Goose's write rate is only 0.78x Rust and 0.59x Jai. Room rates in order
of each application's rounds were Goose 168,545 / 160,361 / 146,750; Rust
28,169 / 28,496 / 27,917; Jai 70,537 / 67,471 / 63,591. These short runs have
visible variation; the mixed result being slightly higher than baseline for
Goose is not evidence that adding writes makes it faster.

Median per-run latency and sampled resource use:

| Metric | Goose | Rust | Jai |
| --- | ---: | ---: | ---: |
| Room p99, ms | 0.242 | 1.179 | 0.489 |
| POST p99, ms | 9.471 | 9.239 | 7.879 |
| Mixed room p99, ms | 0.251 | 1.440 | 0.536 |
| Server CPU cores used, room | 1.95 | 3.32 | 2.82 |
| Anonymous resident MiB after room | 147.3 | 22.1 | 43.2 |
| Anonymous resident MiB after POST | 150.5 | 91.7 | 107.7 |

Memory is a cgroup sample after the route, not peak or total resident memory;
CPU is the cgroup counter delta around the sample. Generator CPU for room reads
was about 3.15 / 1.15 / 1.91 cores respectively. These are measurements at
16 clients, not proven maximum capacity or a sustained production-load result.

**This establishes a lead on the contract-tested reads, not equivalent full
applications or an intrinsic language advantage.** The rendered room was
51,038 decoded bytes for Goose versus 416,121 for both other servers. Compressed
body sizes were 6,019 / 24,230 / 20,630 bytes respectively. Sidebar and search
also omit much of the complete UI. The shared contracts validate message
windows, text, structure and route behavior, not every action or UI element.
Goose's missing features listed above and greater memory use remain material.

The first comparison attempt failed closed on one Goose SQLite lock timeout
during sustained POST and is excluded. The FIFO gate then passed two separate
20-second write stress rounds. After aligning SQLite settings, the complete
comparison above passed; regression tests also verify a successful write after
an injected transaction failure. Local logs are `build/campfire/writer-final-tests.log`
and `build/campfire/shared-comparison-2.log` at the repository root. Raw data and
audit bodies stay ignored.

The rendering and write work described above supersedes this implementation.
These historical throughput figures involve unequal rendered work and must not
be used as the current performance comparison. No new compiler blocker was encountered.

## Historical cache comparison

`benchmark_cache.py` measures only this prototype against itself. It uses the
shared verification project's Rust HTTP load generator, a synthetic 100-message
room, 16 persistent clients, gzip, disjoint CPU affinity sets, one-second warmups
and alternating cache-off/on rounds. Preflight independently checks message IDs
and exact per-message text against SQL, then every measured response must match
the complete decoded bytes. Raw reports include the executable hash, CPU sets,
latencies and response validation counts and stay under ignored `build/`.

Before the shared rendering/avatar work, on 2026-10-21, with compiler
`d9573d81` on an AMD Ryzen 9 9950X3D under WSL2,
three five-second rounds produced these results. Server affinity was CPUs
0/2/4/6 and load-generator affinity 8/10/12/14, using separate cores as reported
by the guest topology.

| Mode | Requests/second, three rounds | Median |
| --- | --- | --- |
| Cache disabled | 41,061.5 / 40,600.5 / 32,031.6 | 40,600.5 |
| Cache enabled | 165,022.6 / 158,125.7 / 161,423.5 | 161,423.5 |

The ratio of medians was **3.98x**. All measured responses passed validation,
with zero transport errors or invalid responses. The decoded page was 8,334
bytes and the reported average response size was 1,529 bytes in both modes.
The executable SHA-256 was
`6d009c6b23869a3b6f315dad3f9cfc39e949bdcd68322ef7da32814135312ce8`.
The local receipt is `build/cache-benchmark-landed.json`. The previous build
with compiler `8511ae34` measured a 3.90x cache ratio; the new run does not
isolate a compiler-speed effect. This short repeated-read
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
