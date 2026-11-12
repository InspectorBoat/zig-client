const FreeSegment = struct {};

fn listEntry(_: *std.SinglyLinkedList.Node) *FreeSegment {
    return undefined;
}

free_segments: std.SinglyLinkedList,
backing_buffer: gl.Buffer,
min_alignment: c_int,
used: usize = 0,
allocator: std.mem.Allocator,

pub fn detectLeaks(self: @This()) bool {
    return self.used > 0;
}

pub fn init() !@This() {
    return undefined;
}

pub fn deinit(_: *@This()) void {}

pub fn alloc(self: *@This(), _: usize) !Segment {
    while (self.free_segments.first) |node| {
        _ = listEntry(node);
    }
    return error.OutOfMemory;
}

pub fn free(_: *@This(), _: Segment) !void {}

pub fn subData(_: @This(), _: Segment, _: []const u8) void {}

pub const Segment = struct {
    offset: usize,
    length: usize,
};

const std = @import("std");

const gl = @import("zgl");
