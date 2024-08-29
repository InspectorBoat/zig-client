const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Connection = root.network.Connection;
const Game = root.Game;
const Uuid = @import("util").Uuid;

uuid: Uuid,
name: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .uuid = try Uuid.fromAscii(try buffer.readStringNonAllocating(36)),
        .name = try buffer.readStringAllocating(16, allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    _ = self;
    std.debug.assert(connection.protocol == .Login);
    connection.switchProtocol(.Play);
}
