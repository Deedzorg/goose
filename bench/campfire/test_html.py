"""Independent extraction of message identities and visible presentation text."""

from html.parser import HTMLParser


class MessageHTML(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.current = None
        self.identity = None
        self.depth = 0
        self.text = []
        self.messages = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "div" and "data-message-id" in attrs:
            assert self.depth == 0, "nested message inside a presentation"
            self.current = int(attrs["data-message-id"])
            self.identity = attrs.get("id")
            assert self.identity and self.identity.startswith("message_")
        if tag == "div" and attrs.get("id", "").startswith("presentation_message_"):
            assert self.current and attrs["id"] == "presentation_" + self.identity
            assert self.depth == 0, "nested presentation"
            self.depth = 1
            self.text = []
        elif self.depth:
            if tag == "div":
                self.depth += 1
            if tag in ("p", "div", "br", "li", "pre"):
                self.text.append(" ")

    def handle_endtag(self, tag):
        if self.depth:
            if tag == "div":
                self.depth -= 1
                if self.depth == 0:
                    self.messages.append((self.current, "".join(self.text)))
            if tag in ("p", "div", "li", "pre"):
                self.text.append(" ")

    def handle_data(self, data):
        if self.depth:
            self.text.append(data)


def message_text(body):
    parser = MessageHTML()
    parser.feed(body)
    parser.close()
    assert parser.depth == 0, "unclosed presentation"
    return [(mid, " ".join(text.split())) for mid, text in parser.messages]
