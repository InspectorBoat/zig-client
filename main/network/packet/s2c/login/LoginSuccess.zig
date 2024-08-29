const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Connection = @import("../../../../network/connection.zig").Connection;
const Uuid = @import("../../../../entity/Uuid.zig");

uuid: Uuid,
name: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
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
