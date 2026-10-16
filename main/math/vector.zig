const std = @import("std");

const Direction = @import("direction.zig").Direction;

pub fn Vector2xy(comptime Element: type) type {
    return struct {
        x: Element,
        y: Element,

        pub fn origin() @This() {
            return .{
                .x = 0,
                .y = 0,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }
        pub fn negate(self: @This()) @This() {
            return .{
                .x = -self.x,
                .y = -self.y,
            };
        }

        pub fn magnitude_squared(self: @This()) Element {
            return self.x * self.x + self.y * self.y;
        }

        pub fn magnitude(self: @This()) Element {
            return @sqrt(self.x * self.x + self.y * self.y);
        }

        pub fn distance_squared(self: @This(), other: @This()) Element {
            const delta: @This() = .sub(other, self);
            return delta.x * delta.x + delta.y * delta.y;
        }

        pub fn equals(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y;
        }

        // for safe coercions
        pub fn cast(vec: anytype) @This() {
            return .{
                .x = vec.x,
                .y = vec.y,
            };
        }

        pub fn floatCast(vec: anytype) @This() {
            return .{
                .x = @floatCast(vec.x),
                .y = @floatCast(vec.y),
            };
        }

        pub fn intCast(vec: anytype) @This() {
            return .{
                .x = @intCast(vec.x),
                .y = @intCast(vec.y),
            };
        }

        pub fn intFromFloat(vec: anytype) @This() {
            return .{
                .x = @intFromFloat(vec.x),
                .y = @intFromFloat(vec.y),
            };
        }

        pub fn floatFromInt(vec: anytype) @This() {
            return .{
                .x = @floatFromInt(vec.x),
                .y = @floatFromInt(vec.y),
            };
        }

        pub fn bitCast(vec: anytype) @This() {
            return .{
                .x = @bitCast(vec.x),
                .y = @bitCast(vec.y),
            };
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{{ x: {d} z: {d} }}", .{
                self.x,
                self.y,
            });
        }
    };
}

