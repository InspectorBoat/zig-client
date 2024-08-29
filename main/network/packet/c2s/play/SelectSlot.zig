const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

slot: i16,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot);
}
