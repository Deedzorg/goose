// Appending a whole array at a time: one copy of a run-time size.
import std;
import os;

fn main() {
    var part: i64[>..] = [];
    part.resize(arg_count() * 5000, 1);
    var all: i64[>..] = [];
    for k in 100 { all.append(part); }
    print(all.len);
}
