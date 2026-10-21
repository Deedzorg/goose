import std;
import html;

fn main() {
    var out: u8[>..] = [];
    campfire::rich_text(out, "<p onclick='bad()'>Hello <strong>world</strong> &amp; friends</p><img src=x onerror=bad()>");
    assert(out == "<p>Hello <strong>world</strong> &amp; friends</p>");
    out.clear();
    campfire::rich_text(out, "<a href='jav&#x61;script:bad()'>bad</a><a href='https://example.test/x'>good</a>");
    assert(out == "<a>bad</a><a href=\"https://example.test/x\" rel=\"nofollow noopener noreferrer\">good</a>");
    out.clear();
    campfire::rich_text(out, "<DIV><b>nested</DIV> & bare <");
    assert(out == "<div><b>nested</b></div> &amp; bare &lt;");
    print("rich text rendering passed");
}
