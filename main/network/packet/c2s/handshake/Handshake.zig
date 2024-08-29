const root = @import("root");
const C2S = root.network.packet.C2S;

comptime id: i32 = 0,

version: i32,
address: []const u8,
port: i16,
protocol_id: i32,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeVarInt(self.version);
    try buffer.writeString(self.address);
    try buffer.write(i16, self.port);
    try buffer.writeVarInt(self.protocol_id);
}
