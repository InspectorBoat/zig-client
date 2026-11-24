buffer: [*]align(std.heap.page_size_min) u8,
/// Capacity of the *logical* ring
capacity: usize,
/// The next allocation can start at this byte
logical_alloc_index: usize = 0,
/// Bytes before this index are free
logical_free_index: std.atomic.Value(usize) = .init(0),
safety: Safety = .{},

const Safety = struct {
    /// serial of the next tail mark that will get freed
    oldest_tail_serial: usize = 0,
    /// serial of the next tail mark that we will pass out
    next_tail_serial: usize = 0,

    active_rewind_index: ?usize = null,
};

pub const TailMark = struct {
    index: usize,
    serial: usize,
};

pub const RewindMark = struct {
    index: usize,
    // no serial, because you can only ever have one out at a time anyways
};

pub fn initCapacity(io: std.Io, capacity: usize) !@This() {
    std.debug.assert(capacity != 0);
    std.debug.assert(std.mem.isAligned(capacity, std.heap.pageSize()));

    const file: std.Io.File = .{ .handle = try std.posix.memfd_create("fifo", std.posix.FD_CLOEXEC), .flags = undefined };
    defer file.close(io);

    try file.setLength(io, capacity);

    const regions = try std.posix.mmap(
        null,
        capacity * 2,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    errdefer std.posix.munmap(regions);

    // Map the same file twice at consecutive virtual addresses
    _ = try std.posix.mmap(
        regions.ptr,
        capacity,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .SHARED, .FIXED = true },
        file.handle,
        0,
    );
    _ = try std.posix.mmap(
        @alignCast(regions[capacity..].ptr),
        capacity,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .SHARED, .FIXED = true },
        file.handle,
        0,
    );

    return .{
        .buffer = regions.ptr,
        .capacity = capacity,
    };
}

pub fn deinit(self: *@This()) void {
    std.posix.munmap(self.buffer[0 .. self.capacity * 2]);
    self.* = undefined;
}

pub fn wrap(self: *const @This(), logical_index: usize) usize {
    return logical_index % self.capacity;
}

pub fn usedBytes(self: *const @This()) usize {
    return self.logical_alloc_index - self.logical_free_index.load(.acquire);
}

pub fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    _ = ret_addr;
    const self: *@This() = @ptrCast(@alignCast(ctx));

    const padding = std.mem.alignPointerOffset(self.buffer + self.logical_alloc_index, alignment.toByteUnits()) orelse return null;
    const next = self.logical_alloc_index + padding + len;

    if (next - self.logical_free_index.load(.acquire) > self.capacity) return null;

    defer self.logical_alloc_index = next;
    return self.buffer[self.wrap(self.logical_alloc_index + padding)..];
}

pub fn resize(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    _ = ret_addr;
    _ = alignment;
    const self: *@This() = @ptrCast(@alignCast(ctx));

    std.debug.assert(self.safety.active_rewind_index != null);

    // at last allocation
    if (self.wrap(self.buffer - memory.ptr + memory.len) == self.wrap(self.logical_alloc_index)) {
        // if shrinking, just reclaim and return
        if (new_len <= memory.len) {
            self.logical_alloc_index -= memory.len - new_len;
            return true;
        } else {
            // otherwise, try to allocate new memory
            const additional_bytes = new_len - memory.len;
            if (self.logical_alloc_index + additional_bytes - self.logical_free_index.load(.acquire) > self.capacity) return false;
            self.logical_alloc_index += additional_bytes;
            return true;
        }
    } else if (new_len <= memory.len) {
        // can always shrink an allocation
        return true;
    } else return false;
}

pub fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    return if (resize(ctx, memory, alignment, new_len, ret_addr)) memory.ptr else null;
}

pub fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    std.debug.assert(resize(ctx, memory, alignment, 0, ret_addr));
}

/// Begins an allocation region.
/// At any point, the caller may call rewind, passing it the returned
/// `RewindMark`. This consumes the token and undoes all allocations
/// since `beginRegion` was called.
/// Alternatively, the caller may call `commit` and receive a `TailMark`
/// which can be passed to a FIFO queue, and freed when reached.
pub fn beginRegion(self: *@This()) RewindMark {
    std.debug.assert(self.safety.active_rewind_index == null);
    self.safety.active_rewind_index = self.logical_alloc_index;
    return .{ .index = self.logical_alloc_index };
}

pub fn rewind(self: *@This(), mark: RewindMark) void {
    std.debug.assert(self.safety.active_rewind_index != null);
    std.debug.assert(mark.index == self.safety.active_rewind_index.?);
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire) and mark.index <= self.logical_alloc_index);

    self.logical_alloc_index = mark.index;
    self.safety.active_rewind_index = null;
}

pub fn commit(self: *@This(), mark: RewindMark) TailMark {
    std.debug.assert(self.safety.active_rewind_index != null);
    std.debug.assert(mark.index == self.safety.active_rewind_index.?);
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire) and mark.index <= self.logical_alloc_index);

    self.safety.active_rewind_index = null;
    defer self.safety.next_tail_serial += 1;
    return .{ .index = self.logical_alloc_index, .serial = self.safety.next_tail_serial };
}

pub fn freeFromTail(self: *@This(), mark: TailMark) void {
    std.debug.assert(mark.serial == self.safety.oldest_tail_serial);
    std.debug.assert(mark.index >= self.logical_free_index.load(.acquire));

    self.logical_free_index.store(mark.index, .release);
    self.safety.oldest_tail_serial += 1;
}

pub fn allocator(self: *@This()) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

test "RingBuffer" {
    var rand_impl: std.Random.DefaultPrng = .init(0xa7122b07cb54a87f);
    const rand = rand_impl.random();

    var ring_alloc: @This() = try .initCapacity(std.testing.io, std.heap.pageSize() * 2);
    defer ring_alloc.deinit();

    var fifo: std.Deque(TailMark) = .empty;
    defer fifo.deinit(std.testing.allocator);

    for (0..4096) |_| {
        const rewind_mark = ring_alloc.beginRegion();
        const alloc_size = rand.intRangeAtMost(usize, 1, 256);
        const alignment: std.mem.Alignment = @fromBackingInt(rand.intRangeAtMost(std.math.Log2Int(usize), 1, 8));
        if (alloc(&ring_alloc, alloc_size, alignment, undefined)) |ptr| {
            std.debug.assert(alignment.check(@intFromPtr(ptr)));
            try fifo.pushBack(std.testing.allocator, ring_alloc.commit(rewind_mark));
        } else {
            ring_alloc.rewind(rewind_mark);
            while (fifo.popFront()) |item| {
                ring_alloc.freeFromTail(item);
            }
            try std.testing.expectEqual(0, ring_alloc.usedBytes());
            try std.testing.expectEqual(ring_alloc.logical_free_index.raw, ring_alloc.logical_alloc_index);
        }
    }
}

const std = @import("std");
