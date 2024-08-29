const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Vector3 = root.Vector3;

block_pos: Vector3(i32),
lines: [][]const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines) |line| {
        try buffer.writeString(line);
    }
}
