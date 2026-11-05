// error: cannot call parse: it shrinks buf while out is still used, and out may refer into buf
// A reference field rebound to null on some paths only still holds, on the
// others, what the caller stored there (§5.1).
struct V { r: (u8&)? = null }
fn parse<F>(buf: F&, out: V&, b: bool) {
    if b { out.r .= null; }
    buf.clear();
    buf.append("x");
    out.r .= buf[0];
}
fn main() {
    var buf: u8[>..] = [];
    var v = V {};
    parse(buf, v, true);
    parse(buf, v, false);
    print(v.r);
}
