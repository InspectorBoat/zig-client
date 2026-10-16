const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Connection = main.network.Connection;
const Client = main.Client;
const Uuid = @import("util").Uuid;

uuid: Uuid,
name: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .uuid = try Uuid.fromAscii(try buffer.readStringNonAllocating(36)),
        .name = try buffer.readStringAllocating(allocator, 16),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    _ = self;
    std.debug.assert(connection.protocol == .Login);
    connection.switchProtocol(.Play);
}
