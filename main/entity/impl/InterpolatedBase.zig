const root = @import("root");
const Vector3 = root.Vector3;
const Rotation2 = root.Rotation2;
const MathHelper = root.MathHelper;
const Base = @import("Base.zig");
const std = @import("std");

interpolation_steps: i32 = 0,
target_position: Vector3(f64) = .origin(),
target_rotation: Rotation2(f32) = .origin(),

pub fn tick(self: *@This(), base: *Base) void {
    if (self.interpolation_steps > 0) {
        const steps: f64 = self.interpolation_steps;
        const new_pos = base.pos.add(self.target_position.sub(base.pos).div(.splat(steps)));
        const delta_yaw = MathHelper.wrapDegrees(@floatCast(self.target_rotation.yaw - base.rotation.yaw));
        base.rotation = .{
            .yaw = base.rotation.yaw + @as(f32, @floatCast(delta_yaw / steps)),
            .pitch = base.rotation.pitch + @as(f32, @floatCast((self.target_rotation.pitch - base.rotation.pitch) / steps)),
        };
        self.interpolation_steps -= 1;
        base.setPosition(new_pos);
        base.setRotation(base.rotation);
    } else {
        base.velocity = base.velocity.mul(.splat(0.98));
    }
}

pub fn beginInterp(self: *@This(), target_pos: Vector3(f64), target_rotation: Rotation2(f32), interpolation_steps: i32) void {
    self.target_position = target_pos;
    self.target_rotation = target_rotation;
    self.interpolation_steps = interpolation_steps;
}
