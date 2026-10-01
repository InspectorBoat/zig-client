const std = @import("std");

buffer: []u8,
/// The next allocation can start at this byte
logical_alloc_index: usize = 0,
/// Bytes before this index are free
logical_free_index: usize = 0,

pub fn toPhysicalIndex(self: *const @This(), logical_index: usize) usize {
    return logical_index % self.buffer.len;
}

pub fn usedBytes(self: *const @This()) usize {
    return self.logical_alloc_index - self.logical_free_index;
}

pub fn alloc(self: *@This(), n: usize, alignment: std.mem.Alignment) ![*]u8 {
    // reset state if we couldn't allocate
    const initial_state = self.*;
    errdefer {
        self.* = initial_state;
    }

    const ptr_align = alignment.toByteUnits();

    while (true) {
        // pad to the correct alignment
        // before consuming padding:
        // - if consumption would wrap, clamp padding to reach physical end of buffer
        const align_padding =
            std.mem.alignPointerOffset(self.buffer.ptr + self.toPhysicalIndex(self.logical_alloc_index), ptr_align) orelse
            return error.CouldNotAlignPointer;
        if (align_padding == 0) {
            const prospective_allocation = self.buffer.ptr + self.toPhysicalIndex(self.logical_alloc_index);
            if (try self.consumeClamp(n) == n) {
                return prospective_allocation;
            }
        } else {
            _ = try self.consumeClamp(align_padding);
        }
    }
}

pub fn rawAlloc(ctx: *anyopaque, n: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
    _ = ra;
    const self: *@This() = @ptrCast(@alignCast(ctx));
    return self.alloc(n, alignment) catch null;
}

pub fn freeFromTail(self: *@This(), mark: usize) !void {
    if (mark < self.logical_free_index or mark > self.logical_alloc_index) return error.InvalidFree;

    self.logical_free_index = mark;

    if (self.usedBytes() == 0) {
        self.logical_alloc_index = 0;
        self.logical_free_index = 0;
    }
}

pub fn undoAllocations(self: *@This(), mark: usize) !void {
    if (mark < self.logical_free_index or mark > self.logical_alloc_index) return error.InvalidFree;

    self.logical_alloc_index = mark;

    if (self.usedBytes() == 0) {
        self.logical_alloc_index = 0;
        self.logical_free_index = 0;
    }
}

// tries to consume bytes, clamping at the end of the buffer without erroring
pub fn consumeClamp(self: *@This(), bytes: usize) !usize {
    const physical_index = self.toPhysicalIndex(self.logical_alloc_index);
    const actual_consumption = if (physical_index + bytes > self.buffer.len) self.buffer.len - physical_index else bytes;
    if (self.usedBytes() + actual_consumption > self.buffer.len) {
        return error.OutOfMemory;
    }
    self.logical_alloc_index += actual_consumption;

    return actual_consumption;
}

pub fn allocator(self: *@This()) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = rawAlloc,
            .resize = std.mem.Allocator.noResize,
            .remap = std.mem.Allocator.noRemap,
            .free = std.mem.Allocator.noFree,
        },
    };
}

test "RingBuffer" {
    var rand_impl: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.testing.io.random(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = rand_impl.random();

    var ring_alloc: @This() = .{ .buffer = try std.testing.allocator.alloc(u8, 1024) };
    defer std.testing.allocator.free(ring_alloc.buffer);

    var fifo: std.Deque(usize) = .empty;
    defer fifo.deinit(std.testing.allocator);

    for (0..1024) |_| {
        while (true) {
            const initial_alloc_index = ring_alloc.logical_alloc_index;
            const alloc_size = rand.intRangeAtMost(usize, 32, 64);

            _ = ring_alloc.alloc(alloc_size, .@"1") catch {
                if (initial_alloc_index != ring_alloc.logical_alloc_index) {
                    try ring_alloc.undoAllocations(initial_alloc_index);
                }
                while (fifo.popFront()) |item| {
                    try ring_alloc.freeFromTail(item);
                }
                try std.testing.expectEqual(0, ring_alloc.usedBytes());
                try std.testing.expectEqual(ring_alloc.logical_free_index, ring_alloc.logical_alloc_index);
                continue;
            };

            break;
        }
        try fifo.pushBack(std.testing.allocator, ring_alloc.logical_alloc_index);
    }
}
