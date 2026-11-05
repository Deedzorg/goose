// error: cannot call parse: it shrinks buf while out is still used, and out may refer into buf
// Emptying one slice field with a string literal leaves what the holder's
// other slice field views (§5.1).
struct V { a: const u8[:] = "", b: const u8[:] = "" }
fn parse<F>(buf: F&, out: V&) {
    out.a = "";
    buf.clear();
    buf.append("x");
    out.a = buf[..];
    out.b = buf[..];
}
fn main() {
    var buf: u8[>..] = [];
    var v = V {};
    parse(buf, v);
    parse(buf, v);
    print(v.a, v.b);
}
