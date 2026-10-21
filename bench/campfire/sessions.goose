namespace campfire;

import std;
import sqlite;
import http;
import hash;
import auth;
import messages;

extern fn campfire_password_verify(password: const u8[:], digest: const u8[:]) -> i32;
extern fn campfire_expiry(out: u8[>..]&);
extern fn campfire_sql_now(out: u8[>..]&);

fn login(db: sqlite::Db, req: const http::Request&, body: const u8[:], key: const u8[:], out: http::Reply) {
    guard same_origin(req) else { http::respond(out, 422, "text/plain", "Invalid origin"); return; }
    var email: u8[>..] = [];
    var password: u8[>..] = [];
    guard http::form_value(body, "email_address", email) && http::form_value(body, "password", password) && password.len <= 4096 else {
        http::respond(out, 422, "text/plain", "Invalid credentials"); return;
    }
    var q = sqlite::Stmt {};
    var insert = sqlite::Stmt {};
    var token: u8[>..] = [];
    var status: i32 = 422;
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT id,password_digest FROM users WHERE email_address=? AND status=0");
        sqlite::bind_text(q, 1, email);
        if sqlite::step(q) {
            let user = sqlite::column_i64(q, 0);
            var digest: u8[>..] = [];
            sqlite::column_text(q, 1, digest);
            sqlite::reset(q);
            let verified = campfire_password_verify(password, digest);
            if verified < 0 { status = 501; }
            if verified == 1 {
                var random: u8[32] = [0; 32];
                hash::random_bytes(random);
                let digits = "0123456789abcdef";
                for c in random { token.push(digits[c >> 4]); token.push(digits[c & 15]); }
                var now: u8[>..] = [];
                campfire_sql_now(now);
                insert = sqlite::prepare(db, "INSERT INTO sessions(user_id,token,created_at,updated_at,last_active_at) SELECT id,?,?,?,? FROM users WHERE id=? AND password_digest=? AND status=0");
                sqlite::bind_text(insert, 1, token);
                sqlite::bind_text(insert, 2, now);
                sqlite::bind_text(insert, 3, now);
                sqlite::bind_text(insert, 4, now);
                sqlite::bind_i64(insert, 5, user);
                sqlite::bind_text(insert, 6, digest);
                while sqlite::step(insert) {}
                if sqlite::changes(db) == 1 { status = 302; }
            }
        }
    };
    sqlite::finalize(insert);
    sqlite::finalize(q);
    if failed.len > 0 { status = 500; }
    if status == 302 {
        var expiry: u8[>..] = [];
        campfire_expiry(expiry);
        let value = sign_cookie(token, key, expiry);
        http::start(out, 302);
        http::field(out, "Set-Cookie", str("session_token=", value, "; Path=/; HttpOnly; SameSite=Lax; Max-Age=630720000"));
        http::field(out, "Location", "/");
        http::finish(out, http::TEXT, "Signed in");
    } else {
        http::respond(out, status, "text/plain", if status == 501 { "Password login requires the Linux build" } else { "Unable to sign in" });
    }
}
