import std;
import os;
import http from "github.com/kaitk/goose-http@v0.4.3";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import compress from "github.com/kaitk/goose-compress@v0.1.1";
import sqlite from "./build/sqlite";
import http.compression;
import auth;
import pages;
import messages;
import checkpoints;
import sessions;
import assets;
import cache;
import avatars;
import signed_id;
import view_data;
import view_types;
import view_assets_generated;

struct Settings {
    database: u8[..1024] = "campfire.sqlite3",
    cookie_key: u8[64] = [0; 64],
    storage_key: u8[64] = [0;64],
    stream_key: u8[64] = [0;64],
    vapid: u8[..256] = [],
    avatar_key: u8[64] = [0; 64],
    storage: u8[..1024] = "storage",
    cache_enabled: bool = true,
    cache_diagnostics: bool = false,
}

var settings = Settings { .. };

extern fn campfire_now(out: u8[>..]&);
extern fn campfire_sql_now(out: u8[>..]&);
extern fn campfire_profile_enable(enabled: bool);

fn authenticate(db: sqlite::Db, req: const http::Request&, key: const u8[:], state: campfire::CacheState&) -> i64 {
    let raw, has_cookie = http::cookie_of(req, "session_token");
    guard has_cookie else { return 0; }
    var now: u8[>..] = [];
    campfire_now(now);
    guard now.len == 24 else { return 0; }
    if state.enabled && state.auth_user > 0 && raw == state.auth_cookie &&
       (state.auth_expiry.len == 0 || compare(now, state.auth_expiry) < 0) { return state.auth_user; }
    var token: u8[>..] = [];
    var valid_until: u8[>..] = [];
    guard campfire::verify_cookie(raw, key, now, token, valid_until) else { return 0; }
    var q = sqlite::Stmt {};
    var user: i64 = 0;
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT u.id FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=? AND u.status=0");
        sqlite::bind_text(q, 1, token);
        if sqlite::step(q) { user = sqlite::column_i64(q, 0); }
    };
    sqlite::finalize(q);
    // Both the session row and the signed-cookie expiry must still be valid.
    if state.enabled && failed.len == 0 && user > 0 {
        state.auth_cookie = raw;
        state.auth_expiry = valid_until;
        state.auth_user = user;
    }
    return if failed.len == 0 { user } else { 0 };
}

