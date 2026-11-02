// Text written straight at a top: numbers rendered in place, and
// literals appended.
import std;
import os;

fn main() {
    var s: u8[>..] = [];
    for i in arg_count() * 50000 { format(s, i, ", "); }
    print(s.len);
}
