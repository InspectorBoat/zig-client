const root = @import("root");
const c2s = root.network.packet.c2s;

player_name: []const u8,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeString(self.player_name);
}
