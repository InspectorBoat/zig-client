sections: [16]?*World.Section,
biomes: [256]u8,
chunk_pos: Vector2xz(i32),

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.sections) |maybe_section| {
        if (maybe_section) |section| {
            std.log.scoped(.world).debug("freeing section", .{});
            allocator.destroy(section);
        }
    }
    allocator.destroy(self);
}

const std = @import("std");

const main = @import("main");

const Vector2xz = main.Vector2xz;
const World = main.World;
