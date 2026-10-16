const main = @import("main");

const S2C = main.network.packet.S2C;

pub fn decode(self: @This(), buffer: *S2C.ReadBuffer) !void {
    _ = self;
    _ = buffer;
}
