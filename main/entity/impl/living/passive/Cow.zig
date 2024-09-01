const root = @import("root");
const Entity = root.Entity;
const Vector3 = root.Vector3;
const Rotation2 = root.Rotation2;

base: Entity.Base,
living: Entity.LivingBase,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = Entity.Base.init(network_id, pos) };
}

pub fn initLiving(network_id: i32, pos: Vector3(f64), rotation: Rotation2(f32), head_yaw: f32) @This() {
    return .{ .base = Entity.Base.initRotation(network_id, pos, rotation), .living = .{ .head_yaw = head_yaw } };
}
