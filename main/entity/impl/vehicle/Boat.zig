const root = @import("root");
const Vector3 = root.Vector3;
const entity = root.entity;

base: entity.Base,
interpolator: entity.InterpolatedBase = undefined,

pub fn init(pos: Vector3(f64)) @This() {
    return .{ .base = .{
        .pos = pos,
        .prev_pos = pos,
    } };
}
