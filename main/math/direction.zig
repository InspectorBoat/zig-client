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

    pub fn from(other: anytype) @This() {
        switch (other) {
            inline else => |tag| return @field(@This(), @tagName(tag)),
        }
    }
};
