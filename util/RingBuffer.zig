const std = @import("std");

buffer: []u8,
/// The next allocation can start at this byte
alloc_index: usize = 0,
/// Bytes before this index are free
free_index: usize = 0,

used_bytes: usize = 0,

pub fn alloc(self: *@This(), n: usize, log2_ptr_align: u8) ![]u8 {
    const start_alloc_index = self.alloc_index;
    const start_used_bytes = self.used_bytes;

    // reset state if we couldn't allocate
    errdefer {
        self.alloc_index = start_alloc_index;
        self.used_bytes = start_used_bytes;
    }

    defer {
        if (!@import("builtin").is_test) {
            @import("log").ring_buffer_allocate(.{n});
        }
    }

    const ptr_align = @as(usize, 1) << @as(std.mem.Allocator.Log2Align, @intCast(log2_ptr_align));

    while (true) {
        // pad to the correct alignment
        // before consuming padding:
        // - if consumption would wrap, clamp padding to reach physical end of buffer
        const align_padding = std.mem.alignPointerOffset(self.buffer.ptr + self.alloc_index, ptr_align) orelse return error.CouldNotAlignPointer;
        if (align_padding == 0) {
            const prospective_allocation = self.buffer.ptr + self.alloc_index;
            if (try self.consumeClamp(n) == n) {
                return prospective_allocation[0..n];
            }
        } else {
            _ = try self.consumeClamp(align_padding);
        }
    }
}

pub fn rawAlloc(ctx: *anyopaque, n: usize, log2_ptr_align: u8, ra: usize) ?[*]u8 {
    _ = ra;
    const self: *@This() = @ptrCast(@alignCast(ctx));
    return @ptrCast(self.alloc(n, log2_ptr_align) catch null);
}

pub fn freeOldest(self: *@This(), allocation_end_index: usize) !void {
    const initial_used = self.used_bytes;
    const initial_free_index = self.free_index;

    errdefer {
        self.used_bytes = initial_used;
        self.free_index = initial_free_index;
    }

    defer {
        if (!@import("builtin").is_test) {
            @import("log").ring_buffer_free(.{initial_used - self.used_bytes});
        }
        // if allocations are empty, reset both indices to minimize wasted bytes to overflow
        if (self.used_bytes == 0) {
            self.alloc_index = 0;
            self.free_index = 0;
        }
    }

    if (self.used_bytes == 0) return error.InvalidFree;
    // no wrapping
    if (self.free_index < self.alloc_index) {
        // end index is correctly in front of free index and does not overshoot alloc index
        // nothing wraps
        if (allocation_end_index <= self.alloc_index and allocation_end_index > self.free_index) {
            self.used_bytes = self.alloc_index - allocation_end_index;
            self.free_index = allocation_end_index;
        } else {
            return error.InvalidFree;
        }
    }
    // wrapping
    else if (self.free_index >= self.alloc_index) {
        // freed segment doesn't wrap, free segment wraps
        if (allocation_end_index > self.free_index) {
            self.used_bytes = try std.math.sub(usize, self.used_bytes, try std.math.sub(usize, allocation_end_index, self.free_index));
            self.free_index = allocation_end_index;
        }
        // freed segment wraps, free segment doesn't wrap
        else if (allocation_end_index <= self.alloc_index) {
            self.used_bytes = self.alloc_index - allocation_end_index;
            self.free_index = allocation_end_index;
        } else {
            return error.InvalidFree;
        }
    }
}

