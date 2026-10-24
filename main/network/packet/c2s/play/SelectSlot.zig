slot: i16,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot);
}

const main = @import("main");

const C2S = main.network.packet.C2S;
