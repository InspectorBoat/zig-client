const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Vector3 = root.Vector3;

target_network_id: i32,
action: Action,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeVarInt(self.target_network_id);
    try buffer.writeEnum(std.meta.Tag(Action), self.action);
    if (self.action == .interact_at) {
        try buffer.write(f32, @floatCast(self.action.interact_at.x));
        try buffer.write(f32, @floatCast(self.action.interact_at.y));
        try buffer.write(f32, @floatCast(self.action.interact_at.z));
    }
}

pub const Action = union(enum(i32)) {
    interact = 0,
    attack = 1,
    interact_at: Vector3(f64) = 2,
};
