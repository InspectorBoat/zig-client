const Rotation2 = @import("../../type/rotation.zig").Rotation2;

pub fn ScaledRotation(comptime Element: type, comptime Factor: comptime_float) type {
    return struct {
        yaw: Element,
        pitch: Element,

        pub fn normalize(self: @This()) Rotation2(f64) {
            return Rotation2(f64){
                .yaw = @as(f64, self.yaw) / @as(f64, Factor),
                .pitch = @as(f64, self.pitch) / @as(f64, Factor),
            };
        }
    };
}
