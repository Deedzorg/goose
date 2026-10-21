namespace campfire;

import std;
import sqlite;
import assets;

fn escape(out: u8[>..]&, text: const u8[:]) {
    for c in text {
        match c {
            '&' => { out.append("&amp;"); },
            '<' => { out.append("&lt;"); },
            '>' => { out.append("&gt;"); },
            '"' => { out.append("&quot;"); },
            '\'' => { out.append("&#39;"); },
            _ => { out.push(c); },
        }
    }
}

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
        q = sqlite::prepare(db, "SELECT r.id, r.name FROM rooms r JOIN memberships m ON m.room_id=r.id WHERE m.user_id=? AND r.type='Rooms::Open' AND m.involvement<>'invisible' ORDER BY r.name");
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

fn message(q: sqlite::Stmt, out: u8[>..]&) {
    let id = sqlite::column_i64(q, 0);
    out.append("<article id=\"message_");
    escape(out, text_column(q, 1));
    format(out, "\" data-message-id=\"", id, "\"><strong>");
    escape(out, text_column(q, 2));
    out.append("</strong><div class=\"message__body\">");
    escape(out, text_column(q, 3));
    out.append("</div></article>");
}

fn room(db: sqlite::Db, user: i64, room_id: i64, before: i64, fragment: bool, out: u8[>..]&) -> i32 {
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
            out.append("<div id=\"messages_rooms_");
            out.append(if room_type == "Rooms::Open" { "open" } else if room_type == "Rooms::Closed" { "closed" } else { "direct" });
            format(out, "_", room_id, "\">");
            rows = sqlite::prepare(db, "SELECT m.id, m.client_message_id, u.name, idx.body FROM (SELECT * FROM messages WHERE room_id=? AND (?=0 OR created_at < (SELECT created_at FROM messages WHERE id=? AND room_id=?)) ORDER BY created_at DESC LIMIT 40) m JOIN users u ON u.id=m.creator_id LEFT JOIN message_search_index idx ON idx.rowid=m.id ORDER BY m.created_at");
            sqlite::bind_i64(rows, 1, room_id);
            sqlite::bind_i64(rows, 2, before);
            sqlite::bind_i64(rows, 3, before);
            sqlite::bind_i64(rows, 4, room_id);
            while sqlite::step(rows) { message(rows, out); }
            out.append("</div>");
            if !fragment {
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

fn search(db: sqlite::Db, user: i64, query: const u8[:], out: u8[>..]&) {
    var q = sqlite::Stmt {};
    let failed = sqlite::run() {
        q = sqlite::prepare(db, "SELECT m.id,m.client_message_id,u.name,idx.body FROM (SELECT m.* FROM messages m JOIN message_search_index idx ON idx.rowid=m.id JOIN memberships mm ON mm.room_id=m.room_id WHERE mm.user_id=? AND idx.body MATCH ? ORDER BY m.id DESC LIMIT 100) m JOIN users u ON u.id=m.creator_id JOIN message_search_index idx ON idx.rowid=m.id ORDER BY m.id");
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
        while sqlite::step(q) { message(q, out); }
        out.append("</body></html>");
    };
    sqlite::finalize(q);
    for e in failed { sqlite::fail(e.code, e.message); }
}