fn handle(db: sqlite::Db, writer: const campfire::WriterStatements&, entries: campfire::CachedPage[:], bytes: u8[>..]&, state: campfire::CacheState&,
          req: const http::Request&, body: const u8[:], out: http::Reply) {
    let path = http::path_of(req.target);
    if starts_with(path,"/assets/") && (req.method=="GET" || req.method=="HEAD") {
        let index=campfire::asset_public_index(path); var data: u8[>..]=[];
        if index>=0 && read_file(str("bench/campfire/build/reference-assets/",campfire::asset_filename(index)),data) {
            http::start(out,200); http::field(out,"Cache-Control","public, max-age=31536000, immutable");
            http::field(out,"Content-Type",campfire::asset_mime(index));
            http::finish(out,http::NO_TYPE,data);
        } else { http::respond(out,404,"text/plain","Asset not found"); } return;
    }
    if path == "/up" {
        http::respond(out, 200, "text/html", "<!DOCTYPE html><html><body style=\"background-color: green\"></body></html>");
        return;
    }
    if path == "/session/new" && req.method == "GET" {
        http::respond(out, 200, "text/html; charset=utf-8", "<!DOCTYPE html><html><head><title>Campfire</title></head><body><h1>Sign in to Campfire</h1><form action=\"/session\" method=\"post\"><label>Email <input type=\"email\" name=\"email_address\" required></label><label>Password <input type=\"password\" name=\"password\" required></label><button>Sign in</button></form></body></html>");
        return;
    }
    if path == "/session" && req.method == "POST" {
        campfire::login(db, req, body, settings.cookie_key, out);
        return;
    }
    let user = authenticate(db, req, settings.cookie_key, state);
    if user == 0 {
        http::start(out, 302);
        http::field(out, "Location", "/session/new");
        http::finish(out, http::TEXT, "Authentication required");
        return;
    }
    if path == "/" && req.method == "GET" {
        var q = sqlite::Stmt {};
        var destination: u8[>..] = [];
        let failed = sqlite::run() {
            q = sqlite::prepare(db, "SELECT room_id FROM memberships WHERE user_id=? ORDER BY room_id LIMIT 1");
            sqlite::bind_i64(q, 1, user);
            if sqlite::step(q) { format(destination, "/rooms/", sqlite::column_i64(q, 0)); }
        };
        sqlite::finalize(q);
        if failed.len == 0 && destination.len > 0 {
            http::start(out, 302);
            http::field(out, "Location", destination);
            http::finish(out, http::TEXT, "Redirecting");
        } else { http::respond(out, 404, "text/plain", "No rooms"); }
        return;
    }
    guard req.method == "GET" || req.method == "HEAD" || req.method == "POST" else {
        http::respond(out, 405, "text/plain", "Method not allowed");
        return;
    }
    if req.method == "POST" && !starts_with(path, "/rooms/") {
        http::respond(out, 405, "text/plain", "Method not allowed");
        return;
    }
    if (req.method == "GET" || req.method == "HEAD") && starts_with(path, "/users/") && ends_with(path, "/avatar") {
        var token: u8[>..] = [];
        if http::decode(path[7..path.len - 7], token, false) {
            var now: u8[>..] = [];
            campfire_now(now);
            campfire::avatar(db, req, token, settings.avatar_key, settings.storage, now, out);
        } else { http::respond(out, 404, "text/plain", "Not found"); }
        return;
    }
    if req.method != "POST" && campfire::cached_page(entries, bytes, state, user, req, out) { return; }
    var html: u8[>..] = [];
    var status: i32 = 200;
    var posted = false;
    var view_bytes: u8[>..]=[];
    let failed = sqlite::run() {
        let context_start=campfire::campfire_profile_clock();
        var ctx=campfire::ViewContext { .. };
        if req.method=="POST" { ctx.user=campfire::load_user(db,user,settings.avatar_key,view_bytes); }
        else { ctx=campfire::load_view_context(db,user,settings.avatar_key,settings.stream_key,settings.vapid,req,view_bytes,settings.storage_key); }
        if path == "/users/me/sidebar" {
            campfire::sidebar(db, user, settings.avatar_key, ctx, view_bytes, html);
        } else if path == "/searches" {
            var search: u8[>..] = [];
            let raw, has_query = http::query_of(req.target, "q");
            if has_query && http::decode(raw, search, true) {
                campfire::search(db, user, search, settings.avatar_key, ctx, view_bytes, req, html);
            } else {
                status = 400;
            }
        } else if starts_with(path, "/rooms/") {
            let tail = path[7..];
            let slash = find(tail, "/");
            let number = if slash >= 0 { tail[..slash] } else { tail };
            let room, valid = parse_int(number);
            let messages = slash >= 0 && tail[slash..] == "/messages";
            if valid && room > 0 && (slash < 0 || messages) {
                if req.method == "POST" && messages {
                    var now: u8[>..] = [];
                    campfire_sql_now(now);
                    status = campfire::post_message(db, writer, req, body, user, room, now, settings.avatar_key, ctx, view_bytes, context_start, html);
                    posted = true;
                } else if req.method == "POST" {
                    status = 405;
                } else {
                    let before, has_before = http::query_int(req.target, "before");
                    status = campfire::room(db, user, room, if has_before { before } else { 0 }, messages, settings.avatar_key, ctx, view_bytes, settings.stream_key, html);
                }
            } else {
                status = 404;
            }
        } else {
            status = 404;
        }
    };
    if failed.len > 0 {
        for e in failed { write_stderr(str("database error ", e.code, ": ", e.message, "\n")); }
        http::respond(out, 500, "text/plain", "Database error");
    } else if status != 200 {
        http::respond(out, status, "text/plain", if status == 404 { "Not found" } else { "Bad request" });
    } else {
        if posted {
            http::respond_compressed(out, req, 200, "text/vnd.turbo-stream.html; charset=utf-8", html);
        } else {
            campfire::cache_page(entries, bytes, state, user, req, html, out);
        }
    }
}

