const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

slot: i16,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.write(i16, self.slot);
}
