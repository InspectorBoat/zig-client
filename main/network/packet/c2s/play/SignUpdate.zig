block_pos: Vector3(i32),
/// Text is stored inline so queued packets never point at a screen's stack memory.
lines: [4][384]u8 = undefined,
lens: [4]usize = .{ 0, 0, 0, 0 },

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    for (self.lines, self.lens) |line, len| {
        // Vanilla sends a serialized Text component, i.e. {"text":"..."} for a
        // plain line. Escape the JSON metacharacters a player can type.
        try buffer.writeBytes("{\"text\":\"");
        for (line[0..len], 0..) |c, i| switch (c) {
            '"' => try buffer.writeBytes("\\\""),
            '\\' => try buffer.writeBytes("\\\\"),
            '\n' => try buffer.writeBytes("\\n"),
            '\r' => try buffer.writeBytes("\\r"),
            '\t' => try buffer.writeBytes("\\t"),
            else => try buffer.writeBytes(line[i .. i + 1]),
        };
        try buffer.writeBytes("\"}");
    }
}

const main = @import("main");

const Vector3 = main.Vector3;
const C2S = main.network.packet.C2S;
