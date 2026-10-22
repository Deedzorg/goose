namespace campfire;
import std;
import base64;
import html;
import view_types;
import view_assets_generated;

struct HtmlAttr { name: u8[], value: u8[] }
struct Reaction { character: u8[], title: u8[] }

fn html_attr(name: const u8[:], value) -> HtmlAttr { return HtmlAttr { name: str(name), value: str(value) }; }
fn html_value(out: u8[>..]&, value) { escape(out, str(value)); }

fn append_attrs(out: u8[>..]&, attrs: const HtmlAttr[:], skip_size: bool = false) {
    for a in attrs {
        if skip_size && a.name == "size" { continue; }
        out.push(' '); out.append(a.name); out.append("=\""); escape(out, a.value); out.push('"');
    }
}

fn builder_html(tag: const u8[:], attrs: HtmlAttr[]) -> u8[>..] {
    var out: u8[>..] = []; out.push('<'); out.append(tag); append_attrs(out, attrs); out.push('>');
    if tag != "meta" && tag != "link" { out.append("</"); out.append(tag); out.push('>'); }
    return out;
}

fn element_html(tag: const u8[:], attrs: HtmlAttr[], body: const u8[:]) -> u8[>..] {
    var out: u8[>..] = []; out.push('<'); out.append(tag); append_attrs(out, attrs); out.push('>');
    out.append(body); out.append("</"); out.append(tag); out.push('>'); return out;
}

fn image_html(source: const u8[:], attrs: HtmlAttr[]) -> u8[>..] {
    var out: u8[>..] = []; out.append("<img"); append_attrs(out, attrs, true);
    out.append(" src=\""); escape(out, asset_path(source)); out.push('"');
    for a in attrs { if a.name == "size" { out.append(" width=\""); escape(out,a.value); out.append("\" height=\""); escape(out,a.value); out.push('"'); } }
    out.append(" />"); return out;
}

fn title_html(title: const u8[:]) -> u8[>..] {
    var text: u8[>..] = []; escape(text,title); return element_html("title",[],text);
}
fn cable_meta() -> u8[>..] { return builder_html("meta",[html_attr("name","action-cable-url"),html_attr("content","/cable")]); }
fn current_user_meta(ctx: const ViewContext&) -> u8[>..] {
    var out: u8[>..] = []; out.append("<meta name=\"current-user-id\" content=\""); format(out,ctx.user.id);
    out.append("\" /><meta name=\"current-user-name\" content=\""); escape(out,ctx.user.name); out.append("\" />"); return out;
}
fn custom_styles_html(ctx: const ViewContext&) -> u8[>..] {
    if ctx.has_custom_styles { return element_html("style",[html_attr("data-turbo-track","reload")],ctx.custom_styles); }
    return [];
}
fn body_classes(ctx: const ViewContext&) -> u8[>..] {
    var out: u8[>..] = []; out.append(ctx.body_class);
    if ctx.user.administrator { if out.len > 0 { out.push(' '); } out.append("admin"); }
    if ctx.account.has_logo { if out.len > 0 { out.push(' '); } out.append("account-has-logo"); } return out;
}
fn absolute_url(ctx: const ViewContext&, path: const u8[:]) -> u8[>..] { return str(ctx.base_url,path); }
fn prefixed_id(id: const u8[:], prefix: const u8[:]) -> u8[>..] { return if prefix.len == 0 { str(id) } else { str(prefix,"_",id) }; }
fn record_dom_id(kind: const u8[:], id: i64, prefix: const u8[:]) -> u8[>..] { return prefixed_id(str(kind,"_",id),prefix); }
fn room_dom_id(kind: const u8[:], id: i64, prefix: const u8[:]) -> u8[>..] { return record_dom_id(kind,id,prefix); }
fn mention_prompt_url(room: i64) -> u8[>..] { return str("/autocompletable/users?room_id=",room); }
fn direct_user_url(user: i64) -> u8[>..] { return str("/rooms/directs?user_ids%5B%5D=",user); }
fn search_url(query: const u8[:]) -> u8[>..] {
    var out: u8[>..] = []; out.append("/searches?q="); let hex="0123456789ABCDEF";
    for c in query {
        if html_word(c) || c == '-' || c == '.' || c == '~' { out.push(c); }
        else if c == ' ' { out.push('+'); } else { out.push('%'); out.push(hex[c >> 4]); out.push(hex[c & 15]); }
    } return out;
}
fn capitalized(text: const u8[:]) -> u8[>..] {
    var out: u8[>..] = []; for i in text.len { let c=text[i]; out.push(if i == 0 && c >= 'a' && c <= 'z' { c - 32 } else if i > 0 && c >= 'A' && c <= 'Z' { c + 32 } else { c }); } return out;
}
fn stream_html(name: const u8[:]) -> u8[>..] { return builder_html("turbo-cable-stream-source",[html_attr("channel","Turbo::StreamsChannel"),html_attr("signed-stream-name",name)]); }
fn sidebar_frame_html(source: const u8[:], body: const u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.append("<turbo-frame data-turbo-permanent=\"true\" data-controller=\"rooms-list read-rooms turbo-frame\" data-rooms-list-unread-class=\"unread\" data-action=\"presence:present@window->rooms-list#read read-rooms:read->rooms-list#read turbo:frame-load->rooms-list#loaded refresh-room:visible@window->turbo-frame#reload\" id=\"user_sidebar\"");
    if source.len > 0 { out.append(" src=\""); escape(out,source); out.push('"'); }
    out.append(" target=\"_top\">"); out.append(body); out.append("</turbo-frame>"); return out;
}
fn block_link_to(url: const u8[:], attrs: HtmlAttr[], body: const u8[:]) -> u8[>..] {
    var out: u8[>..] = []; out.append("<a"); append_attrs(out,attrs); out.append(" href=\""); escape(out,url); out.append("\">"); out.append(body); out.append("</a>"); return out;
}
fn block_link_to_room(id: i64, attrs: HtmlAttr[], body: const u8[:]) -> u8[>..] {
    var all: HtmlAttr[>..] = [];
    all.append(attrs);
    all.push(html_attr("data-rooms-list-target","room")); all.push(html_attr("data-room-id",id));
    all.push(html_attr("data-badge-dot-target","unread")); all.push(html_attr("data-sorted-list-target","item"));
    return block_link_to(str("/rooms/",id),copy(all),body);
}
fn block_button_to(url: const u8[:], attrs: HtmlAttr[], body: const u8[:]) -> u8[>..] {
    var out: u8[>..] = []; out.append("<form class=\"button_to\" method=\"post\" action=\""); escape(out,url);
    out.append("\"><button"); append_attrs(out,attrs); out.append(" type=\"submit\">"); out.append(body); out.append("</button></form>"); return out;
}
fn block_button_to_copy_to_clipboard(url: const u8[:], body: const u8[:]) -> u8[>..] {
    return element_html("button",[html_attr("class","btn"),html_attr("data-controller","copy-to-clipboard"),html_attr("data-action","copy-to-clipboard#copy"),html_attr("data-copy-to-clipboard-success-class","btn--success"),html_attr("data-copy-to-clipboard-content-value",url)],body);
}
fn block_link_to_zoom_qr_code(url: const u8[:], body: const u8[:]) -> u8[>..] {
    var encoded: u8[>..] = []; base64::encode(encoded,url);
    for i in encoded.len { if encoded[i] == '+' { encoded[i]='-'; } else if encoded[i]=='/' { encoded[i]='_'; } }
    let path=str("/qr_codes/",encoded);
    return block_link_to(path,[html_attr("class","btn"),html_attr("data-lightbox-target","image"),html_attr("data-action","lightbox#open"),html_attr("data-lightbox-url-value",path)],body);
}
fn block_web_share_session_button(url: const u8[:], title: const u8[:], text: const u8[:], body: const u8[:]) -> u8[>..] {
    return element_html("button",[html_attr("class","btn"),html_attr("hidden","hidden"),html_attr("data-controller","web-share"),html_attr("data-action","web-share#share"),html_attr("data-web-share-url-value",url),html_attr("data-web-share-text-value",text),html_attr("data-web-share-title-value",title)],body);
}
fn account_logo_html(ctx: const ViewContext&, style: const u8[:]) -> u8[>..] {
    return element_html("figure",[html_attr("class",str("account-logo avatar ",style))],image_html(ctx.account.logo_url,[html_attr("alt","Account logo"),html_attr("size",300)]));
}
fn reactions() -> Reaction[>..] {
    var out: Reaction[>..] = [];
    out.push(Reaction {character:str("👍"),title:str("Thumbs up")});
    out.push(Reaction {character:str("👏"),title:str("Clapping")});
    out.push(Reaction {character:str("👋"),title:str("Waving hand")});
    out.push(Reaction {character:str("💪"),title:str("Muscle")});
    out.push(Reaction {character:str("❤️"),title:str("Red heart")});
    out.push(Reaction {character:str("😂"),title:str("Face with tears of joy")});
    out.push(Reaction {character:str("🎉"),title:str("Party popper")});
    out.push(Reaction {character:str("🔥"),title:str("Fire")}); return out;
}

