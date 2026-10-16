const main = @import("main");
const Entity = main.Entity;
const Vector3 = main.Vector3;
const Rotation2 = main.Rotation2;

base: Entity.Base,
living: Entity.LivingBase,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

pub fn initLiving(network_id: i32, pos: Vector3(f64), rotation: Rotation2(f32)) @This() {
    return .{ .base = .initRotation(network_id, pos, rotation), .living = .{} };
}
