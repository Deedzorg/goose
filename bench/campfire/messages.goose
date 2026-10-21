namespace campfire;

import std;
import sqlite;
import http;
import pages;

fn same_origin(req: const http::Request&) -> bool {
    let site, has_site = http::field_of(req, "Sec-Fetch-Site");
    if has_site && site != "same-origin" && site != "same-site" { return false; }
    let origin, has_origin = http::field_of(req, "Origin");
    if has_origin {
        let host, has_host = http::field_of(req, "Host");
        return has_host && origin == str("http://", host);
    }
    return true;
}

fn post_message(db: sqlite::Db, req: const http::Request&, body: const u8[:], user: i64,
                room_id: i64, now: const u8[:], out: u8[>..]&) -> i32 {
    guard same_origin(req) else { return 422; }
    let kind, has_kind = http::field_of(req, "Content-Type");
    guard has_kind && starts_with(kind, "application/x-www-form-urlencoded") else { return 415; }
    var text: u8[>..] = [];
    var client_id: u8[>..] = [];
    guard http::form_value(body, "message[body]", text) && text.len > 0 else { return 422; }
    guard http::form_value(body, "message[client_message_id]", client_id) && client_id.len > 0 && client_id.len <= 256 else { return 422; }
    var q = sqlite::Stmt {};
    var insert = sqlite::Stmt {};
    var rich = sqlite::Stmt {};
    var index = sqlite::Stmt {};
    var touch = sqlite::Stmt {};
    var unread = sqlite::Stmt {};
    var message_id: i64 = 0;
    var status: i32 = 404;
    let failed = sqlite::run() {
        sqlite::exec(db, "BEGIN IMMEDIATE");
        let transaction_errors = sqlite::transaction(db) {
            q = sqlite::prepare(db, "SELECT r.type,u.name FROM rooms r JOIN memberships m ON m.room_id=r.id JOIN users u ON u.id=m.user_id WHERE r.id=? AND m.user_id=? AND u.status=0");
            sqlite::bind_i64(q, 1, room_id);
            sqlite::bind_i64(q, 2, user);
            if sqlite::step(q) {
                let room_type = text_column(q, 0);
                let name = text_column(q, 1);
                var rich_text: u8[>..] = [];
                rich_text.append("<div>");
                escape(rich_text, text);
                rich_text.append("</div>");
                insert = sqlite::prepare(db, "INSERT INTO messages(room_id,creator_id,client_message_id,created_at,updated_at) VALUES(?,?,?,?,?)");
                sqlite::bind_i64(insert, 1, room_id);
                sqlite::bind_i64(insert, 2, user);
                sqlite::bind_text(insert, 3, client_id);
                sqlite::bind_text(insert, 4, now);
                sqlite::bind_text(insert, 5, now);
                while sqlite::step(insert) {}
                message_id = sqlite::last_insert_rowid(db);
                rich = sqlite::prepare(db, "INSERT INTO action_text_rich_texts(name,record_type,record_id,body,created_at,updated_at) VALUES('body','Message',?,?,?,?)");
                sqlite::bind_i64(rich, 1, message_id);
                sqlite::bind_text(rich, 2, rich_text);
                sqlite::bind_text(rich, 3, now);
                sqlite::bind_text(rich, 4, now);
                while sqlite::step(rich) {}
                index = sqlite::prepare(db, "INSERT INTO message_search_index(rowid,body) VALUES(?,?)");
                sqlite::bind_i64(index, 1, message_id);
                sqlite::bind_text(index, 2, text);
                while sqlite::step(index) {}
                touch = sqlite::prepare(db, "UPDATE rooms SET updated_at=?,messages_count=messages_count+1 WHERE id=?");
                sqlite::bind_text(touch, 1, now);
                sqlite::bind_i64(touch, 2, room_id);
                while sqlite::step(touch) {}
                unread = sqlite::prepare(db, "UPDATE memberships SET unread_at=COALESCE(unread_at,?),updated_at=? WHERE room_id=? AND user_id<>?");
                sqlite::bind_text(unread, 1, now);
                sqlite::bind_text(unread, 2, now);
                sqlite::bind_i64(unread, 3, room_id);
                sqlite::bind_i64(unread, 4, user);
                while sqlite::step(unread) {}
                out.append("<turbo-stream action=\"append\" target=\"messages_rooms_");
                out.append(if room_type == "Rooms::Open" { "open" } else if room_type == "Rooms::Closed" { "closed" } else { "direct" });
                format(out, "_", room_id, "\"><template><article id=\"message_");
                escape(out, client_id);
                format(out, "\" data-message-id=\"", message_id, "\"><strong>");
                escape(out, name);
                out.append("</strong><div class=\"message__body\">");
                escape(out, text);
                out.append("</div></article></template></turbo-stream>");
                status = 200;
            }
        };
        for e in transaction_errors { sqlite::fail(e.code, e.message); }
        sqlite::exec(db, "COMMIT");
    };
    sqlite::finalize(unread);
    sqlite::finalize(touch);
    sqlite::finalize(index);
    sqlite::finalize(rich);
    sqlite::finalize(insert);
    sqlite::finalize(q);
    if failed.len > 0 {
        let rollback_errors = sqlite::run() { if sqlite::in_transaction(db) { sqlite::exec(db, "ROLLBACK"); } };
    }
    for e in failed { sqlite::fail(e.code, e.message); }
    return status;
}
