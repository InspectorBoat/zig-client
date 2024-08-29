const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;

time: i64,

pub fn decode(self: @This(), buffer: *S2C.ReadBuffer) !void {
    _ = self;
    _ = buffer;
}
