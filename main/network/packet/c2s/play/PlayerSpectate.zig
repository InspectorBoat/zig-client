const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const Uuid = @import("util").Uuid;

targetUuid: Uuid,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeUuid(self.targetUuid);
}
