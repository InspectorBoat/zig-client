const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Vector3 = @import("../../../../math/vector.zig").Vector3;

command: []const u8,
block_pos: ?Vector3(i32),

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeString(self.command);
    try buffer.write(bool, self.block_pos != null);
    if (self.block_pos) |block_pos| {
        try buffer.writeBlockPos(block_pos);
    }
}
