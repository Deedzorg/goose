# Campfire in Goose: prototype and compiler limitation

This is a runnable, partial Campfire implementation. Porting and optimization are
stopped at a reproducible Goose reference-analysis limitation, as requested for
this experiment. There is no measured Rust/Jai comparison and no claim of feature
parity or a performance win. The compiler is unchanged.

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

The independent Python integration test creates a synthetic database, generates
cookies independently and checks decoded output, denied access, concurrent reads,
32 concurrent acknowledged writes, exact persisted bodies, rollback after an
injected SQL failure, and access revocation after another connection edits the
database. It passes on Windows and Linux; bcrypt login is exercised on Linux.
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

## Reproduce the limitation

Tested with compiler commit `8511ae34`, at `-O0`, `-O1` and `-O2` on Windows and
Linux. No external package is needed by the reduced examples:

```sh
goose check bench/campfire/repro/field_reference.goose
python3 bench/campfire/repro/check.py /path/to/goose
```

The first command is expected to fail:

```text
cannot clear reusable pool unrelated (which cache.bytes may point at):
its slots stay live for the freelist (§5.4)
```

`Cache.bytes` actually points to a separate ordinary local byte array, and there
is no assignment or call that makes it point to `unrelated`. In the server the
unrelated pool is goose-http's `gathered` request-body storage. A helper receiving
`Cache&` loses enough information about the field's referent to admit that pool
as a candidate, so shrinking is rejected. This follows the conservative
read-back-root rules for reference parameters in specification §9.5; it is a
precision limitation, not evidence of an unsafe compiled program or a measured
performance ceiling.

Two reduced controls compile and run with assertions that the local buffer is
cleared and the unrelated pool retains all four bytes:

- `direct_reference.goose` passes `u8[>..]&` directly to the helper.
- `value_holder.goose` passes the small `Cache` holder by value. This copies the
  reference, not the buffer; clearing still affects the caller's byte array.

The failed caching integration is absent from the runnable server. The reduced
examples preserve the issue without making the prototype fail to build.

## Options before resuming

1. **Adapt the cache API to current Goose.** Pass array references directly, or
   pass a small holder of references by value, with mutable scalar metadata
   handled separately. Both reduced forms are verified. This is the smallest
   route back to the server experiment. The complete cache still needs lifetime,
   eviction and cross-worker invalidation tests; the controls do not prove it.
2. **Improve Goose's reference analysis.** Preserve per-field referents through
   aggregate reference parameters and calls. Keep rejecting real aliases to
   reusable pools, including rebinding and aliases introduced in loops. This
   would allow the original encapsulated cache API, but is compiler work needing
   dedicated positive and negative tests.
3. **Use a reusable pool/offset-based cache.** Recycle allocated runs instead of
   shrinking a referenced grow-only array. This needs explicit ownership,
   eviction and stale-offset handling. It is more invasive than the first option.

The next server work, after choosing an approach, is response caching with
correct invalidation and permission checks, completing rendering compatibility,
then running the common correctness and write audits before measuring throughput.
Any comparison must use the same fixture, workload, compression, CPU/memory
limits and machine for Goose, Rust and the published Jai binary.

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
python bench/campfire/repro/check.py build/campfire/compiler/Release/goose.exe
```

To run manually, use a disposable copy of a Campfire SQLite database and set
`DATABASE_PATH` to it, `SECRET_KEY_BASE` to that database's Rails signing secret,
and optionally `PORT` (default 3000). Run the built executable on its target OS.
The program opens an existing database; the integration test creates and cleans
up its own fixture automatically. The prototype writes to whichever database it
is given.
