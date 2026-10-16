const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    _ = self;
    _ = buffer;
}
