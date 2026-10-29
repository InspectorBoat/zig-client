key: []const u8,
public_key: []const u8,
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

    var sha: std.crypto.hash.Sha1 = .init(.{});

    // TODO: needs a utf-8 -> latin-1 round-trip... ughhhh
    // sha.update(self.key);

    sha.update(&shared_secret);

    // argh....
    // vanilla does a round trip (parses the public key, then re-encodes it)
    // this can be non-idempotent if server sends a non-canonical key encoding!
    // the vanilla client and server would use the canonical encoding to
    // compute the hash, while we use the wire bytes.
    // TODO: KILL MYSELF
    sha.update(self.public_key);

    const hash = sha.finalResult();
    comptime std.debug.assert(hash.len == 20);

    var encoded_hash_buf: [41]u8 = undefined;

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
            \\  "serverId": "{s}"
            \\}}
        , .{
            connection.session.access_token,
            connection.session.uuid,
            try quarantine.JavaBigInt.toString16(&encoded_hash_buf, &hash),
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

const std = @import("std");

const quarantine = @import("llm-code-quarantine");
const main = @import("main");

const Connection = main.network.Connection;
const S2C = main.network.packet.S2C;
