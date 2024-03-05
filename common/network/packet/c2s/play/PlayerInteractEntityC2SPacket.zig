const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Vector3 = @import("../../../../type/vector.zig").Vector3;

target_network_id: i32,
action: Action,
offset: ?Vector3(f64),

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeVarInt(self.target_network_id);
    try buffer.writeEnum(Action, self.action);
    if (self.action == .InteractAt) {
        try buffer.write(f32, @floatCast(self.offset.?.x));
        try buffer.write(f32, @floatCast(self.offset.?.y));
        try buffer.write(f32, @floatCast(self.offset.?.z));
    }
}

pub const Action = enum(i32) {
    Interact = 0,
    Attack = 1,
    InteractAt = 2,
};
