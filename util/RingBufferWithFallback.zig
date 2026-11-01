ringbuffer: RingBuffer,
gpa: std.heap.SafeAllocator,
active_arena: ?std.heap.ArenaAllocator.State = null,

pub const TailMark = struct {
    inner: RingBuffer.TailMark,
    arena: std.heap.ArenaAllocator.State,
};

pub const RewindMark = struct {
    inner: RingBuffer.RewindMark,
};

pub fn initCapacity(backing_allocator: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .ringbuffer = try .initCapacity(backing_allocator, capacity),
        .gpa = .init(backing_allocator, .{}),
    };
}

pub fn deinit(self: *@This(), backing_allocator: std.mem.Allocator) void {
    self.ringbuffer.deinit(backing_allocator);
    _ = self.gpa.deinitLog(false);
}

pub fn ringBufferUsed(self: *@This()) usize {
    return self.ringbuffer.usedBytes();
}

pub fn beginRegion(self: *@This()) RewindMark {
    std.debug.assert(self.active_arena == null);
    self.active_arena = .init;
    return .{ .inner = self.ringbuffer.beginRegion() };
}

pub fn rewind(self: *@This(), mark: RewindMark) void {
    std.debug.assert(self.active_arena != null);
    self.ringbuffer.rewind(mark.inner);
    self.active_arena.?.promote(self.gpa.allocator()).deinit();
    self.active_arena = null;
}

pub fn commit(self: *@This(), mark: RewindMark) TailMark {
    std.debug.assert(self.active_arena != null);
    defer self.active_arena = null;
    return .{ .inner = self.ringbuffer.commit(mark.inner), .arena = self.active_arena.? };
}

pub fn freeFromTail(self: *@This(), mark: TailMark) void {
    self.ringbuffer.freeFromTail(mark.inner);
    mark.arena.promote(self.gpa.allocator()).deinit();
}

fn isRingBufferAlloc(self: *@This(), memory: []u8) bool {
    return @intFromPtr(memory.ptr) >= @intFromPtr(self.ringbuffer.buffer.ptr) and
        @intFromPtr(memory.ptr) < @intFromPtr(self.ringbuffer.buffer.ptr) + self.ringbuffer.buffer.len;
}

pub fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    return self.ringbuffer.allocInner(len, alignment) catch {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawAlloc(len, alignment, ret_addr);
    };
}

pub fn resize(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    if (self.isRingBufferAlloc(memory)) {
        return RingBuffer.resize(&self.ringbuffer, memory, alignment, new_len, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawResize(memory, alignment, new_len, ret_addr);
    }
}

pub fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    if (self.isRingBufferAlloc(memory)) {
        return RingBuffer.remap(&self.ringbuffer, memory, alignment, new_len, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawRemap(memory, alignment, new_len, ret_addr);
    }
}

pub fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    if (self.isRingBufferAlloc(memory)) {
        RingBuffer.free(&self.ringbuffer, memory, alignment, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawFree(memory, alignment, ret_addr);
    }
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

const std = @import("std");
const RingBuffer = @import("RingBuffer.zig");
