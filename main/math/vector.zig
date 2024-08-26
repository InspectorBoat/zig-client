const std = @import("std");
const Direction = @import("direction.zig").Direction;

pub fn Vector2xy(comptime Element: type) type {
    return struct {
        x: Element,
        y: Element,

        pub fn origin() @This() {
            return @This(){
                .x = 0,
                .y = 0,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: @This(), other: @This()) @This() {
            return @This(){
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }
        pub fn scaleUniform(self: @This(), factor: Element) @This() {
            return @This(){
                .x = self.x * factor,
                .y = self.y * factor,
            };
        }

        pub fn negate(self: @This()) @This() {
            return @This(){
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
            const delta = other.sub(self);
            return delta.x * delta.x + delta.y * delta.y;
        }

        pub fn equals(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn floatCast(self: @This(), comptime Target: type) Vector2xy(Target) {
            if (@typeInfo(Target) != .Float) @compileLog("Must floatCast to float!");
            if (@typeInfo(Element) != .Float) @compileLog("Must floatCast from float!");
            return .{
                .x = @floatCast(self.x),
                .z = @floatCast(self.y),
            };
        }

        pub fn intCast(self: @This(), comptime Target: type) Vector2xy(Target) {
            if (@typeInfo(Target) != .Int) @compileLog("Must intCast to int!");
            if (@typeInfo(Element) != .Int) @compileLog("Must intCast from int!");
            return .{
                .x = @intCast(self.x),
                .z = @intCast(self.y),
            };
        }

        pub fn floatToInt(self: @This(), comptime Target: type) Vector2xy(Target) {
            if (@typeInfo(Target) != .Float) @compileLog("Start type must be float!");
            if (@typeInfo(Element) != .Int) @compileLog("Target type from int!");
            return .{
                .x = @intFromFloat(self.x),
                .z = @intFromFloat(self.y),
            };
        }

        pub fn intToFloat(self: @This(), comptime Target: type) Vector2xy(Target) {
            if (@typeInfo(Target) != .Int) @compileLog("Start type must be int!");
            if (@typeInfo(Element) != .Float) @compileLog("Target type from float!");
            return .{
                .x = @floatFromInt(self.x),
                .z = @floatFromInt(self.y),
            };
        }

        pub fn bitCast(self: @This(), comptime Target: type) Vector2xy(Target) {
            return .{
                .x = @bitCast(self.x),
                .z = @bitCast(self.y),
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

        pub fn equals(self: @This(), other: @This()) bool {
            return self.x == other.x and self.z == other.z;
        }

        pub fn floatCast(self: @This(), comptime Target: type) Vector2xz(Target) {
            if (@typeInfo(Target) != .Float) @compileLog("Must floatCast to float!");
            if (@typeInfo(Element) != .Float) @compileLog("Must floatCast from float!");
            return .{
                .x = @floatCast(self.x),
                .z = @floatCast(self.z),
            };
        }

        pub fn intCast(self: @This(), comptime Target: type) Vector2xz(Target) {
            if (@typeInfo(Target) != .Int) @compileLog("Must intCast to int!");
            if (@typeInfo(Element) != .Int) @compileLog("Must intCast from int!");
            return .{
                .x = @intCast(self.x),
                .z = @intCast(self.z),
            };
        }

        pub fn floatToInt(self: @This(), comptime Target: type) Vector2xz(Target) {
            if (@typeInfo(Target) != .Float) @compileLog("Start type must be float!");
            if (@typeInfo(Element) != .Int) @compileLog("Target type from int!");
            return .{
                .x = @intFromFloat(self.x),
                .z = @intFromFloat(self.z),
            };
        }

        pub fn intToFloat(self: @This(), comptime Target: type) Vector2xz(Target) {
            if (@typeInfo(Target) != .Int) @compileLog("Start type must be int!");
            if (@typeInfo(Element) != .Float) @compileLog("Target type from float!");
            return .{
                .x = @floatFromInt(self.x),
                .z = @floatFromInt(self.z),
            };
        }

        pub fn bitCast(self: @This(), comptime Target: type) Vector2xz(Target) {
            return .{
                .x = @bitCast(self.x),
                .z = @bitCast(self.z),
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

        pub fn distance(self: @This(), other: @This()) Element {
            return std.math.sqrt(self.distance_squared(other));
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
            return @This(){
                .x = self.x,
                .y = self.y + 1,
                .z = self.z,
            };
        }
        pub fn down(self: @This()) @This() {
            return @This(){
                .x = self.x,
                .y = self.y - 1,
                .z = self.z,
            };
        }
        pub fn north(self: @This()) @This() {
            return @This(){
                .x = self.x,
                .y = self.y,
                .z = self.z - 1,
            };
        }
        pub fn south(self: @This()) @This() {
            return @This(){
                .x = self.x,
                .y = self.y,
                .z = self.z + 1,
            };
        }
        pub fn west(self: @This()) @This() {
            return @This(){
                .x = self.x - 1,
                .y = self.y,
                .z = self.z,
            };
        }
        pub fn east(self: @This()) @This() {
            return @This(){
                .x = self.x + 1,
                .y = self.y,
                .z = self.z,
            };
        }
        pub fn dir(self: @This(), direction: Direction) @This() {
            return switch (direction) {
                .Down => self.down(),
                .East => self.east(),
                .North => self.north(),
                .South => self.south(),
                .Up => self.up(),
                .West => self.west(),
            };
        }

        pub fn floatCast(self: @This(), comptime Target: type) Vector3(Target) {
            if (@typeInfo(Target) != .Float) @compileLog("Must floatCast to float!");
            if (@typeInfo(Element) != .Float) @compileLog("Must floatCast from float!");
            return .{
                .x = @floatCast(self.x),
                .y = @floatCast(self.y),
                .z = @floatCast(self.z),
            };
        }

        pub fn intCast(self: @This(), comptime Target: type) Vector3(Target) {
            if (@typeInfo(Target) != .Int) @compileLog("Must intCast to int!");
            if (@typeInfo(Element) != .Int) @compileLog("Must intCast from int!");
            return .{
                .x = @intCast(self.x),
                .y = @intCast(self.y),
                .z = @intCast(self.z),
            };
        }

        pub fn floatToInt(self: @This(), comptime Target: type) Vector3(Target) {
            if (@typeInfo(Element) != .Float) @compileLog("Start type must be float!");
            if (@typeInfo(Target) != .Int) @compileLog("Target type from int!");
            return .{
                .x = @intFromFloat(self.x),
                .y = @intFromFloat(self.y),
                .z = @intFromFloat(self.z),
            };
        }

        pub fn intToFloat(self: @This(), comptime Target: type) Vector3(Target) {
            if (@typeInfo(Element) != .Int) @compileError("Start type must be int!");
            if (@typeInfo(Target) != .Float) @compileError("Target type from float!");
            return .{
                .x = @floatFromInt(self.x),
                .y = @floatFromInt(self.y),
                .z = @floatFromInt(self.z),
            };
        }

        pub fn bitCast(self: @This(), comptime Target: type) Vector3(Target) {
            return .{
                .x = @bitCast(self.x),
                .y = @bitCast(self.x),
                .z = @bitCast(self.z),
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
