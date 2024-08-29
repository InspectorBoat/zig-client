const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Connection = root.network.Connection;

time_millis: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .time_millis = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), server_connection: *Connection) !void {
    try server_connection.sendPlayPacket(.{ .KeepAlive = .{ .time_millis = self.time_millis } });
}
