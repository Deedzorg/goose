// A whole array rendered as text into a fresh string, and its image from
// to_bytes: two values built at a top in one go.
import std;
import os;

fn main() {
    var xs: i64[>..] = [];
    for i in arg_count() * 12000 { xs.push(i * 1000003); }
    let text = str(xs);
    let image = xs.to_bytes();
    print(text.len, " ", image.len);
}
