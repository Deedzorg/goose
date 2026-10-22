"""Generate asset names and layout tags from the pinned reference asset manifest."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).parent


def quote(value): return json.dumps(value,ensure_ascii=False)


def lookup(entries, key, indent="    "):
    if not entries: return indent+'return -1;\n'
    at=len(entries)//2; name,index=entries[at]
    code=indent+f'let order = compare({key}, {quote(name)});\n'
    code+=indent+f'if order == 0 {{ return {index}; }}\n'
    code+=indent+'if order < 0 {\n'+lookup(entries[:at],key,indent+'    ')+indent+'} else {\n'+lookup(entries[at+1:],key,indent+'    ')+indent+'}\n'
    return code


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture',type=Path,help='import immutable layout asset tags from a live reference capture')
    args=parser.parse_args()
    assets=ROOT/'build/reference-assets'
    manifest=json.loads((assets/'manifest.json').read_text())
    if args.capture:
        page=args.capture.read_text(encoding='utf8')
        css='\n'.join(re.findall(r'<link rel="stylesheet"[^>]+/>',page))
        start=page.index('<script type="importmap"')
        end=page.index('<script type="module">import "application"</script>',start)+len('<script type="module">import "application"</script>')
        tags={'stylesheet_tags':css,'importmap_tags':page[start:end]}
        # Import map/preload tags contain only static assets and the module entry point.
        assert all(url.startswith('/assets/') for url in re.findall(r'(?:href|src)="([^"]+)"',tags['importmap_tags']))
        (ROOT/'views/asset_tags.json').write_text(json.dumps(tags,indent=2)+'\n',encoding='utf8')
        (ROOT/'views/assets.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    assert manifest==json.loads((ROOT/'views/assets.json').read_text())
    for record in manifest.values():
        assert hashlib.sha256((assets/record['path']).read_bytes()).hexdigest()==record['sha256'],record['path']
    tags=json.loads((ROOT/'views/asset_tags.json').read_text())
    entries=sorted(manifest.items())
    out=['// Generated from the pinned Rust static asset manifest; see views/source.json.',
         'namespace campfire;\nimport std;',
         'let VIEW_STYLESHEET_TAGS = '+quote(tags['stylesheet_tags'])+';',
         'let VIEW_IMPORTMAP_TAGS = '+quote(tags['importmap_tags'])+';']
    for kind,values in [('logical',[(k,i) for i,(k,v) in enumerate(entries)]),('public',sorted(('/assets/'+v['path'],i) for i,(k,v) in enumerate(entries)))]:
        out.append('fn asset_'+kind+'_index(name: const u8[:]) -> i64 {\n'+lookup(values,'name')+'}')
    for name,field in [('filename','path'),('mime','content_type')]:
        text=''; spans=[]
        for _,record in entries:
            value=record[field];spans.append((len(text.encode()),len(value.encode())));text+=value
        out.append(f'fn asset_{name}(index: i64) -> const u8[:] {{\n    let data = {quote(text)};\n    let starts = '+str([p for p,n in spans])+';\n    let sizes = '+str([n for p,n in spans])+';\n    guard index >= 0 && index < starts.len else { return ""; }\n    return data[starts[index]..starts[index]+sizes[index]];\n}')
    out.append('fn asset_path(source: const u8[:]) -> u8[>..] {\n    if starts_with(source, "/") || find(source, ":") >= 0 { return str(source); }\n    let index = asset_logical_index(source);\n    guard index >= 0 else { abort(str("Missing asset: ", source)); }\n    return str("/assets/", asset_filename(index));\n}')
    (ROOT/'view_assets_generated.goose').write_text('\n\n'.join(out)+'\n',encoding='utf8',newline='\n')
    print('verified and indexed',len(entries),'immutable assets')


if __name__=='__main__': main()
