/// Usually unused, but can be up to 20 bytes of Latin-1 encoded text.
/// Only used as part of the hash used for authentication.
key: []const u8,
/// The server's public RSA key
public_key: []const u8,
/// Prevents replay attacks
nonce: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .key = try buffer.readStringAllocating(allocator, 20),
        .public_key = try buffer.readByteSliceAllocating(allocator),
        .nonce = try buffer.readByteSliceAllocating(allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    var shared_secret: [16]u8 = undefined;
    try io.randomSecure(&shared_secret);

    var client: std.http.Client = .{
        .allocator = connection.incoming_allocator.allocator(),
        .io = io,
    };
    defer client.deinit();

    const session_verification = try client.fetch(.{
        .location = .{ .url = "https://sessionserver.mojang.com/session/minecraft/join" },
        .method = .POST,
        .payload = try connection.incoming_allocator.allocator().print(
            \\{{
            \\  "accessToken": "{s}",
            \\  "selectedProfile": "{s}",
            \\  "serverId": "{x}"
            \\}}
        , .{
            connection.session.access_token,
            connection.session.uuid,
            toInt(computeDigest(self.key, shared_secret, self.public_key)),
        }),
        .headers = .{ .content_type = .{ .override = "application/json" } },
        .keep_alive = false,
    });
    if (session_verification.status != .no_content) return error.AuthFailed;

    const public_key = try quarantine.rsa.parsePublicKey(self.public_key);

    var secret_buf: [1024]u8 = undefined;
    var nonce_buf: [1024]u8 = undefined;

    const encrypted_secret = secret_buf[0..try quarantine.rsa.encryptWithKey(io, public_key, &shared_secret, &secret_buf)];
    const encrypted_nonce = nonce_buf[0..try quarantine.rsa.encryptWithKey(io, public_key, self.nonce, &nonce_buf)];

    try connection.sendLoginPacket(io, .{ .key = .{
        .shared_secret = encrypted_secret,
        .nonce = encrypted_nonce,
    } });

    // Set up encryption **after** we send the response. Otherwise we
    // would send an AES-encrypted packet that the server can't read.
    connection.setupEncryption(shared_secret);
}

pub fn computeDigest(key: []const u8, shared_secret: [16]u8, public_key: []const u8) [20]u8 {
    var sha: std.crypto.hash.Sha1 = .init(.{});

    // TODO: needs a utf-8 -> latin-1 round-trip... ughhhh
    if (key.len != 0) {
        std.debug.panic("TODO!", .{});
        // sha.update(self.key);
    }

    sha.update(&shared_secret);

    // argh....
    // vanilla does a round trip (parses the public key, then re-encodes it)
    // this can be non-idempotent if server sends a non-canonical key encoding!
    // the vanilla client and server would use the canonical encoding to
    // compute the hash, while we use the wire bytes.
    // TODO: KILL MYSELF
    sha.update(public_key);

    return sha.finalResult();
}

/// Should match new BigInteger(bytes).toString(16) when formatted with {x}
pub fn toInt(bytes: anytype) @Int(.signed, bytes.len * 8) {
    const Int = @Int(.signed, bytes.len * 8);
    const as_int: Int = @bitCast(bytes);
    const swapped: Int = @byteSwap(as_int);
    return swapped;
}

test toInt {
    const TestCase = struct {
        bytes: []const u8,
        expected: []const u8,
    };

    const cases: []const TestCase = &.{
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
    inline for (cases) |case| {
        try std.testing.expectEqualStrings(
            case.expected,
            try std.mem.print(&buffer, "{x}", .{toInt(case.bytes.*)}),
        );
    }
}

test "20-byte values" {
    var buffer: [41]u8 = undefined;

    {
        const neg_one: [20]u8 = @splat(0xff);
        const expected = "-1";
        try std.testing.expectEqualStrings(
            expected,
            try std.mem.print(&buffer, "{x}", .{toInt(neg_one)}),
        );
    }

    {
        const min_value = .{0x80} ++ @as([19]u8, @splat(0x00));
        const expected: [41]u8 = .{ '-', '8' } ++ @as([39]u8, @splat('0'));
        try std.testing.expectEqualStrings(
            &expected,
            try std.mem.print(&buffer, "{x}", .{toInt(min_value)}),
        );
    }
    {
        const max_value: [20]u8 = .{0x7f} ++ @as([19]u8, @splat(0xff));
        const expected: [40]u8 = .{ '7', 'f' } ++ @as([38]u8, @splat('f'));
        try std.testing.expectEqualStrings(
            &expected,
            try std.mem.print(&buffer, "{x}", .{toInt(max_value)}),
        );
    }
}

test "SHA-1 digest" {
    const digest_hex = "bbe960a25ea311d21d40669e93df2003ba9b90a2";
    var digest: [20]u8 = undefined;
    _ = try std.fmt.hexToBytes(&digest, digest_hex);

    var buffer: [41]u8 = undefined;
    try std.testing.expectEqualStrings(
        "-44169f5da15cee2de2bf99616c20dffc45646f5e",
        try std.mem.print(&buffer, "{x}", .{toInt(digest)}),
    );
}

const std = @import("std");

const quarantine = @import("llm-code-quarantine");
const main = @import("main");

const Connection = main.network.Connection;
const S2C = main.network.packet.S2C;
