namespace campfire;

import std;
import sqlite;
import assets;
import html;
import avatars;
import http;
import view_types;
import view_data;
import view_helpers;
import views_generated;

fn page_start(out: u8[>..]&, title: const u8[:]) {
    out.append("<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>");
    escape(out, title);
    out.append("</title><link rel=\"stylesheet\" href=\"/assets/campfire.css\"></head><body><nav><a href=\"/users/me/sidebar\">Rooms</a><form action=\"/searches\"><input name=\"q\" aria-label=\"Search messages\" placeholder=\"Search messages\"><button>Search</button></form></nav>");
}

fn text_column(q: sqlite::Stmt, column: i64) -> u8[>..] {
    var text: u8[>..] = [];
    sqlite::column_text(q, column, text);
    return text;
}

fn sidebar(db: sqlite::Db, user: i64, key: const u8[:], ctx: ViewContext, bytes: u8[>..]&, out: u8[>..]&) {
    var q=sqlite::Stmt {}; var members=sqlite::Stmt {}; var placeholders=sqlite::Stmt {};
    var shared: RoomView[>..]=[]; var directs: DirectView[>..]=[]; var people: UserView[>..]=[]; var candidates: UserView[>..]=[];
    let failed=sqlite::run() {
        q=sqlite::prepare(db,"SELECT r.id,r.name,r.type,r.updated_at,m.unread_at FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE m.user_id=? AND m.involvement<>'invisible' ORDER BY CASE WHEN r.type='Rooms::Direct' THEN r.updated_at END DESC,LOWER(r.name)"); sqlite::bind_i64(q,1,user);
        members=sqlite::prepare(db,"SELECT u.id,u.name,u.bio,u.updated_at,u.role FROM users u JOIN memberships m ON m.user_id=u.id WHERE m.room_id=? AND u.id<>?");
        while sqlite::step(q) {
            let room=room_view(q,bytes);
            if room.direct {
                var direct=DirectView { .. }; direct.room_id=room.id; direct.updated_at_epoch=view_keep(bytes,str(room.updated_ms));
                direct.classes=if sqlite::is_null(q,4) { "direct" } else { "direct unread" };
                sqlite::reset(members); sqlite::bind_i64(members,1,room.id); sqlite::bind_i64(members,2,user);
                let start=people.len; while sqlite::step(members) { people.push(user_view(members,0,key,bytes)); }
                if people.len==start { people.push(ctx.user); } direct.members=people[start..];
                var initials: u8[>..]=[];
                for i in direct.members.len {
                    if i>0 { initials.append(if direct.members.len==2 { "+" } else if i==direct.members.len-1 { ", and " } else { ", " }); }
                    var words=0; for word in split(direct.members[i].name," ") { if word.len>0 && words<3 { initials.append(capitalized(word[..1])); words+=1; } }
                }
                direct.initials=view_keep(bytes,initials); directs.push(direct);
            } else {
                room.classes=if sqlite::is_null(q,4) { "align-center gap room btn txt-nowrap" } else { "align-center gap room btn txt-nowrap unread" }; shared.push(room);
            }
        }
        placeholders=sqlite::prepare(db,"WITH excluded AS (SELECT DISTINCT m.user_id FROM memberships m WHERE m.room_id IN (SELECT r.id FROM rooms r JOIN memberships own ON own.room_id=r.id WHERE own.user_id=? AND r.type='Rooms::Direct')) SELECT u.id,u.name,u.bio,u.updated_at,u.role FROM users u WHERE u.status=0 AND u.id<>? AND u.id NOT IN excluded ORDER BY u.created_at LIMIT MAX(0,19-(SELECT COUNT(*) FROM excluded))");
        sqlite::bind_i64(placeholders,1,user); sqlite::bind_i64(placeholders,2,user); while sqlite::step(placeholders) { candidates.push(user_view(placeholders,0,key,bytes)); }
        ctx.other_memberships=shared; ctx.direct_memberships=directs; ctx.placeholders=candidates; render_sidebar_html(out,ctx);
    };
    sqlite::finalize(placeholders); sqlite::finalize(members); sqlite::finalize(q); for e in failed { sqlite::fail(e.code,e.message); }
}

