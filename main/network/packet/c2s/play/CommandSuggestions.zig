command: []const u8,
block_pos: ?Vector3(i32),

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.command);
    try buffer.write(bool, self.block_pos != null);
    if (self.block_pos) |block_pos| {
        try buffer.writeBlockPos(block_pos);
    }
}

const main = @import("main");

const Vector3 = main.Vector3;
const C2S = main.network.packet.C2S;
