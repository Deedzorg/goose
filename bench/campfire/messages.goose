namespace campfire;

import std;
import sqlite;
import http;
import pages;
import html;
import emoji;
import view_types;
import view_data;
import view_helpers;
import views_generated;
import checkpoints;

extern fn campfire_disconnected_before(out: u8[>..]&);
extern fn campfire_writer_enter();
extern fn campfire_writer_leave();
extern fn campfire_profile_clock() -> u64;
extern fn campfire_profile_record(times: const u64[:]);

struct WriterStatements {
    q: sqlite::Stmt = sqlite::Stmt {},
    insert: sqlite::Stmt = sqlite::Stmt {},
    rich: sqlite::Stmt = sqlite::Stmt {},
    index: sqlite::Stmt = sqlite::Stmt {},
    touch: sqlite::Stmt = sqlite::Stmt {},
    unread: sqlite::Stmt = sqlite::Stmt {},
    begin: sqlite::Stmt = sqlite::Stmt {},
    commit: sqlite::Stmt = sqlite::Stmt {},
}

fn prepare_writer(db: sqlite::Db, writer: WriterStatements&) {
    writer.q=sqlite::prepare(db,"SELECT r.type,u.name,r.name FROM rooms r JOIN memberships m ON m.room_id=r.id JOIN users u ON u.id=m.user_id WHERE r.id=? AND m.user_id=? AND u.status=0");
    writer.insert=sqlite::prepare(db,"INSERT INTO messages(room_id,creator_id,client_message_id,created_at,updated_at) VALUES(?,?,?,?,?)");
    writer.rich=sqlite::prepare(db,"INSERT INTO action_text_rich_texts(name,record_type,record_id,body,created_at,updated_at) VALUES('body','Message',?,?,?,?)");
    writer.index=sqlite::prepare(db,"INSERT INTO message_search_index(rowid,body) VALUES(?,?)");
    writer.touch=sqlite::prepare(db,"UPDATE rooms SET updated_at=? WHERE id=?");
    writer.unread=sqlite::prepare(db,"UPDATE memberships SET unread_at=?,updated_at=? WHERE room_id=? AND user_id<>? AND involvement<>'invisible' AND (connected_at IS NULL OR connected_at<?)");
    writer.begin=sqlite::prepare(db,"BEGIN IMMEDIATE");
    writer.commit=sqlite::prepare(db,"COMMIT");
}

fn reset_writer(writer: const WriterStatements&) {
    sqlite::reset(writer.q);
    sqlite::reset(writer.insert);
    sqlite::reset(writer.rich);
    sqlite::reset(writer.index);
    sqlite::reset(writer.touch);
    sqlite::reset(writer.unread);
    sqlite::reset(writer.begin);
    sqlite::reset(writer.commit);
}

fn close_writer(writer: const WriterStatements&) {
    sqlite::finalize(writer.q);
    sqlite::finalize(writer.insert);
    sqlite::finalize(writer.rich);
    sqlite::finalize(writer.index);
    sqlite::finalize(writer.touch);
    sqlite::finalize(writer.unread);
    sqlite::finalize(writer.begin);
    sqlite::finalize(writer.commit);
}

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

