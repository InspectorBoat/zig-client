targetUuid: Uuid,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeUuid(self.targetUuid);
}

const main = @import("main");

const network = main.network;
const Uuid = network.Uuid;
const C2S = network.packet.C2S;
