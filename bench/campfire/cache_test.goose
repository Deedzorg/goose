import std;
import http from "github.com/kaitk/goose-http@v0.4.3";
import compress from "github.com/kaitk/goose-compress@v0.1.1";
import cache;

fn main() {
    var entries: campfire::CachedPage[2] = [campfire::CachedPage { .. }; 2];
    var bytes: u8[48] = [0; 48];
    var state = campfire::CacheState { .. };
    campfire::store_page(entries, bytes, state, 1, "/a", "first", "zip1");
    campfire::store_page(entries, bytes, state, 2, "/a", "second", "zip2");
    assert(campfire::find_page(entries, bytes, state, 1, "/a") == 0);
    assert(campfire::find_page(entries, bytes, state, 2, "/a") == 1);
    assert(campfire::find_page(entries, bytes, state, 3, "/a") == -1);
    assert(campfire::find_page(entries, bytes, state, 1, "/a?b") == -1);
    campfire::store_page(entries, bytes, state, 1, "/b", "replacement", "zip3");
    assert(state.count == 1 && state.used == 17);
    assert(campfire::find_page(entries, bytes, state, 1, "/a") == -1);
    let entry = entries[0];
    assert(bytes[entry.plain_start..entry.gzip_start] == "replacement");
    assert(bytes[entry.gzip_start..entry.end] == "zip3");
    campfire::store_page(entries, bytes, state, 1, "/c", "abcdefghijklmnopqrstuvwxyz123456789", "");
    assert(state.count == 1 && state.used == 37);
    assert(campfire::find_page(entries, bytes, state, 1, "/b") == -1);
    campfire::store_page(entries, bytes, state, 1, "/huge", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", "");
    assert(state.count == 1 && state.used == 37);
    campfire::clear_cache(state);
    assert(state.count == 0 && state.used == 0);
    assert(campfire::find_page(entries, bytes, state, 1, "/c") == -1);
    print("Cache key isolation, content, capacity eviction and reset passed");
}
