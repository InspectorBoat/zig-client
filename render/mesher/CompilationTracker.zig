//! This is basically a (specialized) thread pool backed by an Io.Group and an Io.Queue

pending: std.Io.Queue(Task),
completed: std.Io.Queue(Completed),

group: std.Io.Group = .init,
pending_count: std.atomic.Value(u32) = .init(0),
completed_count: std.atomic.Value(u32) = .init(0),
total_count: u32 = 0,
unpaused: std.Io.Event = .is_set,

const Completed = struct {
    task: Task,
    result: Task.Error!Task.Mesh,
};

pub fn init(io: std.Io, gpa: std.mem.Allocator, queue_capacity: usize, workers: usize) !*@This() {
    std.debug.assert(queue_capacity != 0);
    std.debug.assert(workers != 0);

    const pending_buffer = try gpa.alloc(Task, queue_capacity);
    errdefer gpa.free(pending_buffer);
    const completed_buffer = try gpa.alloc(Completed, queue_capacity);
    errdefer gpa.free(completed_buffer);

    const tracker: *@This() = try gpa.create(@This());
    errdefer gpa.destroy(tracker);
    tracker.* = .{
        .completed = .init(completed_buffer),
        .pending = .init(pending_buffer),
    };
    errdefer tracker.group.cancel(io);

    for (0..workers) |_| {
        try tracker.group.concurrent(io, worker, .{ io, gpa, tracker });
    }
    return tracker;
}

fn worker(io: std.Io, gpa: std.mem.Allocator, tracker: *@This()) void {
    while (true) {
        tracker.unpaused.wait(io) catch return;

        const task = tracker.pending.getOne(io) catch return;
        _ = tracker.pending_count.fetchSub(1, .release);

        tracker.completed.putOneUncancelable(io, .{ .task = task, .result = task.compile(gpa) }) catch unreachable;
        _ = tracker.completed_count.fetchAdd(1, .release);
    }
}

pub fn spawn(self: *@This(), io: std.Io, world: *const World, section_pos: main.Vector3(i32), revision: u32) error{ Canceled, QueueFull, Closed }!void {
    const task: Task = try .init(world, section_pos, revision);
    errdefer task.deinit(.failing);
    switch (try self.pending.put(io, &.{task}, 0)) {
        0 => return error.QueueFull,
        1 => {
            self.total_count += 1;
            _ = self.pending_count.fetchAdd(1, .monotonic);
        },
        else => unreachable,
    }
}

pub fn popCompleted(self: *@This(), io: std.Io, gpa: std.mem.Allocator) !?Completed {
    if (self.completed_count.load(.acquire) == 0) return null;
    var completed: Completed = undefined;
    switch (self.completed.getUncancelable(io, (&completed)[0..1], 0) catch unreachable) {
        0 => unreachable,
        1 => {
            completed.task.deinit(gpa);
            self.total_count -= 1;
            _ = self.completed_count.fetchSub(1, .acquire);
            return completed;
        },
        else => unreachable,
    }
}

/// Pauses compilation and cancels all outstanding tasks and free the pool
pub fn pauseAndCancelAll(self: *@This(), io: std.Io, gpa: std.mem.Allocator) void {
    self.unpaused.reset();

    while (self.total_count != 0) {
        var pending: Task = undefined;
        if (1 == self.pending.getUncancelable(io, (&pending)[0..1], 0) catch unreachable) {
            pending.deinit(gpa);
            self.total_count -= 1;
            continue;
        }

        var completed: Completed = undefined;
        if (1 == self.completed.getUncancelable(io, (&completed)[0..1], 0) catch unreachable) {
            completed.task.deinit(gpa);
            if (completed.result) |*result| result.buffer.deinit(gpa) else |_| {}
            self.total_count -= 1;
            continue;
        }
    }

    self.completed_count.store(0, .monotonic);
    self.pending_count.store(0, .monotonic);
}

/// Drain all outstanding tasks and free the pool
pub fn deinit(self: *@This(), io: std.Io, gpa: std.mem.Allocator) void {
    self.pauseAndCancelAll(io, gpa);

    self.group.cancel(io);
    self.pending.close(io);
    self.completed.close(io);

    std.debug.assert(self.pending.getOneUncancelable(io) == error.Closed);
    std.debug.assert(self.completed.getOneUncancelable(io) == error.Closed);

    gpa.free(@as([]Task, @ptrCast(@alignCast(self.pending.type_erased.buffer))));
    gpa.free(@as([]Completed, @ptrCast(@alignCast(self.completed.type_erased.buffer))));
    gpa.destroy(self);
}

const std = @import("std");

const main = @import("main");
const render = @import("render");

const Task = render.mesher.CompilationTask;
const World = main.World;
