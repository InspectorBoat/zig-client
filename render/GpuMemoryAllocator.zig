const std = @import("std");
const gl = if (!@import("builtin").is_test) @import("zgl") else struct {
    pub const Buffer = struct {
        pub fn create() @This() {
            return .{};
        }
        pub fn storage(_: @This(), comptime T: type, _: usize, _: ?[*]align(1) const T, _: anytype) void {}
        pub fn delete(_: @This()) void {}
    };
};
free_segments: std.SinglyLinkedList(Segment),
backing_buffer: gl.Buffer,
used: usize = 0,

pub fn init(allocator: std.mem.Allocator, backing_buffer_size: usize) !@This() {
    const backing_buffer = gl.Buffer.create();
    errdefer backing_buffer.delete();
    backing_buffer.storage(u8, backing_buffer_size, null, .{ .dynamic_storage = true });

    const first_node = try allocator.create(std.SinglyLinkedList(Segment).Node);
    first_node.* = .{
        .data = .{ .length = backing_buffer_size, .offset = 0 },
        .next = null,
    };

    return .{
        .free_segments = std.SinglyLinkedList(Segment){ .first = first_node },
        .backing_buffer = backing_buffer,
    };
}

pub fn alloc(self: *@This(), n: usize, allocator: std.mem.Allocator) !Segment {
    var maybe_node = self.free_segments.first;
    while (maybe_node) |node| : (maybe_node = node.next) {
        const segment = &node.data;
        if (segment.length >= n) {
            defer {
                segment.offset += n;
                segment.length -= n;
                std.debug.assert(segment.length >= 0);
                if (segment.length == 0) {
                    self.free_segments.remove(node);

                    allocator.destroy(node);
                }
            }

            self.used += n;
            return .{
                .length = n,
                .offset = segment.offset,
            };
        }
    }
    return error.OutOfMemory;
}

pub fn free(self: *@This(), free_segment: Segment, allocator: std.mem.Allocator) !void {
    const node = try allocator.create(std.SinglyLinkedList(Segment).Node);
    node.* = .{
        .data = free_segment,
        .next = null,
    };
    self.free_segments.prepend(node);
    self.used -= free_segment.length;
}

pub fn subData(self: @This(), segment: Segment, items: []const u8) void {
    self.backing_buffer.subData(segment.offset, u8, @ptrCast(items));
}

pub const Segment = struct {
    offset: usize,
    length: usize,
};

test alloc {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();
    defer _ = gpa_impl.deinit();

    var gpu_mem_alloc = try init(gpa, 1024);
    while (true) {
        _ = gpu_mem_alloc.alloc(1024, gpa) catch break;
    }
}
