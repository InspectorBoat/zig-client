const Vector3 = @import("vector.zig").Vector3;

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

    pub const verticals: [2]@This() = .{ .up, .down };

    pub const horizontals: [4]@This() = .{ .north, .south, .west, .east };

    pub fn opposite(self: @This()) @This() {
        return switch (self) {
            .down => .up,
            .up => .down,
            .north => .south,
            .south => .north,
            .west => .east,
            .east => .west,
        };
    }

    pub fn from(other: anytype) @This() {
        switch (other) {
            inline else => |tag| return @field(@This(), @tagName(tag)),
        }
    }
};