fn post_message(db: sqlite::Db, writer: const WriterStatements&, req: const http::Request&, body: const u8[:], user: i64,
                room_id: i64, now: const u8[:], key: const u8[:], ctx: ViewContext, bytes: u8[>..]&, context_start: u64, out: u8[>..]&) -> i32 {
    guard same_origin(req) else { return 422; }
    let kind, has_kind = http::field_of(req, "Content-Type");
    guard has_kind && starts_with(kind, "application/x-www-form-urlencoded") else { return 415; }
    var text: u8[>..] = [];
    var client_id: u8[>..] = [];
    guard http::form_value(body, "message[body]", text) && text.len > 0 else { return 422; }
    guard http::form_value(body, "message[client_message_id]", client_id) && client_id.len > 0 && client_id.len <= 256 else { return 422; }
    let q=writer.q;
    let insert=writer.insert;
    let rich=writer.rich;
    let index=writer.index;
    let touch=writer.touch;
    let unread=writer.unread;
    var message_id: i64 = 0;
    var saved_room: u8[>..]=[]; var room_kind: u8[..13]=[];
    var rich_text: u8[>..]=[]; escape(rich_text,text);
    var status: i32 = 404;
    var disconnected_before: u8[>..] = [];
    campfire_disconnected_before(disconnected_before);
    var timing: u64[7]=[0;7]; timing[0]=context_start; timing[1]=campfire_profile_clock();
    campfire_writer_enter();
    timing[2]=campfire_profile_clock();
    let failed = sqlite::run() {
        while sqlite::step(writer.begin) {}
        {

            sqlite::bind_i64(q, 1, room_id);
            sqlite::bind_i64(q, 2, user);
            if sqlite::step(q) {
                let room_type = text_column(q, 0);
                saved_room=text_column(q,2);
                room_kind=if room_type=="Rooms::Open" { "rooms_open" } else if room_type=="Rooms::Closed" { "rooms_closed" } else { "rooms_direct" };

                sqlite::bind_i64(insert, 1, room_id);
                sqlite::bind_i64(insert, 2, user);
                sqlite::bind_text(insert, 3, client_id);
                sqlite::bind_text(insert, 4, now);
                sqlite::bind_text(insert, 5, now);
                while sqlite::step(insert) {}
                message_id = sqlite::last_insert_rowid(db);

                sqlite::bind_i64(rich, 1, message_id);
                sqlite::bind_text(rich, 2, rich_text);
                sqlite::bind_text(rich, 3, now);
                sqlite::bind_text(rich, 4, now);
                while sqlite::step(rich) {}

                sqlite::bind_i64(index, 1, message_id);
                sqlite::bind_text(index, 2, text);
                while sqlite::step(index) {}

                sqlite::bind_text(touch, 1, now);
                sqlite::bind_i64(touch, 2, room_id);
                while sqlite::step(touch) {}

                sqlite::bind_text(unread, 1, now);
                sqlite::bind_text(unread, 2, now);
                sqlite::bind_i64(unread, 3, room_id);
                sqlite::bind_i64(unread, 4, user);
                sqlite::bind_text(unread, 5, disconnected_before);
                while sqlite::step(unread) {}
                status = 200;
            }
        };
        timing[3]=campfire_profile_clock();
        while sqlite::step(writer.commit) {}
        timing[4]=campfire_profile_clock();
    };
    reset_writer(writer);
    if failed.len > 0 {
        let rollback_errors = sqlite::run() { if sqlite::in_transaction(db) { sqlite::exec(db, "ROLLBACK"); } };
    }
    if failed.len==0 && status==200 { checkpoint_after_write(db); }
    campfire_writer_leave();
    timing[5]=campfire_profile_clock();
    for e in failed { sqlite::fail(e.code, e.message); }
    if status==200 {
        var message=MessageView { .. };
        message.id=message_id; message.room_id=room_id; message.room_name=view_keep(bytes,saved_room); message.creator=ctx.user;
        message.dom_id=view_keep(bytes,str("message_",client_id)); message.created_ms=campfire_epoch_ms(now); message.updated_ms=message.created_ms; message.created_iso=view_keep(bytes,time_iso(now));
        message.at_path=view_keep(bytes,str("/rooms/",room_id,"/@",message_id)); message.edit_path=view_keep(bytes,str("/rooms/",room_id,"/messages/",message_id,"/edit"));
        message.boosts_path=view_keep(bytes,str("/messages/",message_id,"/boosts")); message.new_boost_path=view_keep(bytes,str(message.boosts_path,"/new"));
        message.presentation=view_keep(bytes,str("<div class=\"lexxy-content\">\n  ",rich_text,"\n</div>\n")); message.all_emoji=all_emoji(text);
        ctx.room.kind=view_keep(bytes,room_kind);
        render_post_html(out,ctx,message);
        timing[6]=campfire_profile_clock();
        campfire_profile_record([timing[1]-timing[0],timing[2]-timing[1],timing[3]-timing[2],timing[6]-timing[5],timing[4]-timing[3],timing[5]-timing[4]]);
    }
    return status;
}
