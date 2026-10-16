const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;

time: i64,

pub fn decode(self: @This(), buffer: *S2C.ReadBuffer) !void {
    _ = self;
    _ = buffer;
}
