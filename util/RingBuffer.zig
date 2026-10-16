const std = @import("std");

const RingBuffer = @This();

pub const TailMark = struct {
    index: usize,
    /// TODO: actually you *can* move a ring buffer (just like how you can move an arraylist)
    /// so it would have to be a sentinel but i'm lazy
    owner: void = {},
    serial: usize,
};

pub const RewindMark = struct {
    index: usize,
    /// TODO: actually you *can* move a ring buffer (just like how you can move an arraylist)
    /// so it would have to be a sentinel but i'm lazy
    owner: void = {},
    // no serial, because you can only ever have one out at a time anyways
};

const Safety = struct {
    /// serial of the next tail mark that will get freed
    oldest_tail_serial: usize = 0,
    /// serial of the next tail mark that we will pass out
    next_tail_serial: usize = 0,

    active_rewind_index: ?usize = null,
};

buffer: []u8,
/// The next allocation can start at this byte
logical_alloc_index: usize = 0,
/// Bytes before this index are free
logical_free_index: std.atomic.Value(usize) = .init(0),

safety: Safety = .{},

pub fn initBuffer(buffer: []u8) @This() {
    return .{ .buffer = buffer };
}

pub fn toPhysicalIndex(self: *const @This(), logical_index: usize) usize {
    return logical_index % self.buffer.len;
}

pub fn usedBytes(self: *const @This()) usize {
    return self.logical_alloc_index - self.logical_free_index.load(.acquire);
}

pub fn alloc(self: *@This(), n: usize, alignment: std.mem.Alignment) ![*]u8 {
    // reset state if we couldn't allocate
    const initial_logical_alloc_index = self.logical_alloc_index;
    errdefer self.logical_alloc_index = initial_logical_alloc_index;

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

// I keep on shattering time
pub fn beginRewind(self: *@This()) RewindMark {
    std.debug.assert(self.safety.active_rewind_index == null);
    self.safety.active_rewind_index = self.logical_alloc_index;
    return .{ .index = self.logical_alloc_index };
}

// Run it back
pub fn undoAllocations(self: *@This(), mark: RewindMark) void {
    std.debug.assert(self.safety.active_rewind_index != null);
    std.debug.assert(mark.index == self.safety.active_rewind_index.?);
    // if you trigger this check, it's probably the RingBuffer that has a bug,
    // not the consuming code (unless it does something really stupid like forging
    // counterfeit Marks)
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire) and mark.index <= self.logical_alloc_index);

    self.logical_alloc_index = mark.index;
    self.safety.active_rewind_index = null;
}

// I got this blade in my hand for your punishment
pub fn commit(self: *@This(), mark: RewindMark) TailMark {
    std.debug.assert(self.safety.active_rewind_index != null);
    std.debug.assert(mark.index == self.safety.active_rewind_index.?);
    // if you trigger this check, it's probably the RingBuffer that has a bug,
    // not the consuming code (unless it does something really stupid like forging
    // counterfeit Marks)
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire) and mark.index <= self.logical_alloc_index);
    self.safety.active_rewind_index = null;
    defer self.safety.next_tail_serial += 1;
    return .{ .index = self.logical_alloc_index, .serial = self.safety.next_tail_serial };
}

pub fn freeFromTail(self: *@This(), mark: TailMark) void {
    std.debug.assert(mark.serial == self.safety.oldest_tail_serial);
    // if you trigger this check, it's probably the RingBuffer that has a bug,
    // not the consuming code (unless it does something really stupid like forging
    // counterfeit Marks)
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire));

    self.logical_free_index.store(mark.index, .release);
    self.safety.oldest_tail_serial += 1;
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

    var ring_alloc: @This() = .initBuffer(try std.testing.allocator.alloc(u8, 1024));
    defer std.testing.allocator.free(ring_alloc.buffer);

    var fifo: std.Deque(TailMark) = .empty;
    defer fifo.deinit(std.testing.allocator);

    for (0..1024) |_| {
        const rewind_mark = ring_alloc.beginRewind();
        const alloc_size = rand.intRangeAtMost(usize, 32, 64);

        _ = ring_alloc.alloc(alloc_size, .@"1") catch {
            ring_alloc.undoAllocations(rewind_mark);
            while (fifo.popFront()) |item| {
                ring_alloc.freeFromTail(item);
            }
            try std.testing.expectEqual(0, ring_alloc.usedBytes());
            try std.testing.expectEqual(ring_alloc.logical_free_index.raw, ring_alloc.logical_alloc_index);
            continue;
        };

        try fifo.pushBack(std.testing.allocator, ring_alloc.commit(rewind_mark));
    }
}
