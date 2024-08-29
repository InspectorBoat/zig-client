const root = @import("root");
const c2s = root.network.packet.c2s;

comptime id: i32 = 0,

version: i32,
address: []const u8,
port: i16,
protocol_id: i32,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeVarInt(self.version);
    try buffer.writeString(self.address);
    try buffer.write(i16, self.port);
    try buffer.writeVarInt(self.protocol_id);
}
