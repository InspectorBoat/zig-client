const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Rotation2 = @import("../../../../math/rotation.zig").Rotation2;
const Vector3 = @import("../../../../math/vector.zig").Vector3;

on_ground: bool,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.write(bool, self.on_ground);
}

pub const Angles = struct {
    rotation: Rotation2(f32),
    on_ground: bool,

    pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.write(f32, self.rotation.yaw);
        try buffer.write(f32, self.rotation.pitch);

        try buffer.write(bool, self.on_ground);
    }
};

pub const Position = struct {
    pos: Vector3(f64),
    on_ground: bool,

    pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.write(f64, self.pos.x);
        try buffer.write(f64, self.pos.y);
        try buffer.write(f64, self.pos.z);

        try buffer.write(bool, self.on_ground);
    }
};

pub const PositionAndAngles = struct {
    pos: Vector3(f64),
    rotation: Rotation2(f32),
    on_ground: bool,

    pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.write(f64, self.pos.x);
        try buffer.write(f64, self.pos.y);
        try buffer.write(f64, self.pos.z);

        try buffer.write(f32, self.rotation.yaw);
        try buffer.write(f32, self.rotation.pitch);

        try buffer.write(bool, self.on_ground);
    }
};
