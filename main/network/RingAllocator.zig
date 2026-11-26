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

    std.debug.assert(self.safety.active_rewind_index != null);

    const padding = std.mem.alignPointerOffset(self.buffer + self.wrap(self.logical_alloc_index), alignment.toByteUnits()) orelse return null;
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
    if (self.wrap(memory.ptr - self.buffer + memory.len) == self.wrap(self.logical_alloc_index)) {
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

fn fillPattern(ptr: [*]u8, len: usize, seed: u8) void {
    for (0..len) |i| ptr[i] = patternByte(seed, i);
}

fn expectPattern(ptr: [*]u8, len: usize, seed: u8) !void {
    for (0..len) |i| try std.testing.expectEqual(patternByte(seed, i), ptr[i]);
}

fn patternByte(seed: u8, index: usize) u8 {
    return seed +% @as(u8, @truncate(index *% 2654435761));
}

test wrap {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    try std.testing.expectEqual(0, ring.wrap(0));
    try std.testing.expectEqual(5, ring.wrap(5));
    try std.testing.expectEqual(0, ring.wrap(ring.capacity));
    try std.testing.expectEqual(18, ring.wrap(ring.capacity + 18));
    try std.testing.expectEqual(ring.capacity - 2, ring.wrap(3 * ring.capacity - 2));
}

test "allocations honor their requested alignment" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize() * 2);
    defer ring.deinit();

    const a = ring.allocator();
    const mark = ring.beginRegion();
    defer ring.rewind(mark);

    inline for (0..8) |log2| {
        const alignment: std.mem.Alignment = @fromBackingInt(log2);
        const memory = try a.alignedAlloc(u8, alignment, 3);
        try std.testing.expect(alignment.check(@intFromPtr(memory.ptr)));
        fillPattern(memory.ptr, memory.len, 0xA5);
    }
}

test "commit produces ordered serials and freeFromTail frees in fifo order" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize() * 2);
    defer ring.deinit();

    const a = ring.allocator();
    var tails: std.Deque(TailMark) = .empty;
    defer tails.deinit(std.testing.allocator);

    var serial: usize = 0;
    while (true) {
        const mark = ring.beginRegion();
        const memory = a.alloc(u8, 64) catch {
            ring.rewind(mark);
            break;
        };
        fillPattern(memory.ptr, memory.len, @truncate(serial));
        const tail = ring.commit(mark);
        try std.testing.expectEqual(serial, tail.serial);
        try std.testing.expectEqual((serial + 1) * 64, ring.usedBytes());
        try tails.pushBack(std.testing.allocator, tail);
        serial += 1;
    }

    var remaining: usize = tails.len;
    while (tails.popFront()) |tail| {
        ring.freeFromTail(tail);
        remaining -= 1;
        try std.testing.expectEqual(remaining * 64, ring.usedBytes());
    }
    try std.testing.expectEqual(ring.logical_free_index.raw, ring.logical_alloc_index);
}

test "rewind discards an in-progress region and allows reallocation at the same spot" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    const a = ring.allocator();
    const first_mark = ring.beginRegion();
    const first = try a.alloc(u8, 100);
    try std.testing.expectEqual(100, ring.usedBytes());

    ring.rewind(first_mark);
    try std.testing.expectEqual(0, ring.usedBytes());
    try std.testing.expectEqual(0, ring.logical_alloc_index);
    try std.testing.expectEqual(null, ring.safety.active_rewind_index);

    const second_mark = ring.beginRegion();
    const second = try a.alloc(u8, 50);
    try std.testing.expectEqual(first.ptr, second.ptr);
    try std.testing.expectEqual(50, ring.usedBytes());
    ring.rewind(second_mark);
}

test "allocation past remaining capacity fails without mutating state" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    const a = ring.allocator();
    const mark = ring.beginRegion();
    defer ring.rewind(mark);

    const memory = try a.alloc(u8, ring.capacity);
    try std.testing.expectEqual(ring.capacity, ring.usedBytes());

    // Both the Allocator wrapper and the raw vtable entry report failure.
    try std.testing.expectError(error.OutOfMemory, a.alloc(u8, 1));
    try std.testing.expect(a.rawAlloc(1, .@"1", @returnAddress()) == null);
    try std.testing.expectEqual(ring.capacity, ring.logical_alloc_index);
    try std.testing.expectEqual(0, ring.logical_free_index.raw);
    try std.testing.expectEqual(0, ring.safety.active_rewind_index.?);

    // Reclaiming the only allocation makes room again.
    a.free(memory);
    try std.testing.expectEqual(0, ring.usedBytes());
    try std.testing.expectEqual(ring.capacity, (try a.alloc(u8, ring.capacity)).len);
}

