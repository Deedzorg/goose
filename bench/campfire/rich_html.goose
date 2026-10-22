namespace campfire;
import std;
import html;

struct RichAttr { name: const u8[:], value: const u8[:] }
struct RichTag { name: const u8[:] = "", end: i64 = 0, closing: bool = false }

fn rich_tag(source: const u8[:], start: i64, attrs: RichAttr[>..]&) -> RichTag {
    var tag=RichTag { end:start+1, .. }; var i=start+1;
    if i<source.len && source[i]=='/' { tag.closing=true; i+=1; }
    let first=i; while i<source.len && html_word(source[i]) { i+=1; }
    tag.name=source[first..i];
    while i<source.len {
        while i<source.len && (html_space(source[i]) || source[i]=='/') { i+=1; }
        if i==source.len { break; }
        if source[i]=='>' { tag.end=i+1; return tag; }
        let begin=i;
        while i<source.len && !html_space(source[i]) && source[i]!='=' && source[i]!='>' && source[i]!='/' { i+=1; }
        if i==begin { i+=1; continue; }
        let name=source[begin..i];
        while i<source.len && html_space(source[i]) { i+=1; }
        var value: const u8[:]=source[..0];
        if i<source.len && source[i]=='=' {
            i+=1; while i<source.len && html_space(source[i]) { i+=1; }
            var quote: u8=0;
            if i<source.len && (source[i]=='\'' || source[i]=='"') { quote=source[i]; i+=1; }
            let value_start=i;
            while i<source.len && (if quote!=0 { source[i]!=quote } else { !html_space(source[i]) && source[i]!='>' }) { i+=1; }
            value=source[value_start..i]; if quote!=0 && i<source.len { i+=1; }
        }
        attrs.push(RichAttr { name:name,value:value });
    }
    tag.end=source.len; return tag;
}

fn rich_attribute(attrs: const RichAttr[:], name: const u8[:]) -> const u8[:] {
    for a in attrs { if a.name==name { return a.value; } } return "";
}

fn html_decode(source: const u8[:]) -> u8[>..] {
    var out: u8[>..]=[]; var i: i64=0;
    while i<source.len {
        if source[i]=='&' {
            let end=find(source[i..],";");
            if end>0 && end<=16 {
                let entity=source[i+1..i+end]; var c: i64=-1;
                if entity=="amp" { c=38; } else if entity=="lt" { c=60; } else if entity=="gt" { c=62; }
                else if entity=="quot" { c=34; } else if entity=="apos" { c=39; } else if entity=="nbsp" { c=160; }
                else if starts_with(entity,"#") {
                    let hex=entity.len>2 && (entity[1]=='x' || entity[1]=='X'); c=0;
                    for digit in entity[if hex {2} else {1}..] {
                        let v=if digit>='0' && digit<='9' { digit-'0' } else if hex && digit>='a' && digit<='f' { digit-'a'+10 } else if hex && digit>='A' && digit<='F' { digit-'A'+10 } else { 255 };
                        if v==255 { c=-1; break; } c=c*(if hex {16} else {10})+v;
                    }
                }
                if c>0 && c<=0x10ffff && !(c>=0xd800 && c<=0xdfff) {
                    if c<128 { out.push(c as u8); }
                    else if c<2048 { out.push((192 | (c >> 6)) as u8); out.push((128 | (c & 63)) as u8); }
                    else if c<65536 { out.push((224 | (c >> 12)) as u8); out.push((128 | ((c >> 6) & 63)) as u8); out.push((128 | (c & 63)) as u8); }
                    else { out.push((240 | (c >> 18)) as u8); out.push((128 | ((c >> 12) & 63)) as u8); out.push((128 | ((c >> 6) & 63)) as u8); out.push((128 | (c & 63)) as u8); }
                    i+=end+1; continue;
                }
            }
        }
        out.push(source[i]); i+=1;
    } return out;
}

fn rich_text_segment(out: u8[>..]&, source: const u8[:], autolink: bool) {
    let decoded=html_decode(source); var i: i64=0; var begin: i64=0;
    while autolink && i<decoded.len {
        if starts_with(decoded[i..],"https://") || starts_with(decoded[i..],"http://") {
            escape(out,decoded[begin..i]); var end=i;
            while end<decoded.len && !html_space(decoded[end]) && decoded[end]!='<' && decoded[end]!='>' && decoded[end]!='"' { end+=1; }
            while end>i && (decoded[end-1]=='.' || decoded[end-1]==',' || decoded[end-1]==';') { end-=1; }
            let url=decoded[i..end]; out.append("<a target=\"_blank\" href=\""); escape(out,url); out.append("\">"); escape(out,url); out.append("</a>"); i=end; begin=end;
        } else { i+=1; }
    }
    escape(out,decoded[begin..]);
}

fn rich_sanitize(out: u8[>..]&, source: const u8[:], autolink: bool=true) {
    let allowed="|a|abbr|acronym|address|b|big|blockquote|br|cite|code|dd|del|dfn|div|dl|dt|em|h1|h2|h3|h4|h5|h6|hr|i|img|ins|kbd|li|mark|ol|p|pre|samp|small|span|strong|sub|sup|time|tt|ul|var|s|u|table|thead|tbody|tfoot|tr|th|td|";
    let attributes="|abbr|alt|cite|class|datetime|height|href|lang|src|title|width|xml:lang|data-language|";
    var stack: u8[..32][128]=["";128]; var depth: i64=0; var i: i64=0; var link_depth: i64=0;
    while i<source.len {
        if source[i]!='<' { var end=i+1; while end<source.len && source[end]!='<' { end+=1; } rich_text_segment(out,source[i..end],autolink && link_depth==0); i=end; continue; }
        var attrs: RichAttr[>..]=[]; let tag=rich_tag(source,i,attrs); i=tag.end; let name=html_lower(tag.name);
        if name=="script" || name=="style" || name=="iframe" || name=="svg" || name=="math" {
            if !tag.closing { let end=find(source[i..],str("</",name)); if end<0 { return; } let closing=find(source[i+end..],">"); i=if closing<0 {source.len} else {i+end+closing+1}; } continue;
        }
        if find(allowed,str("|",name,"|"))<0 || name.len==0 { continue; }
        if tag.closing {
            var at=depth-1; while at>=0 && stack[at]!=name { at-=1; }
            if at>=0 { while depth>at { depth-=1; if stack[depth]=="a" { link_depth-=1; } format(out,"</",stack[depth],">"); } } continue;
        }
        if depth==stack.len { continue; }
        format(out,"<",name);
        for a in attrs {
            let attr=html_lower(a.name); if find(attributes,str("|",attr,"|"))<0 { continue; }
            let value=html_decode(a.value);
            if (attr=="href" || attr=="src" || attr=="cite") && !safe_link(value) { continue; }
            format(out," ",attr,"=\""); escape(out,value); out.push('"');
        }
        out.push('>');
        if name!="br" && name!="hr" && name!="img" { stack[depth]=name; depth+=1; if name=="a" { link_depth+=1; } }
    }
    while depth>0 { depth-=1; format(out,"</",stack[depth],">"); }
}
