const std = @import("std");
const Vector3 = @import("../../math/vector.zig").Vector3;

pub fn ScaledVector(comptime Element: type, comptime Factor: comptime_float) type {
    switch (@typeInfo(Element)) {
        .Int, .Float => {},
        else => @compileError("Element must be integer or float type, found " ++ @typeName(Element)),
    }
    return struct {
        x: Element,
        y: Element,
        z: Element,

        pub fn normalize(self: @This()) Vector3(f64) {
            return switch (@typeInfo(Element)) {
                .Int => Vector3(f64){
                    .x = @as(f64, @floatFromInt(self.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatFromInt(self.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatFromInt(self.z)) / @as(f64, Factor),
                },
                .Float => Vector3(f64){
                    .x = @as(f64, @floatCast(self.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatCast(self.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatCast(self.z)) / @as(f64, Factor),
                },
                else => unreachable,
            };
        }
    };
}
