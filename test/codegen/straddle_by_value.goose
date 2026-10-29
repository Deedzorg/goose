// Packed values of 9 to 16 bytes passed by value, whose scalars, references
// and limited arrays' lengths cross an eight-byte boundary. The generated C
// declares such fields with plain C types: with the one-byte-aligned
// aliases, clang's x86-64 calling convention put a 9-byte { u8 tag; i64 v }
// in one register and lost v's last byte, which gcc and MSVC do not. Every
// value's last byte is nonzero, so a lost byte shows. Each function returns
// two values, which keeps it a call at -O2 (the inliner leaves those).
enum Shape { Circle { r: i64 }, Sq { s: i64 } }
struct Tagged { tag: u8, v: i64 }
struct Real { tag: u8, x: f64 }
struct Pair { a: u8, b: u16, c: u32, d: i64 }
struct Pointed { lead: u8, at: i64& }
struct Short { lead: u8[6], name: u8[..4] }
enum Wide { One { v: u8 }, Two { v: u16 } }
struct Late { lead: u8[7], w: Wide }

let BIG: i64 = 0x0102030405060708;

fn radius(s: Shape) -> i64, bool {
    return match s { Circle c => c.r, Sq q => q.s }, true;
}
fn tagged(t: Tagged) -> i64, bool { return t.v, t.tag == 1; }
fn make_tagged(v: i64) -> Tagged, bool { return Tagged { tag: 7, v: v }, true; }
fn real(r: Real) -> f64, bool { return r.x, r.tag == 2; }
fn pair(p: Pair) -> i64, bool { return p.a + p.b + p.c + p.d, true; }
fn pointed(p: Pointed) -> i64, bool { return p.at, p.lead == 3; }
fn short(s: Short) -> i64, bool { return s.name.len, true; }
fn late(l: Late) -> i64, bool {
    return match l.w { One o => o.v, Two t => t.v }, true;
}

fn main() {
    let r1, _ = radius(Shape.Circle { r: BIG });
    let r2, _ = radius(Shape.Sq { s: -BIG });
    print(r1 == BIG, " ", r2 == -BIG);
    let v, ok = tagged(Tagged { tag: 1, v: BIG });
    print(v == BIG, " ", ok);
    let t, _ = make_tagged(BIG);
    print(t.tag, " ", t.v == BIG);
    let x, real_ok = real(Real { tag: 2, x: 1.0e300 });
    print(x, " ", real_ok);
    let sum, _ = pair(Pair { a: 1, b: 2, c: 3, d: BIG });
    print(sum == BIG + 6);
    var target = BIG;
    let at, lead_ok = pointed(Pointed { lead: 3, at: target });
    print(at == BIG, " ", lead_ok);
    var s = Short { lead: [0; 6], name: [] };
    s.name.append("goos");
    let n, _ = short(s);
    print(n);
    let w, _ = late(Late { lead: [0; 7], w: Wide.Two { v: 0x0102 } });
    print(w);
}
