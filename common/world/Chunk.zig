const std = @import("std");
const Section = @import("../world/Section.zig");
const FilteredBlockState = @import("../block/block.zig").BlockState;

sections: [16]?*Section,
biomes: [256]u8,

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.sections) |maybe_section| {
        if (maybe_section) |section| {
            @import("log").free_section(&.{});
            allocator.destroy(section);
        }
    }
}
