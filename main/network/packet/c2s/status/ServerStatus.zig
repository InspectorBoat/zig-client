const main = @import("main");

const C2S = main.network.packet.C2S;

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    _ = self;
    _ = buffer;
}
