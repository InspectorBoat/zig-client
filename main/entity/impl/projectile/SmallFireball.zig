const root = @import("root");
const Entity = root.Entity;
const Vector3 = root.Vector3;

base: Entity.Base,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}
