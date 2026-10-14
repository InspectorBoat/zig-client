const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .reason = try buffer.readStringAllocating(32767, allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection, io: std.Io) !void {
    _ = io;

    connection.wants_disconnect.store(true, .release);
    _ = self;
}
