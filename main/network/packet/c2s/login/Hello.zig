player_name: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.player_name);
}

const main = @import("main");

const C2S = main.network.packet.C2S;
