// error: cannot call parse: it shrinks buf while out is still used, and out may refer into buf
// A slice that is not static data stored into a slot empties nothing: the
// slot holds a view of whatever the slice points at (§5.1).
struct V { a: const u8[:] = "" }
fn parse<F>(buf: F&, out: V&, other: const u8[:]) {
    out.a = other;
    buf.clear();
    buf.append("x");
    out.a = buf[..];
}
fn main() {
    var buf: u8[>..] = [];
    var src: u8[>..] = [];
    src.append("s");
    var v = V {};
    parse(buf, v, src[..]);
    parse(buf, v, src[..]);
    print(v.a);
}
