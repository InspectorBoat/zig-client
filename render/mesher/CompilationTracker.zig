gpa: std.mem.Allocator,
free_slots: std.heap.memory_pool.Extra(Slot, .{ .growable = false }),
outstanding: std.SinglyLinkedList = .{},
completed: std.SinglyLinkedList = .{},
mutex: std.Io.Mutex = .init,

const Slot = struct {
    next_outstanding: std.SinglyLinkedList.Node,
    next_completed: std.SinglyLinkedList.Node,
    future: std.Io.Future(Task.Error!Task.Mesh),
    section_pos: main.Vector3(i32),
    task: Task,
    revision: u32,
};
const Completed = struct {
    section_pos: main.Vector3(i32),
    revision: u32,
    mesh: Task.Error!Task.Mesh,
};

pub fn init(gpa: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .gpa = gpa,
        .free_slots = try .initCapacity(gpa, capacity),
    };
}

/// Claim an empty slot
pub fn claimSlot(self: *@This(), section_pos: main.Vector3(i32), revision: u32) error{QueueFull}!*Slot {
    const slot = self.free_slots.create(.failing) catch return error.QueueFull;
    slot.* = .{
        .next_outstanding = .{},
        .next_completed = .{},
        .section_pos = section_pos,
        .revision = revision,
        .task = undefined,
        .future = undefined,
    };
    self.outstanding.prepend(&slot.next_outstanding);
    return slot;
}

/// Release a slot whose task was never started
pub fn releaseUnstarted(self: *@This(), slot: *Slot) void {
    self.outstanding.remove(&slot.next_outstanding);
    self.free_slots.destroy(slot);
}

pub fn addCompleted(self: *@This(), io: std.Io, completion_token: *std.SinglyLinkedList.Node) void {
    self.mutex.lockUncancelable(io);
    self.completed.prepend(completion_token);
    self.mutex.unlock(io);
}

pub fn popCompleted(self: *@This(), io: std.Io, gpa: std.mem.Allocator) ?Completed {
    self.mutex.lockUncancelable(io);
    const maybe_node = self.completed.popFirst();
    self.mutex.unlock(io);

    const node = maybe_node orelse return null;

    const slot: *Slot = @fieldParentPtr("next_completed", node);
    slot.task.deinit(gpa);
    self.outstanding.remove(&slot.next_outstanding);
    defer self.free_slots.destroy(slot);
    return .{
        .section_pos = slot.section_pos,
        .revision = slot.revision,
        .mesh = slot.future.await(io),
    };
}

/// Cancel all outstanding tasks and free the pool
pub fn deinit(self: *@This(), gpa: std.mem.Allocator, io: std.Io) void {
    while (self.outstanding.popFirst()) |node| {
        const slot: *Slot = @fieldParentPtr("next_outstanding", node);
        slot.task.deinit(gpa);
        if (slot.future.cancel(io)) |mesh_const| {
            var mesh = mesh_const;
            mesh.buffer.deinit(self.gpa);
        } else |_| {}
        self.free_slots.destroy(slot);
    }
    self.free_slots.deinit(self.gpa);
}

const std = @import("std");

const main = @import("main");
const render = @import("render");

const Task = render.mesher.CompilationTask;
