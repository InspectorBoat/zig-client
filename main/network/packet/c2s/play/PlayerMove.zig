const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Rotation2 = root.Rotation2;
const Vector3 = root.Vector3;

on_ground: bool,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(bool, self.on_ground);
}

pub const Angles = struct {
    rotation: Rotation2(f32),
    on_ground: bool,

    pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
        try buffer.write(f32, self.rotation.yaw);
        try buffer.write(f32, self.rotation.pitch);

        try buffer.write(bool, self.on_ground);
    }
};

pub const Position = struct {
    pos: Vector3(f64),
    on_ground: bool,

    pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
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

    pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
        try buffer.write(f64, self.pos.x);
        try buffer.write(f64, self.pos.y);
        try buffer.write(f64, self.pos.z);

        try buffer.write(f32, self.rotation.yaw);
        try buffer.write(f32, self.rotation.pitch);

        try buffer.write(bool, self.on_ground);
    }
};
