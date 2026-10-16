const main = @import("main");
const Uuid = @import("util").Uuid;

const C2S = main.network.packet.C2S;

targetUuid: Uuid,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeUuid(self.targetUuid);
}
