const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const Vector3 = @import("../../../../math/vector.zig").Vector3;

block_pos: Vector3(i32),
lines: [][]const u8,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines) |line| {
        try buffer.writeString(line);
    }
}