pub fn freeLatest(self: *@This(), allocation_start_index: usize) !void {
    const initial_used = self.used_bytes;
    const initial_alloc_index = self.alloc_index;

    errdefer {
        self.used_bytes = initial_used;
        self.alloc_index = initial_alloc_index;
    }

    defer {
        if (!@import("builtin").is_test) {
            @import("log").ring_buffer_free(.{initial_used - self.used_bytes});
        }
        // if allocations are empty, reset both indices to minimize wasted bytes to overflow
        if (self.used_bytes == 0) {
            self.alloc_index = 0;
            self.free_index = 0;
        }
    }

    if (self.used_bytes == 0) return error.InvalidFree;
    // no wrapping
    if (self.free_index < self.alloc_index) {
        // end index is correctly in front of free index and does not overshoot alloc index
        // nothing wraps
        if (allocation_start_index < self.alloc_index and allocation_start_index >= self.free_index) {
            self.used_bytes = allocation_start_index - self.free_index;
            self.alloc_index = allocation_start_index;
            return;
        } else {
            return error.InvalidFree;
        }
    }
    // wrapping
    else if (self.free_index >= self.alloc_index) {
        // freed segment doesn't wrap, free segment wraps
        if (allocation_start_index < self.alloc_index) {
            self.used_bytes -= (self.alloc_index - allocation_start_index);
            self.alloc_index = allocation_start_index;
        }
        // freed segment wraps, free segment doesn't wrap
        else if (allocation_start_index >= self.free_index) {
            self.used_bytes = allocation_start_index - self.free_index;
            self.alloc_index = allocation_start_index;
            return;
        } else {
            return error.InvalidFree;
        }
    }
}

// tries to consume bytes, clamping at the end of the buffer without erroring
pub fn consumeClamp(self: *@This(), bytes: usize) !usize {
    var actual_consumption = bytes;
    if (self.alloc_index + actual_consumption > self.buffer.len) {
        actual_consumption = self.buffer.len - self.alloc_index;
    }
    if (self.used_bytes + actual_consumption > self.buffer.len) {
        return error.OutOfMemory;
    }
    self.used_bytes += actual_consumption;
    self.alloc_index += actual_consumption;
    self.alloc_index %= self.buffer.len;

    return actual_consumption;
}

pub fn allocator(self: *@This()) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = rawAlloc,
            .resize = std.mem.Allocator.noResize,
            .free = std.mem.Allocator.noFree,
        },
    };
}

pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try writer.print("{{ alloc: {d} free: {d} used: {d} }}", .{
        self.alloc_index,
        self.free_index,
        self.used_bytes,
    });
}

test "RingBuffer" {
    if (true) return error.SkipZigTest;

    std.debug.print("\n----------------\n", .{});

    var rand_impl: std.rand.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = rand_impl.random();

    var ring_alloc: @This() = .{ .buffer = try std.testing.allocator.alloc(u8, 1024) };
    defer std.testing.allocator.free(ring_alloc.buffer);

    var fifo: std.fifo.LinearFifo(usize, .Dynamic) = .init(std.testing.allocator);
    defer fifo.deinit();

    for (0..1024) |_| {
        while (true) {
            const initial_alloc_index = ring_alloc.alloc_index;
            const alloc_size = rand.intRangeAtMost(usize, 32, 64);

            std.debug.print("PRE  | {} n: {}\n", .{ ring_alloc, alloc_size });

            _ = ring_alloc.alloc(rand.intRangeAtMost(usize, 32, 64), 0) catch {
                std.debug.print("\n--OOM--\n", .{});
                if (initial_alloc_index != ring_alloc.alloc_index) {
                    std.debug.print("freeing {} from latest\n", .{initial_alloc_index});
                    std.debug.print("PRE  | {} allocation_start_index: {}\n", .{ ring_alloc, initial_alloc_index });
                    try ring_alloc.freeLatest(initial_alloc_index);
                    std.debug.print("POST | {}\n", .{ring_alloc});
                }
                while (fifo.readItem()) |item| {
                    std.debug.print("freeing {} from oldest\n", .{item});
                    std.debug.print("PRE  | {} allocation_start_index: {}\n", .{ ring_alloc, item });
                    try ring_alloc.freeOldest(item);
                    std.debug.print("POST | {}\n", .{ring_alloc});
                }
                try std.testing.expectEqual(0, ring_alloc.used_bytes);
                try std.testing.expectEqual(ring_alloc.free_index, ring_alloc.alloc_index);
                continue;
            };

            std.debug.print("POST | {}\n", .{ring_alloc});
            break;
        }
        try fifo.writeItem(ring_alloc.alloc_index);
    }
}
