"""Compare parsed HTML: attribute order and layout whitespace are insignificant."""

import argparse
from difflib import SequenceMatcher
from html.parser import HTMLParser
import json
from pathlib import Path


class CanonicalHTML(HTMLParser):
    def __init__(self, source, base):
        super().__init__(convert_charrefs=True)
        self.events, self.base, self.literal = [], base, []
        self.feed(source)
        self.close()

    def normalize(self, value):
        return value.replace(self.base, "http://SERVER") if value else value

    def handle_starttag(self, tag, attrs):
        self.events.append(("start", tag, sorted((key, self.normalize(value)) for key, value in attrs)))
        if tag in ("script", "style", "pre", "textarea"):
            self.literal.append(tag)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag):
        self.events.append(("end", tag))
        if self.literal and self.literal[-1] == tag:
            self.literal.pop()

    def handle_data(self, data):
        data = self.normalize(data)
        if not self.literal:
            data = " ".join(data.split())
        if data:
            self.events.append(("text", data))

    def handle_decl(self, decl):
        self.events.append(("declaration", decl.lower()))


def compare(left, right, name):
    a = CanonicalHTML((left / f"{name}.html").read_text(encoding="utf8"), json.loads((left / "source.json").read_text())["base"]).events
    b = CanonicalHTML((right / f"{name}.html").read_text(encoding="utf8"), json.loads((right / "source.json").read_text())["base"]).events
    if a == b:
        print(name, "identical HTML structure, attributes and content", len(a), "events")
        return True
    matcher = SequenceMatcher(a=[repr(x) for x in a], b=[repr(x) for x in b], autojunk=False)
    differences = [op for op in matcher.get_opcodes() if op[0] != "equal"]
    print(name, len(a), len(b), "events;", len(differences), "differences")
    for _, i, j, k, l in differences[:12]:
        print("  reference", i, repr(a[i:min(j, i + 2)])[:1200])
        print("  candidate", k, repr(b[k:min(l, k + 2)])[:1200])
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--routes", nargs="+", default=["room", "page", "sidebar", "search"])
    args = parser.parse_args()
    results = [compare(args.reference, args.candidate, name) for name in args.routes]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
