const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .reason = try buffer.readStringAllocating(allocator, 32767),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    connection.wants_disconnect.store(true, .release);
    _ = self;
}
