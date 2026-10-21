namespace campfire;

import std;

fn escape(out: u8[>..]&, text: const u8[:]) {
    for c in text {
        match c {
            '&' => { out.append("&amp;"); },
            '<' => { out.append("&lt;"); },
            '>' => { out.append("&gt;"); },
            '"' => { out.append("&quot;"); },
            '\'' => { out.append("&#39;"); },
            _ => { out.push(c); },
        }
    }
}

fn html_space(c: u8) -> bool { return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == 12; }
fn html_word(c: u8) -> bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_';
}
fn html_lower(text: const u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    for c in text { out.push(if c >= 'A' && c <= 'Z' { c + 32 } else { c }); }
    return out;
}

fn safe_link(url: const u8[:]) -> bool {
    for c in url { if c <= 32 || c == 127 || c == '&' || c == '\\' { return false; } }
    let lower = html_lower(url);
    return starts_with(lower, "https://") || starts_with(lower, "http://") ||
           starts_with(lower, "mailto:") || starts_with(lower, "#") ||
           (starts_with(lower, "/") && !starts_with(lower, "//"));
}

fn rich_text(out: u8[>..]&, source: const u8[:]) {
    // Only these elements and explicitly checked link targets reach the browser.
    let allowed = "|p|div|span|strong|em|b|i|u|s|del|strike|br|pre|code|blockquote|ul|ol|li|h1|h2|h3|h4|h5|h6|table|thead|tbody|tr|td|th|hr|a|";
    var stack: u8[..12][64] = [""; 64];
    var depth: i64 = 0;
    var i: i64 = 0;
    while i < source.len {
        if source[i] == '&' {
            let end = find(source[i..], ";");
            if end > 1 && end <= 16 {
                let entity = source[i + 1..i + end];
                var valid = entity == "amp" || entity == "lt" || entity == "gt" || entity == "quot" || entity == "apos" || entity == "nbsp";
                if entity[0] == '#' && entity.len > 1 {
                    var start: i64 = 1;
                    var hex = false;
                    if entity[1] == 'x' || entity[1] == 'X' { start = 2; hex = true; }
                    valid = start < entity.len;
                    for c in entity[start..] {
                        if !((c >= '0' && c <= '9') || (hex && ((c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))) { valid = false; }
                    }
                }
                if valid { out.append(source[i..i + end + 1]); i += end + 1; continue; }
            }
            out.append("&amp;"); i += 1; continue;
        }
        if source[i] != '<' {
            if source[i] == '>' { out.append("&gt;"); } else { out.push(source[i]); }
            i += 1; continue;
        }
        var end = i + 1;
        var quote: u8 = 0;
        while end < source.len {
            let c = source[end];
            if quote != 0 { if c == quote { quote = 0; } }
            else if c == '"' || c == '\'' { quote = c; }
            else if c == '>' { break; }
            end += 1;
        }
        if end == source.len { out.append("&lt;"); i += 1; continue; }
        var pos = i + 1;
        let closing = source[pos] == '/';
        if closing { pos += 1; }
        let first = pos;
        while pos < end && html_word(source[pos]) { pos += 1; }
        let name = html_lower(source[first..pos]);
        i = end + 1;
        if name.len == 0 || find(allowed, str("|", name, "|")) < 0 { continue; }
        if closing {
            var match_at = depth - 1;
            while match_at >= 0 && stack[match_at] != name { match_at -= 1; }
            if match_at >= 0 {
                while depth > match_at { depth -= 1; format(out, "</", stack[depth], ">"); }
            }
            continue;
        }
        if depth == stack.len { continue; }
        format(out, "<", name);
        while pos < end {
            while pos < end && (html_space(source[pos]) || source[pos] == '/') { pos += 1; }
            let attr_start = pos;
            while pos < end && html_word(source[pos]) { pos += 1; }
            let attr = html_lower(source[attr_start..pos]);
            if pos == attr_start { pos += 1; continue; }
            while pos < end && html_space(source[pos]) { pos += 1; }
            if pos == end || source[pos] != '=' { continue; }
            pos += 1;
            while pos < end && html_space(source[pos]) { pos += 1; }
            var delimiter: u8 = 0;
            if pos < end && (source[pos] == '"' || source[pos] == '\'') { delimiter = source[pos]; pos += 1; }
            let value_start = pos;
            while pos < end && (if delimiter != 0 { source[pos] != delimiter } else { !html_space(source[pos]) }) { pos += 1; }
            let value = source[value_start..pos];
            if name == "a" && attr == "href" && safe_link(value) {
                out.append(" href=\""); escape(out, value); out.append("\" rel=\"nofollow noopener noreferrer\"");
            }
            if delimiter != 0 && pos < end { pos += 1; }
        }
        out.push('>');
        if name != "br" && name != "hr" { stack[depth] = name; depth += 1; }
    }
    while depth > 0 { depth -= 1; format(out, "</", stack[depth], ">"); }
}
