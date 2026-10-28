//! RSA public-key encryption for the Minecraft login handshake.
//!
//! The server sends an X.509 SubjectPublicKeyInfo (occasionally a bare PKCS#1
//! RSAPublicKey). This module parses that key and applies PKCS#1 v1.5
//! encryption (EME-PKCS1-v1_5), which is what the 1.8.9 protocol expects.

pub const Error = error{
    InvalidPublicKey,
    MessageTooLong,
    OutputBufferTooSmall,
    EntropyUnavailable,
    Canceled,
};

/// The largest RSA modulus supported by `std.crypto.Certificate.rsa` (4096 bits).
const max_modulus_len = 512;

const sequence_tag: u8 = 0x30;
const integer_tag: u8 = 0x02;
const bit_string_tag: u8 = 0x03;

/// Encrypts `message` with a DER-encoded RSA public key.
///
/// `out` must be at least the key's modulus length (128 bytes for the
/// 1024-bit key used by 1.8.9 servers). Returns the number of bytes written.
pub fn encryptPkcs1v15(
    io: std.Io,
    public_key_der: []const u8,
    message: []const u8,
    out: []u8,
) Error!usize {
    const key = try parsePublicKey(public_key_der);
    return encryptWithKey(io, key, message, out);
}

/// Encrypts with an already-parsed key.
pub fn encryptWithKey(
    io: std.Io,
    key: rsa.PublicKey,
    message: []const u8,
    out: []u8,
) Error!usize {
    const modulus_len = modulusLength(key);
    if (modulus_len > max_modulus_len) return error.InvalidPublicKey;
    if (out.len < modulus_len) return error.OutputBufferTooSmall;

    var em_buffer: [max_modulus_len]u8 = undefined;
    const em = em_buffer[0..modulus_len];
    try pkcs1v15Pad(io, message, em);

    const Modulus = @TypeOf(key.n);
    const m = Modulus.Fe.fromBytes(key.n, em, .big) catch return error.MessageTooLong;
    const c = key.n.powPublic(m, key.e) catch return error.InvalidPublicKey;
    c.toBytes(out[0..modulus_len], .big) catch return error.InvalidPublicKey;

    return modulus_len;
}

/// Returns the key's modulus length in bytes.
pub fn modulusLength(key: rsa.PublicKey) usize {
    return (key.n.bits() + 7) / 8;
}

/// Parses either a SubjectPublicKeyInfo or a bare PKCS#1 RSAPublicKey.
pub fn parsePublicKey(public_key_der: []const u8) Error!rsa.PublicKey {
    if (parseSubjectPublicKeyInfo(public_key_der)) |key| {
        return key;
    } else |_| {}

    return parsePkcs1PublicKey(public_key_der);
}

fn parseSubjectPublicKeyInfo(der_bytes: []const u8) Error!rsa.PublicKey {
    var outer_index: usize = 0;
    const outer = try readTlv(der_bytes, &outer_index);
    if (outer.tag != sequence_tag) return error.InvalidPublicKey;

    var index: usize = 0;
    const algorithm = try readTlv(outer.content, &index);
    if (algorithm.tag != sequence_tag) return error.InvalidPublicKey;

    const public_key_bits = try readTlv(outer.content, &index);
    if (public_key_bits.tag != bit_string_tag) return error.InvalidPublicKey;
    if (public_key_bits.content.len == 0) return error.InvalidPublicKey;

    // The first BIT STRING content byte is the number of unused bits.
    if (public_key_bits.content[0] != 0) return error.InvalidPublicKey;

    return parsePkcs1PublicKey(public_key_bits.content[1..]);
}

fn parsePkcs1PublicKey(der_bytes: []const u8) Error!rsa.PublicKey {
    var outer_index: usize = 0;
    const sequence = try readTlv(der_bytes, &outer_index);
    if (sequence.tag != sequence_tag) return error.InvalidPublicKey;

    var index: usize = 0;
    const modulus = try readTlv(sequence.content, &index);
    if (modulus.tag != integer_tag) return error.InvalidPublicKey;

    const exponent = try readTlv(sequence.content, &index);
    if (exponent.tag != integer_tag) return error.InvalidPublicKey;

    if (modulus.content.len == 0 or exponent.content.len == 0) return error.InvalidPublicKey;

    // DER INTEGERs are signed; RSA values must be positive.
    if (modulus.content[0] & 0x80 != 0) return error.InvalidPublicKey;
    if (exponent.content[0] & 0x80 != 0) return error.InvalidPublicKey;

    return rsa.PublicKey.fromBytes(exponent.content, modulus.content) catch return error.InvalidPublicKey;
}

