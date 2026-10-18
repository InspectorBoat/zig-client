const std = @import("std");

const main = @import("main");

const Connection = main.network.Connection;
const S2C = main.network.packet.S2C;

time_millis: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .time_millis = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, server_connection: *Connection) !void {
    std.log.scoped(.keepalive).debug("keepalive with id {}", .{self.time_millis});
    _ = io;
    _ = server_connection;
    // try server_connection.sendPlayPacket(io, .{ .keep_alive = .{ .time_millis = self.time_millis } });
}
