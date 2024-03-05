const Hitbox = @import("../math/Hitbox.zig");

id: u16,

pub fn getFriction(self: @This()) f32 {
    _ = self;
    return 0.6;
}

pub fn getHitboxes(self: @This()) []const Hitbox {
    if (self.id == 0) {
        return &.{};
    }
    return &.{
        Hitbox{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 1, .y = 1, .z = 1 },
        },
    };
}
