namespace campfire;

import std;
import sqlite;
import assets;
import html;
import avatars;

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

fn sidebar(db: sqlite::Db, user: i64, out: u8[>..]&) {
    var q = sqlite::Stmt {};
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT r.id, r.name FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE m.user_id=? AND r.type<>'Rooms::Direct' AND m.involvement<>'invisible' ORDER BY LOWER(r.name)");
        sqlite::bind_i64(q, 1, user);
        page_start(out, "Campfire");
        out.append("<nav id=\"shared_rooms\">");
        while sqlite::step(q) {
            format(out, "<a href=\"/rooms/", sqlite::column_i64(q, 0), "\">");
            escape(out, text_column(q, 1));
            out.append("</a>");
        }
        out.append("</nav></body></html>");
    };
    sqlite::finalize(q);
    for e in failed { sqlite::fail(e.code, e.message); }
}

fn render_message(out: u8[>..]&, id: i64, client_id: const u8[:], creator: i64,
                  name: const u8[:], room_id: i64, room_name: const u8[:],
                  created: const u8[:], updated: const u8[:], rich: const u8[:],
                  plain: const u8[:], key: const u8[:]) {
    out.append("<div class=\"message\" id=\"message_"); escape(out, client_id);
    format(out, "\" data-message-id=\"", id, "\" data-user-id=\"", creator, "\" data-message-timestamp=\"");
    escape(out, created);
    out.append("\" data-message-updated-at=\""); escape(out, updated);
    out.append("\" data-messages-target=\"message\" data-search-results-target=\"message\" data-refresh-room-target=\"message\">");
    out.append("<h2 class=\"message__day-separator\"><time>"); escape(out, created); out.append("</time></h2>");
    out.append("<figure class=\"avatar message__avatar\"><img width=\"48\" height=\"48\" alt=\"");
    escape(out, name); out.append("\" src=\""); escape(out, avatar_path(creator, key)); out.append("\"></figure>");
    out.append("<turbo-frame id=\"edit_message_"); escape(out, client_id);
    out.append("\"><div class=\"message__body\"><div class=\"message__body-content\"><div class=\"message__meta\"><h3 class=\"message__heading\"><strong data-reply-target=\"author\">");
    escape(out, name);
    format(out, "</strong> <a class=\"message__permalink\" href=\"/rooms/", room_id, "/at/", id, "\"><time>");
    escape(out, created); out.append("</time></a> <span class=\"message__room\">"); escape(out, room_name);
    out.append("</span></h3></div><div id=\"presentation_message_"); escape(out, client_id);
    out.append("\" dir=\"auto\" data-reply-target=\"body\" data-messages-target=\"body\">");
    if rich.len > 0 { rich_text(out, rich); } else { escape(out, plain); }
    out.append("</div></div></div></turbo-frame></div>");
}

fn message(q: sqlite::Stmt, key: const u8[:], out: u8[>..]&) {
    render_message(out, sqlite::column_i64(q, 0), text_column(q, 1),
                   sqlite::column_i64(q, 5), text_column(q, 2), sqlite::column_i64(q, 8),
                   text_column(q, 9), text_column(q, 6), text_column(q, 7),
                   text_column(q, 4), text_column(q, 3), key);
}

fn room(db: sqlite::Db, user: i64, room_id: i64, before: i64, fragment: bool, key: const u8[:], out: u8[>..]&) -> i32 {
    var q = sqlite::Stmt {};
    var rows = sqlite::Stmt {};
    var status: i32 = 404;
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT r.name,r.type FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE r.id=? AND m.user_id=?");
        sqlite::bind_i64(q, 1, room_id);
        sqlite::bind_i64(q, 2, user);
        if sqlite::step(q) {
            status = 200;
            if !fragment {
                let name = text_column(q, 0);
                page_start(out, name);
                out.append("<h1>");
                escape(out, name);
                out.append("</h1>");
            }
            let room_type = text_column(q, 1);
            if !fragment {
                out.append("<div id=\"messages_rooms_");
                out.append(if room_type == "Rooms::Open" { "open" } else if room_type == "Rooms::Closed" { "closed" } else { "direct" });
                format(out, "_", room_id, "\">");
            }
            rows = sqlite::prepare(db, "SELECT m.id,m.client_message_id,u.name,idx.body,rt.body,m.creator_id,m.created_at,m.updated_at,m.room_id,r.name FROM (SELECT * FROM messages WHERE room_id=? AND (?=0 OR created_at < (SELECT created_at FROM messages WHERE id=? AND room_id=?)) ORDER BY created_at DESC LIMIT 40) m JOIN users u ON u.id=m.creator_id JOIN rooms r ON r.id=m.room_id LEFT JOIN message_search_index idx ON idx.rowid=m.id LEFT JOIN action_text_rich_texts rt ON rt.record_type='Message' AND rt.name='body' AND rt.record_id=m.id ORDER BY m.created_at");
            sqlite::bind_i64(rows, 1, room_id);
            sqlite::bind_i64(rows, 2, before);
            sqlite::bind_i64(rows, 3, before);
            sqlite::bind_i64(rows, 4, room_id);
            while sqlite::step(rows) { message(rows, key, out); }
            if !fragment {
                out.append("</div>");
                out.append("<form id=\"composer\"><label for=\"message-body\">Message</label><textarea id=\"message-body\" name=\"message[body]\" rows=\"3\" required></textarea><button>Send</button><p id=\"status\" role=\"alert\"></p></form><script>");
                out.append(CHAT_SCRIPT);
                out.append("</script></body></html>");
            }
        }
    };
    sqlite::finalize(rows);
    sqlite::finalize(q);
    for e in failed { sqlite::fail(e.code, e.message); }
    return status;
}

fn search(db: sqlite::Db, user: i64, query: const u8[:], key: const u8[:], out: u8[>..]&) {
    var q = sqlite::Stmt {};
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT m.id,m.client_message_id,u.name,idx.body,rt.body,m.creator_id,m.created_at,m.updated_at,m.room_id,r.name FROM (SELECT m.* FROM messages m JOIN message_search_index idx ON idx.rowid=m.id JOIN memberships mm ON mm.room_id=m.room_id WHERE mm.user_id=? AND idx.body MATCH ? ORDER BY m.id DESC LIMIT 100) m JOIN users u ON u.id=m.creator_id JOIN rooms r ON r.id=m.room_id JOIN message_search_index idx ON idx.rowid=m.id LEFT JOIN action_text_rich_texts rt ON rt.record_type='Message' AND rt.name='body' AND rt.record_id=m.id ORDER BY m.id");
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
        page_start(out, "Search");
        out.append("<h1>Search</h1>");
        while sqlite::step(q) { message(q, key, out); }
        out.append("</body></html>");
    };
    sqlite::finalize(q);
    for e in failed { sqlite::fail(e.code, e.message); }
}
