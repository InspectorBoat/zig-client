const std = @import("std");

pub fn SpscQueue(Element: type) type {
    return struct {
        buffer: []Element,

        /// The next element written will go to this index
        write_index: std.atomic.Value(usize) = .init(0),
        /// The next element popped will be at this index
        read_index: std.atomic.Value(usize) = .init(0),

        pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !@This() {
            return .{ .buffer = try allocator.alloc(Element, capacity) };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.buffer);
        }

        pub fn unread(self: *@This()) usize {
            return self.write_index.load(.acquire) - self.read_index.load(.acquire);
        }

        pub fn push(self: *@This(), element: Element) !void {
            const read_index = self.read_index.load(.acquire);
            const write_index = self.write_index.load(.monotonic);
            if (write_index - read_index >= self.buffer.len) return error.WouldOverflow;

            self.buffer[write_index % self.buffer.len] = element;

            self.write_index.store(write_index + 1, .release);
        }

        pub fn pop(self: *@This()) ?Element {
            const read_index = self.read_index.load(.monotonic);
            const write_index = self.write_index.load(.acquire);
            if (write_index == read_index) return null;

            const element = self.buffer[read_index % self.buffer.len];

            self.read_index.store(read_index + 1, .release);

            return element;
        }
    };
}