fn request(db: sqlite::Db, writer: const campfire::WriterStatements&, version: sqlite::Stmt, entries: campfire::CachedPage[:], bytes: u8[>..]&, state: campfire::CacheState&,
           req: const http::Request&, body: const u8[:], out: http::Reply) {
    if !state.enabled || (req.method != "GET" && req.method != "HEAD") {
        campfire::clear_cache(state);
        handle(db, writer, entries, bytes, state, req, body, out);
        campfire::clear_cache(state);
        return;
    }
    let failed = sqlite::run() {
        sqlite::exec(db, "BEGIN");
        // data_version opens the read snapshot used by authentication and rendering.
        sqlite::reset(version);
        guard sqlite::step(version) else { sqlite::fail(1, "Missing data_version"); }
        let current = sqlite::column_i64(version, 0);
        sqlite::reset(version);
        if current != state.version {
            campfire::clear_cache(state);
            state.version = current;
        }
        handle(db, writer, entries, bytes, state, req, body, out);
    };
    let rollback = sqlite::run() { if sqlite::in_transaction(db) { sqlite::exec(db, "ROLLBACK"); } };
    if rollback.len > 0 {
        // A worker must not serve another request with an unreleased snapshot.
        for e in rollback { write_stderr(str("database rollback failed: ", e.message, "\n")); }
        exit(1);
    }
    if failed.len > 0 {
        campfire::clear_cache(state);
        http::respond(out, 500, "text/plain", "Database error");
    }
}

thread_fn worker(cfg: http::Config) {
    var db = sqlite::Db {};
    var version = sqlite::Stmt {};
    var writer=campfire::WriterStatements { .. };
    let failed = sqlite::run() {
        db = sqlite::open(settings.database, sqlite::READ_WRITE);
        sqlite::busy_timeout(db, 5000);
        sqlite::exec(db, "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA journal_size_limit=67108864; PRAGMA cache_size=2000;");
        version = sqlite::prepare(db, "PRAGMA data_version");
        campfire::prepare_writer(db,writer);
        let wal=campfire::campfire_track_wal(db.id); if wal!=0 { sqlite::fail(wal,"Cannot install WAL observer"); }
    };
    if failed.len > 0 {
        for e in failed { write_stderr(str("database open failed: ", e.message, "\n")); }
        exit(1);
    }
    var entries: campfire::CachedPage[128] = [campfire::CachedPage { .. }; 128];
    var bytes: u8[>..] = [];
    var state = campfire::CacheState { enabled: settings.cache_enabled, diagnostics: settings.cache_diagnostics, .. };
    let e = http::serve(cfg) { req, body, out => request(db, writer, version, entries, bytes, state, req, body, out); };
    campfire::close_writer(writer);
    sqlite::finalize(version);
    sqlite::close(db);
    http::report(e);
}

fn main() {
    var database: u8[>..] = [];
    if env("DATABASE_PATH", database) {
        guard database.len > 0 && database.len <= 1024 else { abort("DATABASE_PATH is too long or empty"); }
        settings.database = database;
    }
    var secret: u8[>..] = [];
    guard env("SECRET_KEY_BASE", secret) && secret.len >= 32 else { abort("set SECRET_KEY_BASE to the database's Rails signing secret"); }
    settings.cookie_key = campfire::signed_cookie_key(secret);
    settings.avatar_key = campfire::signed_id_key(secret);
    hash::pbkdf2_sha256(settings.storage_key, secret, "ActiveStorage", 1000);
    hash::pbkdf2_sha256(settings.stream_key, secret, "turbo/signed_stream_verifier_key", 1000);
    var vapid: u8[>..]=[]; if env("VAPID_PUBLIC_KEY",vapid) { settings.vapid=vapid; }
    var storage: u8[>..] = [];
    if env("STORAGE_PATH", storage) {
        guard storage.len > 0 && storage.len <= 1024 else { abort("STORAGE_PATH is too long or empty"); }
        settings.storage = storage;
    }
    var cache_text: u8[>..] = [];
    if env("CAMPFIRE_CACHE", cache_text) { settings.cache_enabled = cache_text != "0"; }
    var diagnostics: u8[>..] = [];
    if env("CAMPFIRE_CACHE_DIAGNOSTICS", diagnostics) { settings.cache_diagnostics = diagnostics == "1"; }
    var profiling: u8[>..]=[];
    campfire_profile_enable(env("CAMPFIRE_PROFILE_WRITES",profiling) && profiling=="1");
    var cfg = http::Config { address: "127.0.0.1", port: 3000, workers: 4, max_conns: 1024, .. };
    var port_text: u8[>..] = [];
    if env("PORT", port_text) {
        let port, ok = parse_int(port_text);
        guard ok && port > 0 && port < 65536 else { abort("invalid PORT"); }
        cfg.port = port as i32;
    }
    qlimit<campfire::CheckpointJob>(1);
    let checkpointer=thread_spawn(campfire::checkpointer,copy(settings.database));
    http::run(cfg, worker);
    while !qput(campfire::CheckpointJob { stop:true }) { sleep_ms(1); }
    thread_wait(checkpointer);
}
