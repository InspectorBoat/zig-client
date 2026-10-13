const std = @import("std");
const CompilationTask = @import("CompilationTask.zig");
const root = @import("root");

free_slots: std.heap.memory_pool.Extra(CompilationFuture, .{ .growable = false }),
completed: std.SinglyLinkedList = .{},
mutex: std.Io.Mutex = .init,

const CompilationFuture = struct {
    next_completed: std.SinglyLinkedList.Node,
    section_pos: root.Vector3(i32),
    revision: u32,
    future: std.Io.Future(CompilationTask.Error!CompilationTask.Result),
};

const CompilationResult = struct {
    section_pos: root.Vector3(i32),
    revision: u32,
    result: CompilationTask.Error!CompilationTask.Result,
};

pub fn init(gpa: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .free_slots = try .initCapacity(gpa, capacity),
    };
}

pub fn take(self: *@This(), section_pos: root.Vector3(i32), revision: u32) !*CompilationFuture {
    const compilation_future = try self.free_slots.create(undefined);
    compilation_future.* = .{
        .next_completed = .{},
        .section_pos = section_pos,
        .revision = revision,
        .future = undefined,
    };
    return compilation_future;
}

pub fn addCompleted(self: *@This(), io: std.Io, node: *std.SinglyLinkedList.Node) void {
    self.mutex.lockUncancelable(io);
    self.completed.prepend(node);
    self.mutex.unlock(io);
}

pub fn popCompleted(self: *@This(), io: std.Io) ?CompilationResult {
    self.mutex.lockUncancelable(io);
    self.mutex.unlock(io);

    if (self.completed.popFirst()) |node| {
        const in_flight: *CompilationFuture = @fieldParentPtr("next_completed", node);
        defer self.free_slots.destroy(in_flight);
        return .{
            .section_pos = in_flight.section_pos,
            .revision = in_flight.revision,
            .result = in_flight.future.await(io),
        };
    }
    return null;
}
