network_id: i32,
action: Action,
data: i32,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeVarInt(self.network_id);
    try buffer.writeEnum(Action, self.action);
    try buffer.writeVarInt(self.data);
}

pub const Action = enum(i32) {
    start_sneaking,
    stop_sneaking,
    stop_sleeping,
    start_sprinting,
    stop_sprinting,
    riding_jump,
    open_horse_inventory,
};

const main = @import("main");

const C2S = main.network.packet.C2S;