fn pkcs1v15Pad(io: std.Io, message: []const u8, em: []u8) Error!void {
    if (em.len < 11 or message.len > em.len - 11) return error.MessageTooLong;

    em[0] = 0x00;
    em[1] = 0x02;

    const ps_len = em.len - message.len - 3;
    const ps = em[2..][0..ps_len];
    io.randomSecure(ps) catch |err| switch (err) {
        error.EntropyUnavailable => return error.EntropyUnavailable,
        error.Canceled => return error.Canceled,
    };

    // PKCS#1 v1.5 requires every padding byte to be non-zero.
    for (ps) |*byte| {
        if (byte.* == 0) byte.* = 1;
    }

    em[2 + ps_len] = 0x00;
    @memcpy(em[3 + ps_len ..], message);
}

const Tlv = struct {
    tag: u8,
    content: []const u8,
};

/// A bounds-checked DER TLV reader. `std.crypto.Certificate.der.Element.parse`
/// assumes its input is already in bounds, so network-supplied keys need this.
fn readTlv(bytes: []const u8, index: *usize) Error!Tlv {
    if (index.* > bytes.len or bytes.len - index.* < 2) return error.InvalidPublicKey;

    const tag = bytes[index.*];
    index.* += 1;

    const first_len = bytes[index.*];
    index.* += 1;

    var len: usize = 0;
    if (first_len & 0x80 == 0) {
        len = first_len;
    } else {
        const len_bytes: usize = first_len & 0x7f;
        if (len_bytes == 0 or len_bytes > @sizeOf(usize)) return error.InvalidPublicKey;
        if (index.* > bytes.len or bytes.len - index.* < len_bytes) return error.InvalidPublicKey;

        for (0..len_bytes) |_| {
            len = std.math.mul(usize, len, 256) catch return error.InvalidPublicKey;
            len = std.math.add(usize, len, bytes[index.*]) catch return error.InvalidPublicKey;
            index.* += 1;
        }
    }

    if (len > bytes.len - index.*) return error.InvalidPublicKey;
    const content = bytes[index.* .. index.* + len];
    index.* += len;

    return .{
        .tag = tag,
        .content = content,
    };
}

test "PKCS#1 v1.5 padding" {
    const message = "0123456789abcdef";
    var em: [128]u8 = undefined;

    try pkcs1v15Pad(std.testing.io, message, &em);

    try std.testing.expectEqual(@as(u8, 0x00), em[0]);
    try std.testing.expectEqual(@as(u8, 0x02), em[1]);

    const ps_len = em.len - message.len - 3;
    for (em[2..][0..ps_len]) |byte| {
        try std.testing.expect(byte != 0);
    }

    try std.testing.expectEqual(@as(u8, 0x00), em[2 + ps_len]);
    try std.testing.expectEqualSlices(u8, message, em[3 + ps_len ..]);
}

test "parse SPKI and encrypt" {
    // 1024-bit test key generated with:
    //   openssl genrsa 1024
    //   openssl rsa -pubout -outform DER
    const spki_hex =
        "30819f300d06092a864886f70d010101050003818d0030818902818100" ++
        "d52abda3ed474a2a710de603b3647d80e88f8c610a6eb1f5ba1447a339" ++
        "a6419df812f1703727f7d35816cf517601addadb595577efcc53bf2b2c" ++
        "056966a1dd97ecd55a76b28cf37d057aaec220fddd470d662867944c41" ++
        "493b1f8a67bb53a64ed340e6d0e5c9e6eacfcd46621c886be069932e04" ++
        "f2db07f364c59f0fc23e28650203010001";

    var spki: [spki_hex.len / 2]u8 = undefined;
    _ = try std.fmt.hexToBytes(&spki, spki_hex);

    const key = try parsePublicKey(&spki);
    try std.testing.expectEqual(@as(usize, 128), modulusLength(key));

    const message = "0123456789abcdef";
    var encrypted: [max_modulus_len]u8 = undefined;

    const len = try encryptPkcs1v15(std.testing.io, &spki, message, &encrypted);
    try std.testing.expectEqual(@as(usize, 128), len);
}

const std = @import("std");

const rsa = std.crypto.Certificate.rsa;
