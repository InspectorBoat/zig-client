ring_allocator: RingAllocator,
gpa: std.heap.SafeAllocator,
active_arena: ?std.heap.ArenaAllocator.State = null,

pub const TailMark = struct {
    inner: RingAllocator.TailMark,
    arena: std.heap.ArenaAllocator.State,
};

pub const RewindMark = struct {
    inner: RingAllocator.RewindMark,
};

pub fn initCapacity(io: std.Io, backing_allocator: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .ring_allocator = try .initCapacity(io, capacity),
        .gpa = .init(backing_allocator, .{}),
    };
}

pub fn deinit(self: *@This()) void {
    self.ring_allocator.deinit();
    _ = self.gpa.deinitLog(false);
}

pub fn ringBufferUsed(self: *@This()) usize {
    return self.ring_allocator.usedBytes();
}

pub fn beginRegion(self: *@This()) RewindMark {
    std.debug.assert(self.active_arena == null);
    self.active_arena = .init;
    return .{ .inner = self.ring_allocator.beginRegion() };
}

pub fn rewind(self: *@This(), mark: RewindMark) void {
    std.debug.assert(self.active_arena != null);
    self.ring_allocator.rewind(mark.inner);
    self.active_arena.?.promote(self.gpa.allocator()).deinit();
    self.active_arena = null;
}

pub fn commit(self: *@This(), mark: RewindMark) TailMark {
    std.debug.assert(self.active_arena != null);
    defer self.active_arena = null;
    return .{ .inner = self.ring_allocator.commit(mark.inner), .arena = self.active_arena.? };
}

pub fn freeFromTail(self: *@This(), mark: TailMark) void {
    self.ring_allocator.freeFromTail(mark.inner);
    mark.arena.promote(self.gpa.allocator()).deinit();
}

fn isRingBufferAlloc(self: *@This(), memory: []u8) bool {
    return @intFromPtr(memory.ptr) >= @intFromPtr(self.ring_allocator.buffer) and
        @intFromPtr(memory.ptr) < @intFromPtr(self.ring_allocator.buffer) + self.ring_allocator.capacity;
}

pub fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    std.debug.assert(self.ring_allocator.safety.active_rewind_index != null);

    return RingAllocator.alloc(&self.ring_allocator, len, alignment, ret_addr) orelse {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawAlloc(len, alignment, ret_addr);
    };
}

pub fn resize(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    std.debug.assert(self.ring_allocator.safety.active_rewind_index != null);

    if (self.isRingBufferAlloc(memory)) {
        return RingAllocator.resize(&self.ring_allocator, memory, alignment, new_len, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawResize(memory, alignment, new_len, ret_addr);
    }
}

pub fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    std.debug.assert(self.ring_allocator.safety.active_rewind_index != null);

    if (self.isRingBufferAlloc(memory)) {
        return RingAllocator.remap(&self.ring_allocator, memory, alignment, new_len, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        return arena.allocator().rawRemap(memory, alignment, new_len, ret_addr);
    }
}

pub fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    std.debug.assert(self.ring_allocator.safety.active_rewind_index != null);

    if (self.isRingBufferAlloc(memory)) {
        RingAllocator.free(&self.ring_allocator, memory, alignment, ret_addr);
    } else {
        var arena = self.active_arena.?.promote(self.gpa.allocator());
        defer self.active_arena = arena.state;
        arena.allocator().rawFree(memory, alignment, ret_addr);
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

const RingAllocator = @import("RingAllocator.zig");
