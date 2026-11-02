// Variable-size elements built at the top field by field, and a copy of
// the whole array.
import std;
import os;

struct Rec { name: u8[..], tags: i32[..] }

fn main() {
    var recs: Rec[>..] = [];
    for i in arg_count() * 8000 {
        let k = i as i32;
        recs.push(Rec { "goose", [k, k + 1, k + 2] });
    }
    var again = copy(recs);
    var n = 0;
    for r in again { n += r.tags.len; }
    print(n);
}
