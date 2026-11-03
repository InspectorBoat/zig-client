pub const Direction = enum(i8) {
    down = 0,
    up = 1,
    north = 2,
    south = 3,
    west = 4,
    east = 5,

    pub const @"+x": @This() = .east;
    pub const @"+y": @This() = .up;
    pub const @"+z": @This() = .south;
    pub const @"-x": @This() = .west;
    pub const @"-y": @This() = .down;
    pub const @"-z": @This() = .north;

    pub const Plane = enum {
        vertical,
        horizontal,
    };

    pub const Axis = enum {
        x,
        y,
        z,

        pub fn to(self: @This(), T: type) T {
            switch (self) {
                inline else => |known_axis| {
                    return @field(T, @tagName(known_axis));
                },
            }
        }

        pub fn toFallible(self: @This(), T: type) ?T {
            return switch (self) {
                inline else => |known_axis| if (@hasField(T, @tagName(known_axis))) @field(T, @tagName(known_axis)) else null,
            };
        }

        pub fn toAssert(self: @This(), T: type) T {
            return self.toFallible(T).?;
        }
    };

    pub fn plane(self: @This()) Plane {
        return switch (self) {
            .up, .down => .vertical,
            else => .horizontal,
        };
    }

    pub fn axis(self: @This()) Axis {
        return switch (self) {
            .west, .east => .x,
            .up, .down => .y,
            .north, .south => .z,
        };
    }

    pub fn opposite(self: @This()) @This() {
        // LLVM can't find this optimization
        // not that it really matters...
        return @fromBackingInt(@backingInt(self) ^ 1);
        // return switch (self) {
        //     .down => .up,
        //     .up => .down,
        //     .north => .south,
        //     .south => .north,
        //     .west => .east,
        //     .east => .west,
        // };
    }

    pub const horizontals: [4]@This() = .{ .north, .east, .south, .west };

    pub const verticals: [2]@This() = .{ .up, .down };

    pub fn fromYaw(yaw: f32) @This() {
        const numeric: u2 = @intCast(main.math.floor(yaw * 4.0 / 360.0 + 0.5) & 3);
        // .south, .west, .north, .east
        return switch (numeric) {
            0 => .south,
            1 => .west,
            2 => .north,
            3 => .east,
        };
    }

    pub fn from(other: anytype) @This() {
        switch (other) {
            inline else => |tag| return @field(@This(), @tagName(tag)),
        }
    }

    pub fn to(self: @This(), T: type) T {
        return switch (self) {
            inline else => |known_dir| @field(T, @tagName(known_dir)),
        };
    }

    pub fn toFallible(self: @This(), T: type) ?T {
        return switch (self) {
            inline else => |known_dir| if (@hasField(T, @tagName(known_dir))) @field(T, @tagName(known_dir)) else null,
        };
    }

    pub fn toAssert(self: @This(), T: type) T {
        return self.toFallible(T).?;
    }
};

const std = @import("std");

const main = @import("main");

const Vector3 = @import("vector.zig").Vector3;
