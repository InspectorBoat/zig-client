buffer: [*]align(std.heap.page_size_min) u8,
/// Capacity of the *logical* ring
capacity: usize,
/// Offset of the first readable byte within [0, capacity).
head: usize,
/// Number of readable bytes.
len: usize,

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

    return .{ .buffer = regions.ptr, .capacity = capacity, .head = 0, .len = 0 };
}

pub fn deinit(self: *@This()) void {
    std.posix.munmap(self.buffer[0..self.capacity]);
    self.* = undefined;
}

fn window(self: *@This(), offset: usize, len: usize) []u8 {
    std.debug.assert(len <= self.capacity);
    return self.buffer[offset % self.capacity ..][0..len];
}

pub fn advance(self: *@This(), n: usize) void {
    std.debug.assert(self.len + n <= self.capacity);
    self.len += n;
}

pub fn writeableSlice(self: *@This(), n: usize) []u8 {
    std.debug.assert(n <= self.capacity - self.len);
    defer self.advance(n);
    return self.window(self.head + self.len, n);
}

pub fn writeableSliceGreedy(self: *@This()) []u8 {
    return self.window(self.head + self.len, self.capacity - self.len);
}

pub fn write(self: *@This(), bytes: []const u8) !void {
    if (bytes.len > self.capacity - self.len) return error.OutOfMemory;
    @memcpy(self.window(self.head + self.len, bytes.len), bytes);
    self.len += bytes.len;
}

pub fn readableSlice(self: *@This()) []u8 {
    return self.window(self.head, self.len);
}

pub fn read(self: *@This(), n: usize) []u8 {
    std.debug.assert(n <= self.len);
    defer self.discard(n);
    return self.window(self.head, n);
}

pub fn readByte(self: *@This()) ?u8 {
    return if (self.len == 0) null else self.read(1)[0];
}

pub fn discard(self: *@This(), n: usize) void {
    std.debug.assert(n <= self.len);
    self.head = (self.head + n) % self.capacity;
    self.len -= n;
}

test write {
    const io = std.testing.io;
    const capacity = std.heap.pageSize();

    var fifo: @This() = try .initCapacity(io, capacity);
    defer fifo.deinit();
    try std.testing.expectEqual(capacity, fifo.capacity);

    const all = try std.testing.allocator.alloc(u8, capacity);
    defer std.testing.allocator.free(all);
    for (all, 0..) |*byte, i| byte.* = @truncate(i);

    try fifo.write(all);
    try std.testing.expectError(error.OutOfMemory, fifo.write(&.{0xff}));

    try std.testing.expectEqual(all[0], fifo.readByte().?);
    try fifo.write(&.{0xff});

    try std.testing.expectEqualSlices(u8, all[1..], fifo.read(capacity - 1));
    try std.testing.expectEqual(@as(u8, 0xff), fifo.readByte().?);
    try std.testing.expectEqual(@as(usize, 0), fifo.len);
}

test "wrapping" {
    const io = std.testing.io;
    const capacity = std.heap.pageSize();

    var fifo: @This() = try .initCapacity(io, capacity);
    defer fifo.deinit();

    @memset(fifo.writeableSlice(fifo.capacity - 4), 0xaa);
    fifo.discard(2);

    try fifo.write(&.{ 1, 2, 3, 4, 5, 6 });
    try std.testing.expectError(error.OutOfMemory, fifo.write(&.{7}));
}

const std = @import("std");
