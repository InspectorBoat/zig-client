//! AES-128 in CFB8 mode, as used by the Minecraft login protocol.
//!
//! CFB8 is a byte-oriented stream mode: each byte is XORed with the first byte
//! of the AES encryption of a 16-byte shift register, then the ciphertext byte
//! is fed back into the register. Encryption and decryption therefore use the
//! AES *encryption* primitive; only the feedback byte differs.

const Cipher = std.crypto.core.aes.AesEncryptCtx(Aes128);

cipher: Cipher,
register: [16]u8,

/// Minecraft uses the shared secret as both the key and the IV.
pub fn init(key: [16]u8) @This() {
    return initWithIv(key, key);
}

pub fn initWithIv(key: [16]u8, iv: [16]u8) @This() {
    return .{
        .cipher = Aes128.initEnc(key),
        .register = iv,
    };
}

/// Encrypts `bytes` in place, advancing the stream state.
pub fn encrypt(self: *@This(), bytes: []u8) void {
    for (bytes) |*byte| {
        const stream_byte = self.keystream();
        const ciphertext = byte.* ^ stream_byte;
        self.feedback(ciphertext);
        byte.* = ciphertext;
    }
}

/// Decrypts `bytes` in place, advancing the stream state.
pub fn decrypt(self: *@This(), bytes: []u8) void {
    for (bytes) |*byte| {
        const stream_byte = self.keystream();
        const ciphertext = byte.*;
        self.feedback(ciphertext);
        byte.* = ciphertext ^ stream_byte;
    }
}

fn keystream(self: *@This()) u8 {
    var block: [16]u8 = undefined;
    self.cipher.encrypt(&block, &self.register);
    return block[0];
}

fn feedback(self: *@This(), byte: u8) void {
    std.mem.copyForwards(u8, self.register[0..15], self.register[1..16]);
    self.register[15] = byte;
}

test "AES-128-CFB8 NIST SP 800-38A vector" {
    const key = hexToArray(16, "2b7e151628aed2a6abf7158809cf4f3c");
    const iv = hexToArray(16, "000102030405060708090a0b0c0d0e0f");
    const plaintext = hexToArray(64, "6bc1bee22e409f96e93d7e117393172a" ++
        "ae2d8a571e03ac9c9eb76fac45af8e51" ++
        "30c81c46a35ce411e5fbc1191a0a52ef" ++
        "f69f2445df4f9b17ad2b417be66c3710");
    const expected_ciphertext = hexToArray(64, "3b79424c9c0dd436bace9e0ed4586a4f" ++
        "32b9ded50ae3ba69d472e88267fb5052" ++
        "70cbad1e257691f7c47c5038297edda3" ++
        "2ff26d0ed19174096161ecc14086dd62");

    var ciphertext = plaintext;
    var enc: @This() = .initWithIv(key, iv);
    enc.encrypt(&ciphertext);
    try std.testing.expectEqualSlices(u8, &expected_ciphertext, &ciphertext);

    var decrypted = ciphertext;
    var dec: @This() = .initWithIv(key, iv);
    dec.decrypt(&decrypted);
    try std.testing.expectEqualSlices(u8, &plaintext, &decrypted);
}

test "AES-CFB8 state survives chunked calls" {
    const key = hexToArray(16, "2b7e151628aed2a6abf7158809cf4f3c");
    const iv = hexToArray(16, "000102030405060708090a0b0c0d0e0f");
    const plaintext = hexToArray(64, "6bc1bee22e409f96e93d7e117393172a" ++
        "ae2d8a571e03ac9c9eb76fac45af8e51" ++
        "30c81c46a35ce411e5fbc1191a0a52ef" ++
        "f69f2445df4f9b17ad2b417be66c3710");
    const expected_ciphertext = hexToArray(64, "3b79424c9c0dd436bace9e0ed4586a4f" ++
        "32b9ded50ae3ba69d472e88267fb5052" ++
        "70cbad1e257691f7c47c5038297edda3" ++
        "2ff26d0ed19174096161ecc14086dd62");

    var ciphertext = plaintext;
    var enc: @This() = .initWithIv(key, iv);
    enc.encrypt(ciphertext[0..7]);
    enc.encrypt(ciphertext[7..31]);
    enc.encrypt(ciphertext[31..]);
    try std.testing.expectEqualSlices(u8, &expected_ciphertext, &ciphertext);
}

test "AES-CFB8 init uses the key as the IV" {
    const key = hexToArray(16, "2b7e151628aed2a6abf7158809cf4f3c");
    const plaintext = hexToArray(16, "6bc1bee22e409f96e93d7e117393172a");

    var a = plaintext;
    var b = plaintext;
    var key_iv: @This() = .init(key);
    var explicit_iv: @This() = .initWithIv(key, key);
    key_iv.encrypt(&a);
    explicit_iv.encrypt(&b);

    try std.testing.expectEqualSlices(u8, &a, &b);
}

fn hexToArray(comptime len: usize, comptime text: []const u8) [len]u8 {
    var out: [len]u8 = undefined;
    _ = std.fmt.hexToBytes(&out, text) catch unreachable;
    return out;
}

const std = @import("std");

const Aes128 = std.crypto.core.aes.Aes128;