pub fn Vector2xz(comptime Element: type) type {
    return struct {
        x: Element,
        z: Element,

        pub fn origin() @This() {
            return .{
                .x = 0,
                .z = 0,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .z = self.z - other.z,
            };
        }
        pub fn splat(n: Element) @This() {
            return .{ .x = n, .z = n };
        }

        pub fn mul(self: @This(), factor: @This()) @This() {
            return .{
                .x = self.x * factor.x,
                .z = self.z * factor.z,
            };
        }

        pub fn negate(self: @This()) @This() {
            return .{
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
            const delta: @This() = .sub(other, self);
            return delta.x * delta.x + delta.z * delta.z;
        }

        pub fn equals(self: @This(), other: @This()) bool {
            return self.x == other.x and self.z == other.z;
        }

        // for safe coercions
        pub fn cast(vec: anytype) @This() {
            return .{
                .x = vec.x,
                .z = vec.z,
            };
        }

        pub fn floatCast(vec: anytype) @This() {
            return .{
                .x = @floatCast(vec.x),
                .z = @floatCast(vec.z),
            };
        }

        pub fn intCast(vec: anytype) @This() {
            return .{
                .x = @intCast(vec.x),
                .z = @intCast(vec.z),
            };
        }

        pub fn intFromFloat(vec: anytype) @This() {
            return .{
                .x = @intFromFloat(vec.x),
                .z = @intFromFloat(vec.z),
            };
        }

        pub fn floatFromInt(vec: anytype) @This() {
            return .{
                .x = @floatFromInt(vec.x),
                .z = @floatFromInt(vec.z),
            };
        }

        pub fn bitCast(vec: anytype) @This() {
            return .{
                .x = @bitCast(vec.x),
                .z = @bitCast(vec.z),
            };
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
            return .{ .x = 0, .y = 0, .z = 0 };
        }

        pub fn splat(n: Element) @This() {
            return .{ .x = n, .y = n, .z = n };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub fn mul(self: @This(), factor: @This()) @This() {
            return .{
                .x = self.x * factor.x,
                .y = self.y * factor.y,
                .z = self.z * factor.z,
            };
        }

        pub fn div(self: @This(), divisor: @This()) @This() {
            return .{
                .x = self.x / divisor.x,
                .y = self.y / divisor.y,
                .z = self.z / divisor.z,
            };
        }

        pub fn divFloor(self: @This(), divisor: @This()) @This() {
            return .{
                .x = @divFloor(self.x, divisor.x),
                .y = @divFloor(self.y, divisor.y),
                .z = @divFloor(self.z, divisor.z),
            };
        }

        pub fn divCeil(self: @This(), divisor: @This()) @This() {
            return .{
                .x = @divCeil(self.x, divisor.x),
                .y = @divCeil(self.y, divisor.y),
                .z = @divCeil(self.z, divisor.z),
            };
        }

        pub fn divTrunc(self: @This(), divisor: @This()) @This() {
            return .{
                .x = @divTrunc(self.x, divisor.x),
                .y = @divTrunc(self.y, divisor.y),
                .z = @divTrunc(self.z, divisor.z),
            };
        }

        pub fn negate(self: @This()) @This() {
            return .{
                .x = -self.x,
                .y = -self.y,
                .z = -self.z,
            };
        }

        pub fn distanceSquared(self: @This(), other: @This()) Element {
            const delta: @This() = .sub(other, self);
            return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z;
        }

        pub fn distance(self: @This(), other: @This()) Element {
            return std.math.sqrt(self.distanceSquared(other));
        }

        pub fn magnitudeSquared(self: @This()) Element {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }

        pub fn magnitude(self: @This()) Element {
            return std.math.sqrt(self.magnitudeSquared());
        }

        pub fn anyNaN(self: @This()) bool {
            return std.math.isNan(self.x) or std.math.isNan(self.y) or std.math.isNan(self.z);
        }

        pub fn equals(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y and self.z == other.z;
        }

        pub fn up(self: @This()) @This() {
            return .{
                .x = self.x,
                .y = self.y + 1,
                .z = self.z,
            };
        }
        pub fn down(self: @This()) @This() {
            return .{
                .x = self.x,
                .y = self.y - 1,
                .z = self.z,
            };
        }
        pub fn north(self: @This()) @This() {
            return .{
                .x = self.x,
                .y = self.y,
                .z = self.z - 1,
            };
        }
        pub fn south(self: @This()) @This() {
            return .{
                .x = self.x,
                .y = self.y,
                .z = self.z + 1,
            };
        }
        pub fn west(self: @This()) @This() {
            return .{
                .x = self.x - 1,
                .y = self.y,
                .z = self.z,
            };
        }
        pub fn east(self: @This()) @This() {
            return .{
                .x = self.x + 1,
                .y = self.y,
                .z = self.z,
            };
        }
        pub fn dir(self: @This(), direction: Direction) @This() {
            return switch (direction) {
                .down => self.down(),
                .east => self.east(),
                .north => self.north(),
                .south => self.south(),
                .up => self.up(),
                .west => self.west(),
            };
        }
        pub fn fromDir(direction: Direction) @This() {
            return switch (direction) {
                .@"+x" => .{ .x = 1, .y = 0, .z = 0 },
                .@"+y" => .{ .x = 0, .y = 1, .z = 0 },
                .@"+z" => .{ .x = 0, .y = 0, .z = 1 },
                .@"-x" => .{ .x = -1, .y = 0, .z = 0 },
                .@"-y" => .{ .x = 0, .y = -1, .z = 0 },
                .@"-z" => .{ .x = 0, .y = 0, .z = -1 },
            };
        }

        pub fn cmp(lhs: @This(), op: std.math.CompareOperator, rhs: @This()) Vector3(bool) {
            return .{
                .x = std.math.compare(lhs.x, op, rhs.x),
                .y = std.math.compare(lhs.y, op, rhs.y),
                .z = std.math.compare(lhs.z, op, rhs.z),
            };
        }

        pub fn any(self: @This()) bool {
            return self.x or self.y or self.z;
        }

        pub fn all(self: @This()) bool {
            return self.x and self.y and self.z;
        }

        // for safe coercions
        pub fn cast(vec: anytype) @This() {
            return .{
                .x = vec.x,
                .y = vec.y,
                .z = vec.z,
            };
        }

        pub fn floatCast(vec: anytype) @This() {
            return .{
                .x = @floatCast(vec.x),
                .y = @floatCast(vec.y),
                .z = @floatCast(vec.z),
            };
        }

        pub fn intCast(vec: anytype) @This() {
            return .{
                .x = @intCast(vec.x),
                .y = @intCast(vec.y),
                .z = @intCast(vec.z),
            };
        }

        pub fn intFromFloat(vec: anytype) @This() {
            return .{
                .x = @intFromFloat(vec.x),
                .y = @intFromFloat(vec.y),
                .z = @intFromFloat(vec.z),
            };
        }

        pub fn floatFromInt(vec: anytype) @This() {
            return .{
                .x = @floatFromInt(vec.x),
                .y = @floatFromInt(vec.y),
                .z = @floatFromInt(vec.z),
            };
        }

        pub fn bitCast(vec: anytype) @This() {
            return .{
                .x = @bitCast(vec.x),
                .y = @bitCast(vec.y),
                .z = @bitCast(vec.z),
            };
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
