pub const Direction = enum(i8) {
    down = 0,
    up = 1,
    north = 2,
    south = 3,
    west = 4,
    east = 5,

    pub fn from(other: anytype) @This() {
        switch (other) {
            inline else => |tag| return @field(@This(), @tagName(tag)),
        }
    }

    pub const names: []const []const u8 = &.{ "down", "up", "north", "south", "west", "east" };
};
