const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;
const Uuid = @import("util").Uuid;

targetUuid: Uuid,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeUuid(self.targetUuid);
}
