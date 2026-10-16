const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;
const Vector3 = main.Vector3;

block_pos: Vector3(i32),
lines: [][]const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines) |line| {
        try buffer.writeString(line);
    }
}
