const Vector3 = @import("../../math/vector.zig").Vector3;
const Rotation2 = @import("../../math/rotation.zig").Rotation2;

interpolation_steps: usize,
server_pos: Vector3(f64),
server_rotation: Rotation2(f32),
