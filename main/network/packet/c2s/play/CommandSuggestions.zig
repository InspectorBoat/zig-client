const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Vector3 = root.Vector3;

command: []const u8,
block_pos: ?Vector3(i32),

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.command);
    try buffer.write(bool, self.block_pos != null);
    if (self.block_pos) |block_pos| {
        try buffer.writeBlockPos(block_pos);
    }
}
