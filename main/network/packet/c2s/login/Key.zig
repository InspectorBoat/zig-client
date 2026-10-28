shared_secret: []const u8,
nonce: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeByteSlice(self.shared_secret);
    try buffer.writeByteSlice(self.nonce);
}

const main = @import("main");

const C2S = main.network.packet.C2S;
