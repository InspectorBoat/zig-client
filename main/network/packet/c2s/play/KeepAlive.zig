const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

time_millis: i32,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeVarInt(self.time_millis);
}
