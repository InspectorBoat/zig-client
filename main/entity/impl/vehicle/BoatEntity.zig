const EntityBase = @import("../EntityBase.zig");
const InterpolatedEntityBase = @import("../InterpolatedEntityBase.zig");
const Vector3 = @import("../../../math/vector.zig").Vector3;

base: EntityBase,
interpolator: InterpolatedEntityBase = undefined,

pub fn init(pos: Vector3(f64)) @This() {
    return .{ .base = .{
        .pos = pos,
        .prev_pos = pos,
    } };
}
