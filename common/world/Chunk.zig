const std = @import("std");
const Section = @import("../world/Section.zig");
const Vector2 = @import("../math/vector.zig").Vector2;

sections: [16]?*Section,
biomes: [256]u8,
chunk_pos: Vector2(i32),

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.sections) |maybe_section| {
        if (maybe_section) |section| {
            @import("log").free_section(&.{});
            allocator.destroy(section);
        }
    }
}
