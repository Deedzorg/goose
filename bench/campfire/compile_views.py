#!/usr/bin/env python3
"""Compile the pinned Askama view subset into native Goose render functions.

Templates remain unaltered upstream files. Unsupported constructs or expressions
fail the build; this translator never evaluates templates at request time.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).parent / "views/templates"


def literal(s):
    return json.dumps(s, ensure_ascii=False)


def split_args(s, separator=","):
    parts, start, depth, quoted, escaped = [], 0, 0, False, False
    for i, c in enumerate(s):
        if quoted:
            if escaped: escaped = False
            elif c == "\\": escaped = True
            elif c == '"': quoted = False
        elif c == '"': quoted = True
        elif c in "([": depth += 1
        elif c in ")]": depth -= 1
        elif c == separator and depth == 0:
            parts.append(s[start:i].strip()); start = i + 1
    parts.append(s[start:].strip())
    return parts if s.strip() else []


def tokens(path):
    source = (ROOT / path).read_text(encoding="utf8").removesuffix("\n")
    result, pos, trim = [], 0, False
    for m in re.finditer(r"{{.*?}}|{%.*?%}|{\#.*?\#}", source, re.S):
        text = source[pos:m.start()]
        if trim: text = text.lstrip(" \t\r\n")
        if m[0][2] == "-": text = text.rstrip(" \t\r\n")
        result.append(("text", text))
        kind = {"{{":"expr", "{%":"stmt", "{#":"comment"}[m[0][:2]]
        value = m[0][2:-2].removeprefix("-").removesuffix("-").strip()
        if kind != "comment": result.append((kind,value))
        trim, pos = m[0][-3] == "-", m.end()
    text = source[pos:]
    result.append(("text", text.lstrip(" \t\r\n") if trim else text))
    return result


def parse(path):
    items = tokens(path)
    def body(i, ending=()):
        nodes = []
        while i < len(items):
            kind, val = items[i]; i += 1
            op = val.split(" ",1)[0]
            if kind == "stmt" and op in ending: return nodes, i, val
            if kind != "stmt": nodes.append((kind,val)); continue
            if op in ("if", "for", "filter", "block"):
                child, i, stop = body(i, ("elif","else","endif") if op == "if" else ("end"+op,))
                if op == "if":
                    branches = [(val[3:],child)]
                    while stop.startswith("elif ") or stop == "else":
                        test = stop[5:] if stop.startswith("elif ") else None
                        child, i, stop = body(i,("elif","else","endif")); branches.append((test,child))
                    nodes.append(("if",branches))
                else: nodes.append((op,val[len(op)+1:],child))
            elif op in ("include","extends","let"): nodes.append((op,val[len(op)+1:]))
            else: raise ValueError((path,"unsupported statement",val))
        if ending: raise ValueError((path,"unclosed",ending))
        return nodes,i,None
    return body(0)[0]


ROUTES = {
    "searches": '"/searches"', "clear_searches": '"/searches/clear"',
    "user_sidebar": '"/users/me/sidebar"', "user_push_subscriptions": '"/users/me/push_subscriptions"',
    "user_profile": '"/users/me/profile"', "edit_account": '"/account/edit"',
    "new_rooms_direct": '"/rooms/directs/new"', "new_rooms_open": '"/rooms/opens/new"',
    "account_join_code": '"/account/join_code"',
}


class Generator:
    def __init__(self):
        self.lines, self.counter = [], 0
        self.aliases = dict(show="ctx", index="ctx", current_user="ctx.user", user="ctx.user", room="ctx.room",
                            messages="ctx.messages", direct_memberships="ctx.direct_memberships",
                            other_memberships="ctx.other_memberships", direct_placeholder_users="ctx.placeholders",
                            can_create_rooms="ctx.can_create_rooms", rooms_stream="ctx.rooms_stream",
                            user_rooms_stream="ctx.user_rooms_stream", room_kind="ctx.room.kind")

    def emit(self,line): self.lines.append("    "+line)

    def attrs(self,s):
        assert s.startswith("h::attrs()"),s
        s=s[len("h::attrs()"):]; values=[]
        while s:
            m=re.match(r"\.([a-z_]+)\(",s); assert m,s
            start=m.end(); depth=1; quoted=False; escaped=False; end=start
            for end in range(start,len(s)):
                c=s[end]
                if quoted:
                    if escaped: escaped=False
                    elif c=='\\': escaped=True
                    elif c=='"': quoted=False
                elif c=='"': quoted=True
                elif c=='(': depth+=1
                elif c==')':
                    depth-=1
                    if depth==0: break
            args=split_args(s[start:end]); method=m[1]; s=s[end+1:]
            if method in ("data","aria"):
                key=literal(method+"-"+json.loads(args[0]).replace("_","-")); value=self.expr(args[1])
            elif method in ("attr","attr_opt"):
                key=args[0]; value=self.expr(args[1])
            elif method=="aria_hidden": key='"aria-hidden"'; value='"true"'
            else:
                assert len(args)==1,(method,args)
                key=literal(method.removesuffix("_")); value=self.expr(args[0])
            values.append(f"html_attr({key}, {value})")
        return "["+", ".join(values)+"]"

    def expr(self,s):
        s=s.strip().removeprefix("&").removeprefix("*").removesuffix("|safe").strip()
        s=re.sub(r"\.(?:as_str|as_deref|as_ref|clone)\(\)","",s)
        if s in ("true","false") or re.fullmatch(r"\d+",s) or s.startswith('"') and s.endswith('"') and len(split_args(s,"~"))==1:
            return s
        if s in ("None",): return '""'
        if s.startswith("Some(") and s.endswith(")"): return self.expr(s[5:-1])
        parts=split_args(s,"~")
        if len(parts)>1: return "str("+", ".join(self.expr(p) for p in parts)+")"
        if s.startswith("h::attrs()"): return self.attrs(s)
        exact={
            'self.page_title()':'ctx.title', 'self.body_class()':'ctx.body_class', 'self.loaded_at()':'ctx.room.updated_ms',
            'ctx.can_administer()':'ctx.user.administrator', 'ctx.flash_alert.is_some()':'ctx.has_alert',
            'ctx.flash_notice.or(ctx.flash_alert)':'ctx.notice',
            'crate::messages::REACTIONS':'reactions()',
            'h::current_user_meta_tags(ctx)':'current_user_meta(ctx)',
            'h::script_aware_action_cable_meta_tag(ctx)':'cable_meta()',
            'h::custom_styles_tag(ctx)':'custom_styles_html(ctx)',
            'h::body_classes(ctx, self.body_class())':'body_classes(ctx)',
            'crate::messages::presentation::message_presentation(ctx, message)':'message.presentation',
        }
        if s in exact: return exact[s]
        m=re.fullmatch(r"h::routes::(\w+)\((.*)\)",s)
        if m:
            if m[1] in ROUTES: return ROUTES[m[1]]
            args=[self.expr(a) for a in split_args(m[2])]
            patterns={'room':'str("/rooms/", {})','room_messages':'str("/rooms/", {}, "/messages")',
                      'room_refresh':'str("/rooms/", {}, "/refresh")','room_involvement':'str("/rooms/", {}, "/involvement")',
                      'join':'str("/join/", {})'}
            return patterns[m[1]].format(*args)
        m=re.fullmatch(r"(ctx.asset|ctx.url|h::raw|h::capitalize|h::page_title_tag|h::turbo_stream_from|h::account_logo_tag|h::translation_button|h::sidebar_turbo_frame_tag|h::image_tag|h::builder_tag|h::dom_id|h::rooms_directs_with_user|crate::rooms::mention_prompt_src|crate::searches::search_path|crate::messages::room_dom_id)\((.*)\)",s)
        if m:
            args=[self.expr(a) for a in split_args(m[2])]; name=m[1]
            if name=='h::raw': return args[0]
            names={'ctx.asset':'asset_path','ctx.url':'absolute_url','h::capitalize':'capitalized',
                   'h::page_title_tag':'title_html','h::turbo_stream_from':'stream_html','h::account_logo_tag':'account_logo_html',
                   'h::translation_button':'translation_button_html','h::sidebar_turbo_frame_tag':'sidebar_frame_html',
                   'h::image_tag':'image_html','h::builder_tag':'builder_html','h::dom_id':'record_dom_id',
                   'h::rooms_directs_with_user':'direct_user_url','crate::rooms::mention_prompt_src':'mention_prompt_url',
                   'crate::searches::search_path':'search_url','crate::messages::room_dom_id':'room_dom_id'}
            if name=='ctx.url': args.insert(0,'ctx')
            if name=='h::image_tag': args=args[1:]
            return names[name]+"("+", ".join(args)+")"
        if s.endswith('.len()'): return self.expr(s[:-6])+'.len'
        if s.endswith('.is_empty()'): return '('+self.expr(s[:-11])+'.len == 0)'
        m=re.fullmatch(r"([\w.\[\]0-9]+)\.([a-z_]+)\((.*)\)",s)
        if m:
            obj=self.expr(m[1]); name=m[2]; args=[self.expr(a) for a in split_args(m[3])]
            fields={'created_at_epoch':'created_ms','updated_at_epoch':'updated_ms','created_at_iso':'created_iso',
                    'is_unrenderable':'unrenderable','attachment':'attachment','is_direct':'direct',
                    'first_name':'first_name','member_initials':'initials','class_names':'classes','room_id':'room_id',
                    'path':'path','at_path':'at_path','boosts_path':'boosts_path','new_boost_path':'new_boost_path','edit_path':'edit_path','noun':'noun'}
            if name in fields: return obj+'.'+fields[name]
            if name=='dom_id':
                if not args: return obj+'.dom_id'
                return 'prefixed_id('+obj+'.dom_id, '+args[0]+')'
        if re.fullmatch(r"[a-zA-Z_][\w.\[\]0-9]*",s):
            head,sep,tail=s.partition('.')
            result=self.aliases.get(head,head)+(sep+tail if sep else '')
            return result.replace('.avatar_path','.avatar_url')
        raise ValueError('unsupported expression: '+s)

    def condition(self,s):
        # The boolean operators in these templates have the same precedence in Goose.
        s=s.replace('.len()', '.len')
        # Preserve method calls while translating their atomic operands.
        s=re.sub(r"([\w.]+)\.(is_empty|is_some|is_direct|is_unrenderable)\(\)",lambda m: {'is_empty':f'({self.expr(m[1])}.len == 0)','is_some':'ctx.has_alert','is_direct':f'{self.expr(m[1])}.direct','is_unrenderable':f'{self.expr(m[1])}.unrenderable'}[m[2]],s)
        s=s.replace('ctx.can_administer()','ctx.user.administrator')
        return re.sub(r"\b[A-Za-z_][\w.]*\b",lambda m: self.expr(m[0]) if m[0] not in ('true','false') else m[0],s)

    def render(self,nodes,blocks=None):
        blocks=blocks or {}
        for node in nodes:
            kind,val=node[:2]
            if kind=='text':
                if val: self.emit('out.append('+literal(val)+');')
            elif kind=='expr':
                calls={'crate::messages::cached_message_item(ctx, message)':'render_message_html(out, ctx, message);',
                       'crate::messages::cached_boost(ctx, boost)':'render_boost_html(out, ctx, boost);',
                       'crate::users::cached_direct_room(ctx, membership)':'render_direct_room_html(out, ctx, membership);'}
                if val in calls: self.emit(calls[val]); continue
                safe=val.endswith('|safe') or val.startswith(('h::image_tag','h::builder_tag','h::page_title_tag','h::raw(',
                     'h::current_user_meta_tags','h::script_aware_action_cable_meta_tag','h::custom_styles_tag',
                     'h::account_logo_tag','h::translation_button','h::turbo_stream_from','h::sidebar_turbo_frame_tag'))
                self.emit(('out.append(' if safe else 'html_value(out, ')+self.expr(val)+');')
            elif kind=='include': self.render(parse(json.loads(val)),blocks)
            elif kind=='block': self.render(blocks.get(val,node[2]),{})
            elif kind=='extends': pass
            elif kind=='let':
                name,expr=val.split('=',1); self.aliases[name.strip()]=self.expr(expr.strip())
            elif kind=='if':
                for i,(test,child) in enumerate(val):
                    old=dict(self.aliases)
                    if test and test.startswith('let Some('):
                        m=re.fullmatch(r'let Some\((\w+)\) = (.*)',test); obj=self.expr(m[2]); self.aliases[m[1]]=obj
                        cond= 'message.has_attachment' if m[1]=='attachment' else ('ctx.has_query' if m[1] in ('q','query') else obj+'.len > 0')
                    else: cond=self.condition(test) if test else ''
                    self.emit(('if ' if i==0 else '} else if ')+cond+' {' if test else '} else {')
                    self.render(child,blocks); self.aliases=old
                self.emit('}')
            elif kind=='for':
                var,seq=val.split(' in ',1); old=dict(self.aliases)
                if var=='(character, title)':
                    var='reaction'; self.aliases.update(character='reaction.character',title='reaction.title')
                else: self.aliases[var]=var
                limit=None
                m=re.fullmatch(r'(.*)\.iter\(\)\.take\((\d+)\)',seq)
                if m: seq=m[1]; limit=int(m[2])
                self.counter+=1
                index=f'view_index_{self.counter}'
                if limit:
                    self.emit(f'for {index} in min({self.expr(seq)}.len, {limit}) {{')
                    self.aliases[var]=self.expr(seq)+f'[{index}]'
                else: self.emit(f'for {var} in {self.expr(seq)} {{')
                self.render(node[2],blocks); self.emit('}'); self.aliases=old
            elif kind=='filter':
                self.counter+=1; name=f'view_block_{self.counter}'
                self.emit('{'); self.emit(f'var {name}: u8[>..] = [];')
                start=len(self.lines); self.render(node[2],blocks)
                for i in range(start,len(self.lines)):
                    parts=re.split(r'("(?:\\.|[^"\\])*")',self.lines[i])
                    self.lines[i]=''.join(re.sub(r'\bout\b',name,p) if j%2==0 else p for j,p in enumerate(parts))
                if val=='sidebar_turbo_frame_tag': call=f'sidebar_frame_html("", {name})'
                else:
                    m=re.fullmatch(r'(\w+)\((.*)\)',val); assert m,val
                    args=[self.expr(a) for a in split_args(m[2])]
                    call='block_'+m[1]+'('+', '.join(args+[name])+')'
                self.emit('out.append('+call+');'); self.emit('}')

    def template(self,name):
        nodes=parse(name); blocks={n[1]:n[2] for n in nodes if n[0]=='block'}
        extends=next((json.loads(n[1]) for n in nodes if n[0]=='extends'),None)
        self.render(parse(extends) if extends else nodes,blocks if extends else {})


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).parent/'views_generated.goose')
    args=parser.parse_args()
    source = json.loads((ROOT.parent / 'source.json').read_text())
    for path, expected in source['templates_sha256'].items():
        content = (ROOT / path).read_bytes().replace(b'\r\n', b'\n')
        if hashlib.sha256(content).hexdigest() != expected:
            raise SystemExit(f'pinned template has changed: {path}')
    functions={
        'message':('messages/_message.html', ', message: const MessageView&'),
        'boost':('messages/boosts/_boost.html', ', boost: const BoostView&'),
        'direct_room':('users/sidebars/rooms/_direct.html', ', membership: const DirectView&'),
        'room':('rooms/show.html',''), 'sidebar':('users/sidebars/show.html',''),
        'search':('searches/index.html',''), 'messages':('messages/index.html',''),
        'post':('messages/create.turbo_stream.html',', message: const MessageView&'),
    }
    out=['// Generated by compile_views.py from the pinned, unmodified view templates.','namespace campfire;','import std;','import view_types;','import view_helpers;']
    for name,(path,params) in functions.items():
        g=Generator(); g.template(path)
        out.append(f'fn render_{name}_html(out: u8[>..]&, ctx: const ViewContext&{params}) {{\n'+'\n'.join(g.lines)+'\n}')
    args.output.write_text('\n\n'.join(out)+'\n',encoding='utf8',newline='\n')
    print('compiled',len(functions),'native Goose renderers')


if __name__=='__main__': main()
