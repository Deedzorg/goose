namespace campfire;

import std;
import os;
import base64;
import json;
import hash;
import http;

fn hmac_sha1(key: const u8[:], data: const u8[:]) -> u8[20] {
    var key_bytes: u8[64] = [0; 64];
    if key.len > 64 {
        let digest = hash::sha1(key);
        for i in digest.len { key_bytes[i] = digest[i]; }
    } else {
        for i in key.len { key_bytes[i] = key[i]; }
    }
    var inner: u8[>..] = [];
    for c in key_bytes { inner.push(c ^ 0x36); }
    inner.append(data);
    let digest = hash::sha1(inner);
    var outer: u8[84] = [0; 84];
    for i in 64 { outer[i] = key_bytes[i] ^ 0x5c; }
    for i in 20 { outer[64 + i] = digest[i]; }
    return hash::sha1(outer);
}

fn hex_digit(c: u8) -> i64 {
    if c >= '0' && c <= '9' { return c - '0'; }
    if c >= 'a' && c <= 'f' { return c - 'a' + 10; }
    if c >= 'A' && c <= 'F' { return c - 'A' + 10; }
    return -1;
}

fn signed_cookie_key(secret: const u8[:]) -> u8[64] {
    var out: u8[64] = [0; 64];
    hash::pbkdf2_sha256(out, secret, "signed cookie", 1000);
    return out;
}

fn sign_cookie(token: const u8[:], key: const u8[:], expiry: const u8[:]) -> u8[>..] {
    var value: u8[>..] = [];
    json::format_string(value, token);
    var encoded_value: u8[>..] = [];
    base64::encode(encoded_value, value);
    var envelope: u8[>..] = [];
    envelope.append("{\"_rails\":{\"message\":");
    json::format_string(envelope, encoded_value);
    envelope.append(",\"exp\":");
    json::format_string(envelope, expiry);
    envelope.append(",\"pur\":\"cookie.session_token\"}}");
    var payload: u8[>..] = [];
    base64::encode(payload, envelope);
    let mac = hmac_sha1(key, payload);
    payload.append("--");
    let digits = "0123456789abcdef";
    for c in mac { payload.push(digits[c >> 4]); payload.push(digits[c & 15]); }
    var escaped: u8[>..] = [];
    for c in payload {
        if c == '+' || c == '/' || c == '=' {
            escaped.push('%'); escaped.push(digits[c >> 4]); escaped.push(digits[c & 15]);
        } else {
            escaped.push(c);
        }
    }
    return escaped;
}

// Rails serializes a signed cookie's value inside a purpose/expiry envelope.
fn verify_cookie(raw: const u8[:], key: const u8[:], now: const u8[:], token: u8[>..]&) -> bool {
    guard raw.len < 8192 else { return false; }
    var decoded_cookie: u8[>..] = [];
    guard http::decode(raw, decoded_cookie, false) else { return false; }
    let split = find(decoded_cookie, "--");
    guard split > 0 && decoded_cookie.len - split - 2 == 40 else { return false; }
    var supplied: u8[20] = [0; 20];
    for i in 20 {
        let hi = hex_digit(decoded_cookie[split + 2 + i * 2]);
        let lo = hex_digit(decoded_cookie[split + 3 + i * 2]);
        guard hi >= 0 && lo >= 0 else { return false; }
        supplied[i] = (hi * 16 + lo) as u8;
    }
    let payload = decoded_cookie[..split];
    guard hash::equal(supplied, hmac_sha1(key, payload)) else { return false; }
    var text: u8[>..] = [];
    guard base64::decode(text, payload) else { return false; }
    var nodes: json::Node[>..] = [];
    var strings: u8[>..] = [];
    let root, error = json::parse(text, nodes, strings);
    guard root else { return false; }
    let envelope = json::member(root, "_rails");
    if envelope {
        let purpose, valid_purpose = json::as_string(json::member(envelope, "pur"));
        guard valid_purpose && purpose == "cookie.session_token" else { return false; }
        let expiry = json::member(envelope, "exp");
        guard expiry else { return false; }
        match expiry.val {
            Null => {},
            Str s => {
                guard s.s.len == 24 && s.s[23] == 'Z' && now.len == 24 && compare(s.s, now) > 0 else { return false; }
            },
            _ => { return false; },
        }
        let message, has_message = json::as_string(json::member(envelope, "message"));
        guard has_message else { return false; }
        var value: u8[>..] = [];
        guard base64::decode(value, message) else { return false; }
        var value_nodes: json::Node[>..] = [];
        var value_strings: u8[>..] = [];
        let value_root, value_error = json::parse(value, value_nodes, value_strings);
        let parsed, ok = json::as_string(value_root);
        guard ok && parsed.len > 0 && parsed.len <= 256 else { return false; }
        token.append(parsed);
        return true;
    }
    let parsed, ok = json::as_string(root);
    guard ok && parsed.len > 0 && parsed.len <= 256 else { return false; }
    token.append(parsed);
    return true;
}