fn translation_button_html(ctx: const ViewContext&, key: const u8[:]) -> u8[>..] {
    assert(key == "invite_message");
    var rows: u8[>..] = [];
    rows.append(element_html("dt", [], "🇺🇸"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Welcome to Campfire. To invite some people to chat with you, share the join link below."));
    rows.append(element_html("dt", [], "🇪🇸"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Bienvenido a Campfire. Para invitar a algunas personas a chatear contigo, comparte el enlace de unión que se encuentra a continuación."));
    rows.append(element_html("dt", [], "🇫🇷"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Bienvenue sur Campfire. Pour inviter des personnes à discuter avec vous, partagez le lien pour rejoindre ci-dessous."));
    rows.append(element_html("dt", [], "🇮🇳"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Campfire में आपका स्वागत है। अधिक लोगों को चैट के लिए आमंत्रित करने के लिए, नीचे जुड़ने का लिंक साझा करें।"));
    rows.append(element_html("dt", [], "🇩🇪"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Willkommen bei Campfire. Um einige Personen zum Chatten einzuladen, teilen Sie den unten stehenden Beitrittslink."));
    rows.append(element_html("dt", [], "🇧🇷"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Boas vindas ao Campfire. Para convidar pessoas para conversarem com você, compartilhe o link de convite abaixo."));
    rows.append(element_html("dt", [], "🇯🇵"));
    rows.append(element_html("dd", [html_attr("class","margin-none")], "Campfireへようこそ。他の人をチャットに招待するには、下記の参加リンクを共有してください。"));
    let summary=element_html("summary",[html_attr("class","btn"),html_attr("tabindex",-1)],str(image_html("globe.svg",[html_attr("size",20),html_attr("aria-hidden",true),html_attr("class","color-icon")]),element_html("span",[html_attr("class","for-screen-reader")],"Translate")));
    let menu=element_html("div",[html_attr("class","language-list-menu shadow"),html_attr("data-popup-target","menu")],element_html("dl",[html_attr("class","language-list")],rows));
    return element_html("details",[html_attr("class","position-relative"),html_attr("data-controller","popup"),html_attr("data-action","keydown.esc->popup#close toggle->popup#toggle click@document->popup#closeOnClickOutside"),html_attr("data-popup-orientation-top-class","popup-orientation-top")],str(summary,menu));
}
