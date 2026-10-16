const std = @import("std");

const main = @import("main");

const CompilationTask = @import("CompilationTask.zig");

gpa: std.mem.Allocator,
free_slots: std.heap.memory_pool.Extra(CompilationSlot, .{ .growable = false }),
/// Every slot handed out but not yet collected with popCompleted, running or not.
outstanding: std.SinglyLinkedList = .{},
completed: std.SinglyLinkedList = .{},
mutex: std.Io.Mutex = .init,

const CompilationSlot = struct {
    next_outstanding: std.SinglyLinkedList.Node,
    next_completed: std.SinglyLinkedList.Node,
    section_pos: main.Vector3(i32),
    revision: u32,
    future: std.Io.Future(CompilationTask.Error!CompilationTask.Mesh),
};

const CompletedCompilation = struct {
    section_pos: main.Vector3(i32),
    revision: u32,
    mesh: CompilationTask.Error!CompilationTask.Mesh,
};

pub fn init(gpa: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .gpa = gpa,
        .free_slots = try .initCapacity(gpa, capacity),
    };
}

pub fn take(self: *@This(), section_pos: main.Vector3(i32), revision: u32) error{QueueFull}!*CompilationSlot {
    const slot = self.free_slots.create(undefined) catch return error.QueueFull;
    slot.* = .{
        .next_outstanding = .{},
        .next_completed = .{},
        .section_pos = section_pos,
        .revision = revision,
        .future = undefined,
    };
    self.outstanding.prepend(&slot.next_outstanding);
    return slot;
}

pub fn addCompleted(self: *@This(), io: std.Io, completion_token: *std.SinglyLinkedList.Node) void {
    self.mutex.lockUncancelable(io);
    self.completed.prepend(completion_token);
    self.mutex.unlock(io);
}

pub fn popCompleted(self: *@This(), io: std.Io) ?CompletedCompilation {
    self.mutex.lockUncancelable(io);
    const maybe_node = self.completed.popFirst();
    self.mutex.unlock(io);

    const node = maybe_node orelse return null;

    const slot: *CompilationSlot = @fieldParentPtr("next_completed", node);
    self.outstanding.remove(&slot.next_outstanding);
    defer self.free_slots.destroy(slot);
    return .{
        .section_pos = slot.section_pos,
        .revision = slot.revision,
        .mesh = slot.future.await(io),
    };
}

/// Release a slot whose task was never started, so `future` is still
/// undefined. Callers must guarantee no task exists for it; otherwise this
/// strands that task's `addCompleted`. Main thread only.
pub fn releaseUnstarted(self: *@This(), slot: *CompilationSlot) void {
    self.outstanding.remove(&slot.next_outstanding);
    self.free_slots.destroy(slot);
}

/// Cancel everything still outstanding and free the pool. A task that finishes
/// while we're draining will still link itself onto `completed` on the way out.
/// Nothing reads that list after this, so this is fine.
pub fn deinit(self: *@This(), io: std.Io) void {
    while (self.outstanding.popFirst()) |node| {
        const slot: *CompilationSlot = @fieldParentPtr("next_outstanding", node);
        if (slot.future.cancel(io)) |mesh_const| {
            var mesh = mesh_const;
            mesh.buffer.deinit(self.gpa);
        } else |_| {}
        self.free_slots.destroy(slot);
    }
    self.free_slots.deinit(self.gpa);
}
