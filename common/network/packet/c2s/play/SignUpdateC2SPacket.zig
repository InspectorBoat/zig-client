const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Vector3 = @import("../../../../type/vector.zig").Vector3;

block_pos: Vector3(i32),
lines: [][]const u8,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines) |line| {
        try buffer.writeString(line);
    }
}
