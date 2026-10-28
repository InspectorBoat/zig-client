reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .reason = try buffer.readStringNonAllocating(32768),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    connection.wants_disconnect.store(true, .release);

    std.log.err("failed to log in: {s}", .{self.reason});
}

const std = @import("std");

const main = @import("main");

const Connection = main.network.Connection;
const S2C = main.network.packet.S2C;
