const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

time_millis: i32,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeVarInt(self.time_millis);
}
