const root = @import("root");
const C2S = root.network.packet.C2S;

player_name: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.player_name);
}
