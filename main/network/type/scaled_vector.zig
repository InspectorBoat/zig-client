const std = @import("std");
const root = @import("root");
const Vector3 = root.Vector3;

pub fn ScaledVector(comptime Element: type, comptime Factor: comptime_float) type {
    switch (@typeInfo(Element)) {
        .int, .float => {},
        else => @compileError("Element must be integer or float type, found " ++ @typeName(Element)),
    }
    return struct {
        x: Element,
        y: Element,
        z: Element,

        pub fn normalize(self: @This()) Vector3(f64) {
            return switch (@typeInfo(Element)) {
                .int => .{
                    .x = @as(f64, @floatFromInt(self.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatFromInt(self.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatFromInt(self.z)) / @as(f64, Factor),
                },
                .float => .{
                    .x = @as(f64, @floatCast(self.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatCast(self.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatCast(self.z)) / @as(f64, Factor),
                },
                else => unreachable,
            };
        }
    };
}
