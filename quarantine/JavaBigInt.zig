//! Java-compatible BigInteger hex formatting.
//!
//! Minecraft hashes the login key material with SHA-1, then converts the digest
//! with `new BigInteger(digest).toString(16)`. Java treats the digest as a
//! signed, big-endian two's-complement integer, so the result can start with
//! `-` and leading zero digits are omitted.

pub const Error = error{
    EmptyInteger,
    OutputTooSmall,
};

/// Equivalent to Java's `new BigInteger(bytes).toString(16)`.
///
/// `bytes` is interpreted as a signed, big-endian two's-complement integer.
/// Returns a slice of `out` containing lowercase hex.
pub fn toString16(out: []u8, bytes: []const u8) Error![]const u8 {
    if (bytes.len == 0) return error.EmptyInteger;

    if (bytes[0] & 0x80 == 0) {
        return positiveToString16(out, bytes);
    }
    return negativeToString16(out, bytes);
}

fn positiveToString16(out: []u8, bytes: []const u8) Error![]const u8 {
    var start: usize = 0;
    while (start < bytes.len and bytes[start] == 0) : (start += 1) {}

    if (start == bytes.len) {
        if (out.len < 1) return error.OutputTooSmall;
        out[0] = '0';
        return out[0..1];
    }

    const first = bytes[start];
    const needed = hexDigitsForByte(first) + 2 * (bytes.len - start - 1);
    if (out.len < needed) return error.OutputTooSmall;

    var pos = writeFirstByte(out, 0, first);
    for (bytes[start + 1 ..]) |byte| {
        pos = writeByte(out, pos, byte);
    }
    return out[0..pos];
}

fn negativeToString16(out: []u8, bytes: []const u8) Error![]const u8 {
    // The absolute value is `~bytes + 1`. The carry from the `+1` propagates
    // through trailing zero bytes, so the last non-zero byte is where it stops.
    var stop: usize = bytes.len - 1;
    while (bytes[stop] == 0) : (stop -= 1) {
        // bytes[0] has its high bit set, so this cannot underflow.
    }

    // Strip leading zero bytes from the absolute value.
    var start: usize = 0;
    while (start < stop and absoluteByte(bytes, stop, start) == 0) : (start += 1) {}

    const first = absoluteByte(bytes, stop, start);
    const needed = 1 + hexDigitsForByte(first) + 2 * (bytes.len - start - 1);
    if (out.len < needed) return error.OutputTooSmall;

    out[0] = '-';
    var pos = writeFirstByte(out, 1, first);
    var i = start + 1;
    while (i < bytes.len) : (i += 1) {
        pos = writeByte(out, pos, absoluteByte(bytes, stop, i));
    }
    return out[0..pos];
}

fn hexDigitsForByte(byte: u8) usize {
    return if (byte < 0x10) 1 else 2;
}

fn writeFirstByte(out: []u8, pos: usize, byte: u8) usize {
    if (byte < 0x10) {
        out[pos] = hex_digits[byte];
        return pos + 1;
    }
    out[pos] = hex_digits[byte >> 4];
    out[pos + 1] = hex_digits[byte & 0x0f];
    return pos + 2;
}

fn writeByte(out: []u8, pos: usize, byte: u8) usize {
    out[pos] = hex_digits[byte >> 4];
    out[pos + 1] = hex_digits[byte & 0x0f];
    return pos + 2;
}

fn absoluteByte(bytes: []const u8, stop: usize, i: usize) u8 {
    if (i < stop) return ~bytes[i];
    if (i == stop) return ~bytes[stop] +% 1;
    return 0;
}

const hex_digits = "0123456789abcdef";

test "matches Java BigInteger.toString(16)" {
    const cases = [_]struct {
        bytes: []const u8,
        expected: []const u8,
    }{
        .{ .bytes = &.{ 0x00, 0x01, 0xab }, .expected = "1ab" },
        .{ .bytes = &.{ 0xff, 0xff }, .expected = "-1" },
        .{ .bytes = &.{ 0x80, 0x00 }, .expected = "-8000" },
        .{ .bytes = &.{ 0x00, 0x00 }, .expected = "0" },
        .{ .bytes = &.{ 0x80, 0x00, 0x00 }, .expected = "-800000" },
        .{ .bytes = &.{ 0x7f, 0xff }, .expected = "7fff" },
        .{ .bytes = &.{0xff}, .expected = "-1" },
        .{ .bytes = &.{0x80}, .expected = "-80" },
        .{ .bytes = &.{ 0xff, 0x00 }, .expected = "-100" },
        .{ .bytes = &.{ 0x80, 0x01 }, .expected = "-7fff" },
    };

    var buffer: [64]u8 = undefined;
    for (cases) |case| {
        const actual = try toString16(&buffer, case.bytes);
        try std.testing.expectEqualStrings(case.expected, actual);
    }
}

test "20-byte SHA-1-sized values" {
    var buffer: [41]u8 = undefined;

    var all_ff: [20]u8 = @splat(0xff);
    try std.testing.expectEqualStrings("-1", try toString16(&buffer, &all_ff));

    var high_bit: [20]u8 = @splat(0x00);
    high_bit[0] = 0x80;
    const negative_max = try toString16(&buffer, &high_bit);
    var expected_negative: [41]u8 = undefined;
    expected_negative[0] = '-';
    expected_negative[1] = '8';
    @memset(expected_negative[2..], '0');
    try std.testing.expectEqualStrings(&expected_negative, negative_max);

    var positive_max: [20]u8 = @splat(0xff);
    positive_max[0] = 0x7f;
    const positive = try toString16(&buffer, &positive_max);
    var expected_positive: [40]u8 = undefined;
    expected_positive[0] = '7';
    expected_positive[1] = 'f';
    @memset(expected_positive[2..], 'f');
    try std.testing.expectEqualStrings(&expected_positive, positive);
}

test "SHA-1 digest from Java" {
    const digest_hex = "bbe960a25ea311d21d40669e93df2003ba9b90a2";
    var digest: [20]u8 = undefined;
    _ = try std.fmt.hexToBytes(&digest, digest_hex);

    var buffer: [41]u8 = undefined;
    try std.testing.expectEqualStrings(
        "-44169f5da15cee2de2bf99616c20dffc45646f5e",
        try toString16(&buffer, &digest),
    );
}

test "output buffer and empty input errors" {
    var small: [2]u8 = undefined;
    try std.testing.expectError(error.OutputTooSmall, toString16(&small, &.{ 0x01, 0x02 }));

    var buffer: [16]u8 = undefined;
    try std.testing.expectError(error.EmptyInteger, toString16(&buffer, &.{}));
}

const std = @import("std");
