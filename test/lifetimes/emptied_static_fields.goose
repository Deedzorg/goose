// A slot holding a slice or a reference is emptied by static data too: a
// string literal or a null points into no storage a shrink could free
// (§5.1). A parser filling a view struct through a reference parameter
// empties its fields, or the whole struct with a literal whose fields
// default to those, before it shrinks the buffer the next view is taken
// into, and may be called again and again; a local holder's slots are
// emptied the same way at the top of each iteration.
struct MessageView {
    tag:     const u8[:] = "",
    payload: const u8[:] = "",
    first:   (u8&)?      = null,
}

fn parse_fields<F>(buf: F&, out: MessageView&, data: const u8[:]) {
    out.tag = "";
    out.payload = "";
    out.first .= null;
    buf.clear();
    buf.append(data);
    out.tag = buf[..1];
    out.payload = buf[1..];
    out.first .= buf[0];
}

fn parse_whole<F>(buf: F&, out: MessageView&, data: const u8[:]) {
    out = MessageView {};
    buf.clear();
    buf.append(data);
    out.payload = buf[..];
    out.first .= buf[0];
}

fn show(v: MessageView&) { print(v.tag, " ", v.payload, " ", v.first); }

fn main() {
    var buf: u8[>..] = [];
    var v = MessageView {};
    parse_fields(buf, v, "hello");
    show(v);
    for i in 3 {
        parse_fields(buf, v, "abc");
        parse_whole(buf, v, "xyz");
    }
    show(v);

    // A local holder, its slots emptied one by one, then by a literal.
    var w = MessageView {};
    for i in 2 {
        w.tag = "";
        w.payload = "";
        w.first .= null;
        buf.clear();
        buf.append("pq");
        w.tag = buf[..];
        w.first .= buf[1];
    }
    show(w);
    w = MessageView {};
    buf.clear();
    show(w);
}