fn room(db: sqlite::Db, user: i64, room_id: i64, before: i64, fragment: bool, key: const u8[:], ctx: ViewContext, bytes: u8[>..]&, stream_key: const u8[:], out: u8[>..]&) -> i32 {
    var q=sqlite::Stmt {}; var rows=sqlite::Stmt {}; var status: i32=404;
    var messages: MessageView[>..]=[]; var boosts: BoostView[>..]=[];
    let failed=sqlite::run() {
        q=sqlite::prepare(db,"SELECT r.id,r.name,r.type,r.updated_at FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE r.id=? AND m.user_id=?");
        sqlite::bind_i64(q,1,room_id); sqlite::bind_i64(q,2,user);
        if sqlite::step(q) {
            status=200; ctx.room=room_view(q,bytes); ctx.body_class="sidebar";
            if ctx.room.direct { let name=direct_room_name(db,room_id,user); ctx.room.display_name=if name.len>0 { view_keep(bytes,name) } else { ctx.user.name }; }
            ctx.title=ctx.room.display_name;
            ctx.messages_stream_name=view_keep(bytes,signed_stream(str(gid_param(view_text(q,2),room_id),":messages"),stream_key));
            rows=sqlite::prepare(db,"SELECT m.id,m.client_message_id,u.name,idx.body,rt.body,m.creator_id,m.created_at,m.updated_at,m.room_id,r.name,r.type FROM (SELECT * FROM messages WHERE room_id=? AND (?=0 OR created_at < (SELECT created_at FROM messages WHERE id=? AND room_id=?)) ORDER BY created_at DESC LIMIT 40) m LEFT JOIN users u ON u.id=m.creator_id JOIN rooms r ON r.id=m.room_id LEFT JOIN message_search_index idx ON idx.rowid=m.id LEFT JOIN action_text_rich_texts rt ON rt.record_type='Message' AND rt.name='body' AND rt.record_id=m.id ORDER BY m.created_at");
            sqlite::bind_i64(rows,1,room_id); sqlite::bind_i64(rows,2,before); sqlite::bind_i64(rows,3,before); sqlite::bind_i64(rows,4,room_id);
            while sqlite::step(rows) { messages.push(message_view(db,rows,key,ctx.storage_key,bytes,boosts)); }
            ctx.messages=messages;
            if fragment { render_messages_html(out,ctx); } else { render_room_html(out,ctx); }
        }
    };
    sqlite::finalize(rows); sqlite::finalize(q); for e in failed { sqlite::fail(e.code,e.message); } return status;
}

fn search(db: sqlite::Db, user: i64, query: const u8[:], key: const u8[:], ctx: ViewContext, bytes: u8[>..]&, req: const http::Request&, out: u8[>..]&) {
    var q = sqlite::Stmt {}; var recent=sqlite::Stmt {}; var last=sqlite::Stmt {};
    var messages: MessageView[>..]=[]; var boosts: BoostView[>..]=[]; var searches: const u8[:][>..]=[];
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT m.id,m.client_message_id,u.name,idx.body,rt.body,m.creator_id,m.created_at,m.updated_at,m.room_id,r.name,r.type FROM (SELECT m.* FROM messages m JOIN message_search_index idx ON idx.rowid=m.id JOIN memberships mm ON mm.room_id=m.room_id WHERE mm.user_id=? AND idx.body MATCH ? ORDER BY m.id DESC LIMIT 100) m LEFT JOIN users u ON u.id=m.creator_id JOIN rooms r ON r.id=m.room_id JOIN message_search_index idx ON idx.rowid=m.id LEFT JOIN action_text_rich_texts rt ON rt.record_type='Message' AND rt.name='body' AND rt.record_id=m.id ORDER BY m.id");
        sqlite::bind_i64(q, 1, user);
        var terms: u8[>..] = [];
        for word in split(query, " ") {
            if word.len == 0 { continue; }
            if terms.len > 0 { terms.push(' '); }
            terms.push('"');
            for c in word { terms.push(c); if c == '"' { terms.push(c); } }
            terms.push('"');
        }
        sqlite::bind_text(q, 2, if terms.len == 0 { "\"\"" } else { terms });
        while sqlite::step(q) { messages.push(message_view(db,q,key,ctx.storage_key,bytes,boosts)); }
        recent=sqlite::prepare(db,"SELECT query FROM searches WHERE user_id=? ORDER BY updated_at DESC"); sqlite::bind_i64(recent,1,user);
        while sqlite::step(recent) { searches.push(view_keep(bytes,view_text(recent,0))); }
        let last_cookie,has_last=http::cookie_of(req,"last_room"); let last_id,valid_last=parse_int(last_cookie);
        last=sqlite::prepare(db,"SELECT r.id FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE m.user_id=? ORDER BY (r.id=?) DESC,r.created_at ASC LIMIT 1"); sqlite::bind_i64(last,1,user); sqlite::bind_i64(last,2,if has_last && valid_last { last_id } else { 0 });
        if sqlite::step(last) { ctx.return_to_room_id=sqlite::column_i64(last,0); }
        ctx.title="Search"; ctx.body_class="sidebar searches"; ctx.has_query=true; ctx.query=query; ctx.q=query; ctx.messages=messages; ctx.recent_searches=searches; render_search_html(out,ctx);
    };
    sqlite::finalize(last); sqlite::finalize(recent); sqlite::finalize(q);
    for e in failed { sqlite::fail(e.code, e.message); }
}
