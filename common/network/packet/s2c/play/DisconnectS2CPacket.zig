const std = @import("std");
const Connection = @import("../../../connection.zig").Connection;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    connection.disconnected.* = true;
    _ = self;
}
