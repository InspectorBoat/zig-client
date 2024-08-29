const root = @import("root");
const Vector3 = root.Vector3;
const Entity = root.Entity;

base: Entity.Base,
interpolator: Entity.InterpolatedBase = undefined,

pub fn init(pos: Vector3(f64)) @This() {
    return .{ .base = .{
        .pos = pos,
        .prev_pos = pos,
    } };
}
