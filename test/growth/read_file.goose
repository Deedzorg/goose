// C appending to a builder (the runtime's gs_bld_append): a whole file
// read into a resizable.
import std;
import os;

fn main() {
    var path: u8[>..] = [];
    arg(1, path);
    var data: u8[>..] = [];
    let ok = read_file(path, data);
    print(ok, " ", data.len);
}