test "resize and remap grow and shrink the last allocation in place" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    const a = ring.allocator();
    const mark = ring.beginRegion();
    defer ring.rewind(mark);

    var memory = try a.alloc(u8, 64);
    fillPattern(memory.ptr, memory.len, 0x11);

    try std.testing.expect(a.resize(memory, 128));
    memory = memory.ptr[0..128];
    try std.testing.expectEqual(128, ring.usedBytes());
    try expectPattern(memory.ptr, 64, 0x11);

    const remapped = a.rawRemap(memory, .of(u8), 96, @returnAddress());
    try std.testing.expectEqual(memory.ptr, remapped.?);
    memory = memory.ptr[0..96];
    try std.testing.expectEqual(96, ring.usedBytes());

    try std.testing.expect(a.resize(memory, 32));
    memory = memory.ptr[0..32];
    try std.testing.expectEqual(32, ring.usedBytes());
    try expectPattern(memory.ptr, 32, 0x11);

    // Growing beyond the buffer fails and leaves the index untouched.
    try std.testing.expect(!a.resize(memory, ring.capacity + 1));
    try std.testing.expectEqual(32, ring.usedBytes());
}

test "non-last allocation resizes can only shrink and frees are no-ops" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    const a = ring.allocator();
    const mark = ring.beginRegion();
    defer ring.rewind(mark);

    const first = try a.alloc(u8, 64);
    var last = try a.alloc(u8, 64);
    try std.testing.expectEqual(128, ring.usedBytes());

    // Shrinking a non-last allocation is allowed but cannot reclaim space,
    // since the following allocation still sits directly after it.
    try std.testing.expect(a.resize(first, 32));
    try std.testing.expectEqual(128, ring.usedBytes());
    try std.testing.expect(!a.resize(first, 128));

    // Only the final allocation is actually reclaimed by free/resize.
    a.free(first);
    try std.testing.expectEqual(128, ring.usedBytes());
    try std.testing.expect(a.resize(last, 16));
    last = last.ptr[0..16];
    try std.testing.expectEqual(80, ring.usedBytes());
    a.free(last);
    // The non-last `first` allocation was never reclaimed, so 64 bytes remain.
    try std.testing.expectEqual(64, ring.usedBytes());
}

test "allocations crossing the physical end are contiguous and alias the first mapping" {
    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize());
    defer ring.deinit();

    try std.testing.expectEqual(5, ring.wrap(ring.capacity + 5));

    const a = ring.allocator();
    {
        const mark = ring.beginRegion();
        const memory = try a.alloc(u8, ring.capacity - 96);
        @memset(memory, 0xAA);
        ring.freeFromTail(ring.commit(mark));
    }
    try std.testing.expectEqual(ring.capacity - 96, ring.logical_free_index.raw);

    // This allocation starts 96 bytes before the end of the first mapping,
    // so its last 96 bytes live in the second mapping and alias offset 0.
    const mark = ring.beginRegion();
    const wrapped = try a.alloc(u8, 192);
    const seed: u8 = 0x37;
    fillPattern(wrapped.ptr, wrapped.len, seed);

    try std.testing.expectEqual(wrapped[0], ring.buffer[ring.capacity - 96]);
    try std.testing.expectEqual(wrapped[96], ring.buffer[0]);
    try std.testing.expectEqual(wrapped[191], ring.buffer[95]);
    try expectPattern(ring.buffer + (ring.capacity - 96), 96, seed);
    try expectPattern(wrapped.ptr + 96, 96, patternByte(seed, 96));
    try std.testing.expectEqual(192, ring.usedBytes());

    ring.freeFromTail(ring.commit(mark));
    try std.testing.expectEqual(0, ring.usedBytes());
}

