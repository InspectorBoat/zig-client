channel: []const u8,
data: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.channel);
    if (self.data.len > 32767) return error.CustomPayloadTooLarge;
    try buffer.writeBytes(self.data);
}

const main = @import("main");

const C2S = main.network.packet.C2S;
