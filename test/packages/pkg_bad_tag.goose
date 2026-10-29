// C that writes over an enum value's tag (pkg_bad_tag_impl.c): the next
// match on it aborts in every build, rather than taking whichever arm the
// optimizer guessed. Safe Goose cannot make such a tag; only C can.
import std;

enum Shape {
    Circle { r: f64 },
    Square { s: f64 },
    Dot,
}

extern fn bad_tag_scribble(s: Shape&);

fn name(s: Shape) -> u8[:] {
    match s {
        Circle c => "circle",
        Square q => "square",
        Dot => "dot",
    }
}

fn main() {
    var s: Shape = Shape.Square { s: 2.0 };
    print(name(s));
    bad_tag_scribble(s);
    print(name(s));
}
