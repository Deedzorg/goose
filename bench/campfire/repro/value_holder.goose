import std;

reusable[] var unrelated: u8[>..] = [];

struct Cache { bytes: u8[>..]& }

fn clear_cache(cache: Cache) { cache.bytes.clear(); }

fn main() {
    var bytes: u8[>..] = [];
    var cache = Cache { bytes: bytes };
    bytes.append("cache data");
    unrelated.alloc_slice(4);
    clear_cache(cache);
    assert(bytes.len == 0 && unrelated.len == 4);
}
