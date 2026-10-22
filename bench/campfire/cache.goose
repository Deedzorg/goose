namespace campfire;

import std;
import http;
import http.compression;
import compress;

struct CachedPage {
    user: i64 = 0,
    target_start: i64 = 0,
    plain_start: i64 = 0,
    gzip_start: i64 = 0,
    end: i64 = 0,
}

struct CacheState {
    version: i64 = -1,
    enabled: bool = true,
    diagnostics: bool = false,
    count: i64 = 0,
    used: i64 = 0,
    auth_user: i64 = 0,
    auth_cookie: u8[..8192] = [],
    auth_expiry: u8[..24] = [],
}

fn clear_cache(state: CacheState&) {
    state.count = 0;
    state.used = 0;
    state.auth_user = 0;
}

fn find_page(entries: const CachedPage[:], bytes: const u8[:], state: const CacheState&, user: i64, target: const u8[:]) -> i64 {
    for i in state.count {
        let entry = entries[i];
        if entry.user == user && bytes[entry.target_start..entry.plain_start] == target { return i; }
    }
    return -1;
}

// Offsets remain valid until the worker resets the entire cache generation.
fn store_page(entries: CachedPage[:], bytes: u8[:], state: CacheState&, user: i64,
              target: const u8[:], plain: const u8[:], packed: const u8[:]) {
    let size = target.len + plain.len + packed.len;
    if entries.len == 0 || size > 1024 * 1024 || size > bytes.len || target.len > 2048 { return; }
    if state.count >= entries.len || state.used + size > bytes.len { clear_cache(state); }
    let start = state.used;
    let plain_start = start + target.len;
    let gzip_start = plain_start + plain.len;
    let end = gzip_start + packed.len;
    copy_into(bytes[start..plain_start], target);
    copy_into(bytes[plain_start..gzip_start], plain);
    copy_into(bytes[gzip_start..end], packed);
    entries[state.count] = CachedPage { user: user, target_start: start, plain_start: plain_start,
                                       gzip_start: gzip_start, end: end };
    state.count += 1;
    state.used = end;
}

fn send_page(out: http::Reply, req: const http::Request&, plain: const u8[:], gzip: const u8[:],
             diagnostics: bool, hit: bool) {
    let coding = if out.head || plain.len < 1024 { http::Coding.Identity }
                 else { http::coding_for(req, http::Compression { .. }) };
    if coding == http::Coding.Deflate || coding == http::Coding.Zstd {
        http::respond_compressed(out, req, 200, "text/html; charset=utf-8", plain);
        return;
    }
    http::start(out, 200);
    http::field(out, "Content-Type", "text/html; charset=utf-8");
    http::field(out, "Vary", "Accept-Encoding");
    if diagnostics { http::field(out, "X-Campfire-Cache", if hit { "hit" } else { "miss" }); }
    if coding == http::Coding.Gzip {
        http::field(out, "Content-Encoding", "gzip");
        http::finish(out, http::NO_TYPE, gzip);
    } else {
        http::finish(out, http::NO_TYPE, plain);
    }
}

fn page_cache_key(req: const http::Request&) -> u8[>..] {
    var out: u8[>..]=[]; out.append(req.target);
    for name in ["Host","User-Agent","Turbo-Frame","Cookie"] {
        let value,present=http::field_of(req,name); format(out,"\n",name,":",value.len,":",value);
    } return out;
}

fn cached_page(entries: const CachedPage[:], bytes: const u8[:], state: const CacheState&, user: i64, req: const http::Request&, out: http::Reply) -> bool {
    if !state.enabled { return false; }
    let index = find_page(entries, bytes, state, user, page_cache_key(req));
    if index < 0 { return false; }
    let entry = entries[index];
    send_page(out, req, bytes[entry.plain_start..entry.gzip_start], bytes[entry.gzip_start..entry.end], state.diagnostics, true);
    return true;
}

fn cache_page(entries: CachedPage[:], bytes: u8[:], state: CacheState&,
              user: i64, req: const http::Request&, body: const u8[:], out: http::Reply) {
    if !state.enabled {
        http::respond_compressed(out, req, 200, "text/html; charset=utf-8", body);
        return;
    }
    var packed: u8[>..] = [];
    if body.len >= 1024 {
        var encoder = compress::encoder(compress::GZIP, 1);
        compress::write(encoder, body, packed);
        compress::finish(encoder, packed);
    }
    send_page(out, req, body, packed, state.diagnostics, false);
    store_page(entries, bytes, state, user, page_cache_key(req), body, packed);
}
