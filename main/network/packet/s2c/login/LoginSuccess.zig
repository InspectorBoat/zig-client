uuid: Uuid,
name: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .uuid = try .fromAscii(try buffer.readString(36)),
        .name = try buffer.allocString(allocator, 16),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    _ = self;
    std.debug.assert(connection.protocol == .login);
    connection.switchProtocol(.play);
}

const std = @import("std");

const main = @import("main");

const network = main.network;
const Connection = network.Connection;
const Uuid = network.Uuid;
const S2C = network.packet.S2C;
