// Growth past a small stack, element by element: each push is checked
// after it moves the top (test/growth_checks.py).
import std;
import os;

fn main() {
    var xs: i64[>..] = [];
    for i in arg_count() * 100000 { xs.push(i); }
    print(xs.len);
}
