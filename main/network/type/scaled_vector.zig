const main = @import("main");

const Vector3 = main.Vector3;

pub fn ScaledVector(comptime Element: type, comptime Factor: comptime_float) type {
    switch (@typeInfo(Element)) {
        .int, .float => {},
        else => @compileError("Element must be integer or float type, found " ++ @typeName(Element)),
    }
    return struct {
        raw: Vector3(Element),

        pub fn normalize(self: @This()) Vector3(f64) {
            return switch (@typeInfo(Element)) {
                .int => .{
                    .x = @as(f64, @floatFromInt(self.raw.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatFromInt(self.raw.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatFromInt(self.raw.z)) / @as(f64, Factor),
                },
                .float => .{
                    .x = @as(f64, @floatCast(self.raw.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatCast(self.raw.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatCast(self.raw.z)) / @as(f64, Factor),
                },
                else => unreachable,
            };
        }
    };
}
