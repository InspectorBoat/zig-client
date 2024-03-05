const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const KeepAliveC2SPacket = @import("../../../../network/packet/c2s/play/KeepAliveC2SPacket.zig");
const Connection = @import("../../../../network/connection.zig").Connection;

time_millis: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .time_millis = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), server_connection: *Connection) !void {
    try server_connection.sendPlayPacket(.{ .KeepAlive = .{ .time_millis = self.time_millis } });
}
