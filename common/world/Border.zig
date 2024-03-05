pub const Vector3 = @import("../type/vector.zig").Vector3;

center_pos: Vector3(f64),
size: f64,
size_lerp_target: f64,
size_change_start: i64,
size_change_end: i64,
max_size: i32,
