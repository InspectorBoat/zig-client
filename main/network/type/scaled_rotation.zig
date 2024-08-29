const Rotation2 = @import("../../math/rotation.zig").Rotation2;

pub fn ScaledRotation(comptime Element: type, comptime Factor: comptime_float) type {
    return struct {
        yaw: Element,
        pitch: Element,

        pub fn normalize(self: @This()) Rotation2(f32) {
            return .{
                .yaw = @as(f32, @floatFromInt(self.yaw)) / @as(f32, Factor),
                .pitch = @as(f32, @floatFromInt(self.pitch)) / @as(f32, Factor),
            };
        }
    };
}
