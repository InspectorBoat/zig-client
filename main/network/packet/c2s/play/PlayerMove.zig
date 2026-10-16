const main = @import("main");

const Rotation2 = main.Rotation2;
const Vector3 = main.Vector3;
const C2S = main.network.packet.C2S;

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
