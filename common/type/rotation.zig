const std = @import("std");
pub fn Rotation2(comptime Element: type) type {
    return struct {
        yaw: Element,
        pitch: Element,

        pub fn origin() @This() {
            return @This(){
                .yaw = 0,
                .pitch = 0,
            };
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{{ yaw: {d} pitch: {d} }}", .{
                self.yaw,
                self.pitch,
            });
        }
    };
}

pub fn Rotation3(comptime Element: type) type {
    return struct {
        yaw: Element,
        pitch: Element,
        roll: Element,

        pub fn origin() @This() {
            return @This(){
                .yaw = 0,
                .pitch = 0,
                .roll = 0,
            };
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{{ yaw: {d} pitch: {d} roll: {d} }}", .{
                self.yaw,
                self.pitch,
                self.roll,
            });
        }
    };
}