test "randomized streaming allocations keep their data across wraps and frees" {
    var rand_impl: std.Random.DefaultPrng = .init(0xa7122b07cb54a87f);
    const rand = rand_impl.random();

    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize() * 2);
    defer ring.deinit();

    const a = ring.allocator();
    const Live = struct {
        tail: TailMark,
        ptr: [*]u8,
        len: usize,
        seed: u8,
    };
    var fifo: std.Deque(Live) = .empty;
    defer fifo.deinit(std.testing.allocator);

    for (0..4096) |iteration| {
        // Retire the oldest tails to keep usage bounded; the remaining
        // allocations must never overlap or corrupt one another.
        while (fifo.len > 0 and ring.usedBytes() > ring.capacity / 2) {
            ring.freeFromTail(fifo.popFront().?.tail);
        }

        const mark = ring.beginRegion();
        const len = rand.intRangeAtMost(usize, 1, 256);
        const alignment: std.mem.Alignment = @fromBackingInt(rand.intRangeAtMost(std.math.Log2Int(usize), 0, 6));
        const seed: u8 = @truncate(iteration);

        if (a.rawAlloc(len, alignment, @returnAddress())) |ptr| {
            try std.testing.expect(alignment.check(@intFromPtr(ptr)));
            fillPattern(ptr, len, seed);
            try fifo.pushBack(std.testing.allocator, .{
                .tail = ring.commit(mark),
                .ptr = ptr,
                .len = len,
                .seed = seed,
            });
        } else {
            ring.rewind(mark);
        }

        try std.testing.expect(ring.usedBytes() <= ring.capacity);
        var it = fifo.iterator();
        while (it.next()) |live| try expectPattern(live.ptr, live.len, live.seed);
    }

    while (fifo.popFront()) |live| ring.freeFromTail(live.tail);
    try std.testing.expectEqual(0, ring.usedBytes());
    try std.testing.expectEqual(ring.logical_free_index.raw, ring.logical_alloc_index);
}

test "producer and consumer share the ring across threads" {
    const concurrent_count = 2048;
    const concurrent_max_len = 256;
    const concurrent_max_align: std.mem.Alignment = .@"64";

    const ConcurrentCtx = struct {
        ring: *Ring,
        queue: *SpscQueue(Item),
        count: usize,
        items: std.Io.Semaphore = .{},
        space: std.Io.Semaphore = .{},

        const Item = struct {
            tail: TailMark,
            ptr: [*]u8,
            len: usize,
            seed: u8,
        };

        fn producer(ctx: *@This(), io: std.Io) void {
            const a = ctx.ring.allocator();
            var prng: std.Random.DefaultPrng = .init(0xa7122b07cb54a87f);
            const rand = prng.random();

            for (0..ctx.count) |produced| {
                ctx.space.waitUncancelable(io);
                const mark = ctx.ring.beginRegion();
                const len = rand.intRangeAtMost(usize, 1, concurrent_max_len);
                const alignment: std.mem.Alignment = @fromBackingInt(rand.intRangeAtMost(std.math.Log2Int(usize), 0, 6));
                const seed: u8 = @truncate(produced);
                const ptr = a.rawAlloc(len, alignment, @returnAddress()) orelse unreachable;

                fillPattern(ptr, len, seed);
                const tail = ctx.ring.commit(mark);
                ctx.queue.push(.{ .tail = tail, .ptr = ptr, .len = len, .seed = seed }) catch unreachable;
                ctx.items.post(io);
            }
        }
    };

    var ring: @This() = try .initCapacity(std.testing.io, std.heap.pageSize() * 2);
    defer ring.deinit();

    var queue: SpscQueue(ConcurrentCtx.Item) = try .initCapacity(std.testing.allocator, concurrent_count);
    defer queue.deinit(std.testing.allocator);

    var ctx: ConcurrentCtx = .{
        .ring = &ring,
        .queue = &queue,
        .count = concurrent_count,
        .space = .{ .permits = ring.capacity / (concurrent_max_len + concurrent_max_align.toByteUnits() - 1) },
    };

    const io = std.testing.io;

    var future = try io.concurrent(ConcurrentCtx.producer, .{ &ctx, io });
    for (0..ctx.count) |_| {
        ctx.items.waitUncancelable(io);
        const item = ctx.queue.pop().?;
        try expectPattern(item.ptr, item.len, item.seed);
        ctx.ring.freeFromTail(item.tail);
        ctx.space.post(io);
    }
    future.await(io);

    try std.testing.expectEqual(0, ring.usedBytes());
    try std.testing.expectEqual(ring.logical_free_index.raw, ring.logical_alloc_index);
}

const std = @import("std");

const SpscQueue = @import("spsc_queue.zig").SpscQueue;

const Ring = @This();
