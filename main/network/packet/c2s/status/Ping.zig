const root = @import("root");
const C2S = root.network.packet.C2S;

time: i64,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    _ = self;
    _ = buffer;
}
