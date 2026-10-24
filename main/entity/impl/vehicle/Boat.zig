base: Entity.Base,
interpolator: Entity.InterpolatedBase = undefined,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

const main = @import("main");

const Entity = main.Entity;
const Vector3 = main.Vector3;
