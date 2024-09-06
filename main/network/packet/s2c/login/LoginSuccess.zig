const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;
const Client = root.Client;
const Uuid = @import("util").Uuid;

uuid: Uuid,
name: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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
