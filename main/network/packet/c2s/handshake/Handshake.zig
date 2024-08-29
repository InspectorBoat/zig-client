const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

comptime id: i32 = 0,

version: i32,
address: []const u8,
port: i16,
protocol_id: i32,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeVarInt(self.version);
    try buffer.writeString(self.address);
    try buffer.write(i16, self.port);
    try buffer.writeVarInt(self.protocol_id);
}
