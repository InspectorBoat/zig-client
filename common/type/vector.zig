const std = @import("std");

pub fn Vector2(comptime Element: type) type {
    return struct {
        x: Element,
        z: Element,

        pub fn origin() @This() {
            return @This(){
                .x = 0,
                .z = 0,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x + other.x,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x - other.x,
                .z = self.z - other.z,
            };
        }
        pub fn scaleUniform(self: @This(), factor: Element) @This() {
            return @This(){
                .x = self.x * factor,
                .z = self.z * factor,
            };
        }

        pub fn negate(self: @This()) @This() {
            return @This(){
                .x = -self.x,
                .z = -self.z,
            };
        }

        pub fn magnitude_squared(self: @This()) Element {
            return self.x * self.x + self.z * self.z;
        }

        pub fn magnitude(self: @This()) Element {
            return @sqrt(self.x * self.x + self.z * self.z);
        }

        pub fn distance_squared(self: @This(), other: @This()) Element {
            const delta = other.sub(self);
            return delta.x * delta.x + delta.z * delta.z;
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{{ x: {d} z: {d} }}", .{
                self.x,
                self.z,
            });
        }
    };
}

pub fn Vector3(comptime Element: type) type {
    return struct {
        x: Element,
        y: Element,
        z: Element,

        pub fn origin() @This() {
            return @This(){
                .x = 0,
                .y = 0,
                .z = 0,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub fn scaleUniform(self: @This(), factor: Element) @This() {
            return @This(){
                .x = self.x * factor,
                .y = self.y * factor,
                .z = self.z * factor,
            };
        }

        pub fn scale(self: @This(), factor: @This()) @This() {
            return @This(){
                .x = self.x * factor.x,
                .y = self.y * factor.y,
                .z = self.z * factor.z,
            };
        }

        pub fn negate(self: @This()) @This() {
            return @This(){
                .x = -self.x,
                .y = -self.y,
                .z = -self.z,
            };
        }

        pub fn distance_squared(self: @This(), other: @This()) Element {
            const delta = other.sub(self);
            return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z;
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{{ x: {d} y: {d} z: {d} }}", .{
                self.x,
                self.y,
                self.z,
            });
        }
    };
}
