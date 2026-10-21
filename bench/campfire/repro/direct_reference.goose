import std;

reusable[] var unrelated: u8[>..] = [];

fn clear_cache(bytes: u8[>..]&) { bytes.clear(); }

fn main() {
    var bytes: u8[>..] = [];
    bytes.append("cache data");
    unrelated.alloc_slice(4);
    clear_cache(bytes);
    assert(bytes.len == 0 && unrelated.len == 4);
}
