const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

player_name: []const u8,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeString(self.player_name);
}
