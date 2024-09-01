const root = @import("root");
const Vector3 = root.Vector3;
const Entity = root.Entity;

base: Entity.Base,
interpolator: Entity.InterpolatedBase = undefined,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = Entity.Base.init(network_id, pos) };
}
