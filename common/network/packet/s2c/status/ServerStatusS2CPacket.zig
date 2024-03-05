const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

pub fn decode(self: @This(), buffer: *WritePacketBuffer) !void {
    _ = self;
    _ = buffer;
}
