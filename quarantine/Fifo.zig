buffer: []u8 = undefined,
/// Index of the first readable item.
consumed: usize = 0,
/// Number of readable items.
len: usize = 0,

pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !@This() {
    return .{ .buffer = try allocator.alloc(u8, capacity) };
}

/// No-op: items are stored inline and never allocated.
pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    allocator.free(self.buffer);
}

pub fn count(self: *const @This()) usize {
    return self.len;
}

fn used(self: *const @This()) usize {
    return self.consumed + self.len;
}

/// Drops everything and starts again at the front of the buffer.
fn reset(self: *@This()) void {
    self.consumed = 0;
    self.len = 0;
}

/// Slides the readable items down over the consumed prefix.
fn compact(self: *@This()) void {
    if (self.consumed == 0) return;
    if (self.len > 0) {
        std.mem.copyForwards(u8, self.buffer[0..self.len], self.buffer[self.consumed..][0..self.len]);
    }
    self.consumed = 0;
}

/// Reclaims the consumed prefix if that is what is needed to make room.
fn makeRoom(self: *@This(), n: usize) void {
    if (self.buffer.len - self.used() >= n) return;
    self.compact();
}

/// Appends `bytes` at the end of the readable run.
pub fn write(self: *@This(), bytes: []const u8) !void {
    self.makeRoom(bytes.len);
    if (self.buffer.len - self.used() < bytes.len) return error.OutOfMemory;
    @memcpy(self.buffer[self.used()..][0..bytes.len], bytes);
    self.len += bytes.len;
}

pub fn writeItem(self: *@This(), item: u8) !void {
    try self.write(&[_]u8{item});
}

/// Everything currently readable, as one contiguous slice.
pub fn readableSlice(self: *const @This()) []u8 {
    return self.buffer[self.consumed..][0..self.len];
}

/// Removes and returns the oldest item.
pub fn readItem(self: *@This()) ?u8 {
    if (self.len == 0) return null;
    const item = self.buffer[self.consumed];
    self.consumed += 1;
    self.len -= 1;
    if (self.consumed == self.buffer.len) self.reset();
    return item;
}

/// Removes the oldest `n` items.
pub fn discard(self: *@This(), n: usize) void {
    const dropped = @min(n, self.len);
    self.consumed += dropped;
    self.len -= dropped;
    if (self.consumed == self.buffer.len) self.reset();
}

/// Reclaims the consumed prefix so the readable run sits at the front.
pub fn realign(self: *@This()) void {
    self.compact();
}

test "Fifo is FIFO ordered" {
    var fifo: @This() = .initCapacity(std.testing.allocator, 4);
    defer fifo.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(?u32, null), fifo.readItem());

    try fifo.writeItem(1);
    try fifo.writeItem(2);
    try fifo.writeItem(3);

    try std.testing.expectEqual(3, fifo.count());
    try std.testing.expectEqual(@as(?u32, 1), fifo.readItem());
    try std.testing.expectEqual(@as(?u32, 2), fifo.readItem());
    try std.testing.expectEqual(@as(?u32, 3), fifo.readItem());
    try std.testing.expectEqual(@as(?u32, null), fifo.readItem());
}

test "Fifo reclaims space and reports overflow" {
    var fifo: @This() = .initCapacity(std.testing.allocator, 2);
    defer fifo.deinit(std.testing.allocator);

    try fifo.writeItem(1);
    try fifo.writeItem(2);
    try std.testing.expectError(error.OutOfMemory, fifo.writeItem(3));

    // consume one, which frees room at the front
    try std.testing.expectEqual(@as(u32, 1), fifo.readItem().?);
    try fifo.writeItem(3);

    try std.testing.expectEqual(@as(u32, 2), fifo.readItem().?);
    try std.testing.expectEqual(@as(u32, 3), fifo.readItem().?);
}

test "FixedFifo readable slice stays contiguous and correct" {
    var fifo: @This() = .initCapacity(64);
    defer fifo.deinit();

    var all: [64]u8 = undefined;
    for (&all, 0..) |*b, i| b.* = @intCast(i);

    try fifo.write(all[0..30]);
    fifo.discard(17);
    try std.testing.expectEqualSlices(u8, all[17..30], fifo.readableSlice());

    // force compaction, then check the contents survived intact
    fifo.realign();
    try std.testing.expectEqualSlices(u8, all[17..30], fifo.readableSlice());

    // keep appending past capacity: the consumed prefix must be reclaimed
    var i: usize = 30;
    while (i < 64) : (i += 1) {
        try fifo.write(all[i .. i + 1]);
    }
    try std.testing.expectEqualSlices(u8, all[17..64], fifo.readableSlice());
}

const std = @import("std");
