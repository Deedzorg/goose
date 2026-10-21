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
import sessions;
import assets;

struct Settings {
    database: u8[..1024] = "campfire.sqlite3",
    cookie_key: u8[64] = [0; 64],
}

var settings = Settings { .. };

extern fn campfire_now(out: u8[>..]&);
extern fn campfire_sql_now(out: u8[>..]&);

fn authenticate(db: sqlite::Db, req: const http::Request&, key: const u8[:]) -> i64 {
    let raw, has_cookie = http::cookie_of(req, "session_token");
    guard has_cookie else { return 0; }
    var now: u8[>..] = [];
    campfire_now(now);
    var token: u8[>..] = [];
    guard campfire::verify_cookie(raw, key, now, token) else { return 0; }
    var q = sqlite::Stmt {};
    var user: i64 = 0;
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT u.id FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=? AND u.status=0");
        sqlite::bind_text(q, 1, token);
        if sqlite::step(q) { user = sqlite::column_i64(q, 0); }
    };
    sqlite::finalize(q);
    return if failed.len == 0 { user } else { 0 };
}

fn handle(db: sqlite::Db, req: const http::Request&, body: const u8[:], out: http::Reply) {
    let path = http::path_of(req.target);
    if path == "/assets/campfire.css" && (req.method == "GET" || req.method == "HEAD") {
        http::respond(out, 200, "text/css", campfire::STYLE);
        return;
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
    let user = authenticate(db, req, settings.cookie_key);
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
    var html: u8[>..] = [];
    var status: i32 = 200;
    var posted = false;
    let failed = sqlite::run() {
        if path == "/users/me/sidebar" {
            campfire::sidebar(db, user, html);
        } else if path == "/searches" {
            var search: u8[>..] = [];
            let raw, has_query = http::query_of(req.target, "q");
            if has_query && http::decode(raw, search, true) {
                campfire::search(db, user, search, html);
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
                    status = campfire::post_message(db, req, body, user, room, now, html);
                    posted = true;
                } else if req.method == "POST" {
                    status = 405;
                } else {
                    let before, has_before = http::query_int(req.target, "before");
                    status = campfire::room(db, user, room, if has_before { before } else { 0 }, messages, html);
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
        http::respond_compressed(out, req, 200,
            if posted { "text/vnd.turbo-stream.html; charset=utf-8" } else { "text/html; charset=utf-8" }, html);
    }
}

thread_fn worker(cfg: http::Config) {
    var db = sqlite::Db {};
    let failed = sqlite::run() {
        db = sqlite::open(settings.database, sqlite::READ_WRITE);
        sqlite::busy_timeout(db, 1000);
    };
    if failed.len > 0 {
        for e in failed { write_stderr(str("database open failed: ", e.message, "\n")); }
        exit(1);
    }
    let e = http::serve(cfg) { req, body, out => handle(db, req, body, out); };
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
    var cfg = http::Config { address: "127.0.0.1", port: 3000, workers: 4, max_conns: 1024, .. };
    var port_text: u8[>..] = [];
    if env("PORT", port_text) {
        let port, ok = parse_int(port_text);
        guard ok && port > 0 && port < 65536 else { abort("invalid PORT"); }
        cfg.port = port as i32;
    }
    http::run(cfg, worker);
}
