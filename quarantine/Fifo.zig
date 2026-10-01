//! A minimal FIFO queue.
//!
//! `FixedFifo` stores its items inline with a comptime capacity and never
//! allocates. It deliberately does *not* wrap: readable items always occupy one
//! contiguous run starting at `consumed`, and the consumed prefix is reclaimed
//! by compacting when space runs short. That keeps `readableSlice` trivially
//! correct, which matters because the packet decoder hands it straight to a
//! buffer that must see every queued byte.
//!
//! This exists because `std.Deque` is a wrapping ring with no contiguous-slice
//! accessor. For a plain growable queue, use `std.Deque` instead.

const std = @import("std");

/// A FIFO queue with a comptime capacity that stores its items inline.
/// Writing beyond the capacity returns `error.OutOfMemory`.
pub fn FixedFifo(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [capacity]T = undefined,
        /// Index of the first readable item.
        consumed: usize = 0,
        /// Number of readable items.
        len: usize = 0,

        pub fn init() Self {
            return .{};
        }

        /// No-op: items are stored inline and never allocated.
        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub fn count(self: *const Self) usize {
            return self.len;
        }

        fn used(self: *const Self) usize {
            return self.consumed + self.len;
        }

        /// Drops everything and starts again at the front of the buffer.
        fn reset(self: *Self) void {
            self.consumed = 0;
            self.len = 0;
        }

        /// Slides the readable items down over the consumed prefix.
        fn compact(self: *Self) void {
            if (self.consumed == 0) return;
            if (self.len > 0) {
                std.mem.copyForwards(T, self.buffer[0..self.len], self.buffer[self.consumed..][0..self.len]);
            }
            self.consumed = 0;
        }

        /// Reclaims the consumed prefix if that is what is needed to make room.
        fn makeRoom(self: *Self, n: usize) void {
            if (capacity - self.used() >= n) return;
            self.compact();
        }

        /// Appends `bytes` at the end of the readable run.
        pub fn write(self: *Self, bytes: []const T) !void {
            self.makeRoom(bytes.len);
            if (capacity - self.used() < bytes.len) return error.OutOfMemory;
            @memcpy(self.buffer[self.used()..][0..bytes.len], bytes);
            self.len += bytes.len;
        }

        pub fn writeItem(self: *Self, item: T) !void {
            try self.write(&[_]T{item});
        }

        /// Everything currently readable, as one contiguous slice.
        pub fn readableSlice(self: *const Self) []const T {
            return self.buffer[self.consumed..][0..self.len];
        }

        /// Removes and returns the oldest item.
        pub fn readItem(self: *Self) ?T {
            if (self.len == 0) return null;
            const item = self.buffer[self.consumed];
            self.consumed += 1;
            self.len -= 1;
            if (self.consumed == capacity) self.reset();
            return item;
        }

        /// Removes the oldest `n` items.
        pub fn discard(self: *Self, n: usize) void {
            const dropped = @min(n, self.len);
            self.consumed += dropped;
            self.len -= dropped;
            if (self.consumed == capacity) self.reset();
        }

        /// Reclaims the consumed prefix so the readable run sits at the front.
        pub fn realign(self: *Self) void {
            self.compact();
        }
    };
}

test "FixedFifo is FIFO ordered" {
    var fifo: FixedFifo(u32, 4) = .init();
    defer fifo.deinit();

    try std.testing.expectEqual(@as(?u32, null), fifo.readItem());

    try fifo.writeItem(1);
    try fifo.writeItem(2);
    try fifo.writeItem(3);

    try std.testing.expectEqual(@as(usize, 3), fifo.count());
    try std.testing.expectEqual(@as(u32, 1), fifo.readItem().?);
    try std.testing.expectEqual(@as(u32, 2), fifo.readItem().?);
    try std.testing.expectEqual(@as(u32, 3), fifo.readItem().?);
    try std.testing.expectEqual(@as(?u32, null), fifo.readItem());
}

test "FixedFifo reclaims space and reports overflow" {
    var fifo: FixedFifo(u32, 2) = .init();
    defer fifo.deinit();

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
    var fifo: FixedFifo(u8, 64) = .init();
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
