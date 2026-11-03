pub fn floor(x: f32) i32 {
    return if (x >= -0x1p31 and x < 0x1p31)
        @floor(x)
    else if (std.math.isNan(x))
        0
    else
        std.math.maxInt(i32);
}

const std = @import("std");

pub const MathHelper = @import("llm-code-quarantine").MathHelper;

pub const Box = @import("box.zig").Box;
pub const Direction = @import("direction.zig").Direction;
pub const HitResult = @import("hitresult.zig").HitResult;
pub const HitType = @import("hitresult.zig").HitType;
pub const Rotation2 = @import("rotation.zig").Rotation2;
pub const Rotation3 = @import("rotation.zig").Rotation3;
pub const Vector2xy = @import("vector.zig").Vector2xy;
pub const Vector2xz = @import("vector.zig").Vector2xz;
pub const Vector3 = @import("vector.zig").Vector3;
