const main = @import("main");

const Vector3 = main.Vector3;
const C2S = main.network.packet.C2S;

block_pos: Vector3(i32),
lines: [][]const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines) |line| {
        try buffer.writeString(line);
    }
}
