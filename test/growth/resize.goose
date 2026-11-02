// One resize of a run-time count: checked before the fill writes anything.
import std;
import os;

fn main() {
    var bytes: u8[>..] = [];
    bytes.resize(arg_count() * 400000, 7);
    print(bytes.len);
}
