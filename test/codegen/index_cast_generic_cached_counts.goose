// A generic helper's cast names its array only through the substituted
// type, and its result lands in a wider slot than the index type.
var nodes: i32[>..] = [];
type Id = u32 in nodes;
fn convert<T>(n: i64) -> i64 { let v: i64 = n as T; v }
fn main() {
    nodes.push(10);
    nodes.push(20);
    print(convert<Id>(1));
}
