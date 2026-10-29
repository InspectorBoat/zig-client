//! AES-128 in CFB8 mode

/// `cipher` is just the (transformed) key, which stays constant.
/// Therefore it can be shared between the decryption and encryption
/// routines.
cipher: std.crypto.core.aes.AesEncryptCtx(Aes128),
enc_register: [16]u8,
dec_register: [16]u8,

/// Minecraft uses the same shared secret as both the key and the IV,
/// on both the client and server. Hey, don't shoot the messenger!
pub fn init(key: [16]u8) @This() {
    return initWithIv(key, key);
}

pub fn initWithIv(key: [16]u8, iv: [16]u8) @This() {
    return .{
        .cipher = .init(key),
        .enc_register = iv,
        .dec_register = iv,
    };
}

/// Encrypts `plaintext` in place, advancing the encryption stream state.
pub fn encrypt(self: *@This(), plaintext: []u8) void {
    for (plaintext) |*byte| {
        const stream_byte = keystream(self.enc_register, self.cipher);
        byte.* ^= stream_byte;
        feedback(&self.enc_register, byte.*);
    }
}

/// Decrypts `ciphertext` in place, advancing the decryption stream state.
pub fn decrypt(self: *@This(), ciphertext: []u8) void {
    for (ciphertext) |*byte| {
        const stream_byte = keystream(self.dec_register, self.cipher);
        feedback(&self.dec_register, byte.*);
        byte.* ^= stream_byte;
    }
}

fn keystream(register: [16]u8, cipher: std.crypto.core.aes.AesEncryptCtx(Aes128)) u8 {
    var block: [16]u8 = undefined;
    cipher.encrypt(&block, &register);
    return block[0];
}

fn feedback(register: *[16]u8, byte: u8) void {
    @memmove(register[0..15], register[1..16]);
    register[15] = byte;
}

test "AES-128-CFB8 NIST SP 800-38A vector" {
    const key = hexToArray("2b7e151628aed2a6abf7158809cf4f3c");
    const iv = hexToArray("000102030405060708090a0b0c0d0e0f");
    const plaintext = hexToArray("6bc1bee22e409f96e93d7e117393172a" ++
        "ae2d8a571e03ac9c9eb76fac45af8e51" ++
        "30c81c46a35ce411e5fbc1191a0a52ef" ++
        "f69f2445df4f9b17ad2b417be66c3710");
    const expected_ciphertext = hexToArray("3b79424c9c0dd436bace9e0ed4586a4f" ++
        "32b9ded50ae3ba69d472e88267fb5052" ++
        "70cbad1e257691f7c47c5038297edda3" ++
        "2ff26d0ed19174096161ecc14086dd62");

    var ciphertext = plaintext;
    var stream: @This() = .initWithIv(key, iv);
    stream.encrypt(&ciphertext);
    try std.testing.expectEqualSlices(u8, &expected_ciphertext, &ciphertext);

    var decrypted = ciphertext;
    stream.decrypt(&decrypted);
    try std.testing.expectEqualSlices(u8, &plaintext, &decrypted);
}

test "state survives chunked calls" {
    const key = hexToArray("2b7e151628aed2a6abf7158809cf4f3c");
    const iv = hexToArray("000102030405060708090a0b0c0d0e0f");
    const plaintext = hexToArray(
        "6bc1bee22e409f96e93d7e117393172a" ++
            "ae2d8a571e03ac9c9eb76fac45af8e51" ++
            "30c81c46a35ce411e5fbc1191a0a52ef" ++
            "f69f2445df4f9b17ad2b417be66c3710",
    );
    const expected_ciphertext = hexToArray(
        "3b79424c9c0dd436bace9e0ed4586a4f" ++
            "32b9ded50ae3ba69d472e88267fb5052" ++
            "70cbad1e257691f7c47c5038297edda3" ++
            "2ff26d0ed19174096161ecc14086dd62",
    );

    var ciphertext = plaintext;
    var enc: @This() = .initWithIv(key, iv);
    enc.encrypt(ciphertext[0..7]);
    enc.encrypt(ciphertext[7..31]);
    enc.encrypt(ciphertext[31..]);
    try std.testing.expectEqualSlices(u8, &expected_ciphertext, &ciphertext);
}

test "init uses the key as the IV" {
    const key = hexToArray("2b7e151628aed2a6abf7158809cf4f3c");
    const plaintext = hexToArray("6bc1bee22e409f96e93d7e117393172a");

    var a = plaintext;
    var b = plaintext;
    var key_iv: @This() = .init(key);
    var explicit_iv: @This() = .initWithIv(key, key);
    key_iv.encrypt(&a);
    explicit_iv.encrypt(&b);

    try std.testing.expectEqualSlices(u8, &a, &b);
}

test "cipher is unchanged" {
    const key = hexToArray("2b7e151628aed2a6abf7158809cf4f3c");
    var plaintext = hexToArray("6bc1bee22e409f96e93d7e117393172a");

    var enc: @This() = .init(key);
    const initial_cipher_state = enc.cipher;

    enc.encrypt(&plaintext);

    try std.testing.expectEqual(initial_cipher_state, enc.cipher);
}

inline fn hexToArray(text: []const u8) [@divExact(text.len, 2)]u8 {
    var out: [@divExact(text.len, 2)]u8 = undefined;
    _ = std.fmt.hexToBytes(&out, text) catch unreachable;
    return out;
}

const std = @import("std");

const Aes128 = std.crypto.core.aes.Aes128;
