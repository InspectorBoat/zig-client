const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;

time: i64,

pub fn decode(self: @This(), buffer: *s2c.ReadBuffer) !void {
    _ = self;
    _ = buffer;
}
