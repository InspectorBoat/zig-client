//! This is basically a (specialized) thread pool backed by an Io.Group and an Io.Queue

group: *std.Io.Group,
pending: *std.Io.Queue(Task),
completed: *std.Io.Queue(Completed),
live: usize,
pending_count: *std.atomic.Value(usize),

const Completed = struct {
    task: Task,
    result: Task.Error!Task.Mesh,
};

pub fn initCapacity(io: std.Io, gpa: std.mem.Allocator, pending_capacity: usize, workers: usize) !@This() {
    const pending_buffer = try gpa.alloc(Task, pending_capacity);
    errdefer gpa.free(pending_buffer);
    const completed_buffer = try gpa.alloc(Completed, pending_capacity);
    errdefer gpa.free(completed_buffer);

    const pending: *std.Io.Queue(Task) = try gpa.create(std.Io.Queue(Task));
    errdefer gpa.destroy(pending);
    const completed: *std.Io.Queue(Completed) = try gpa.create(std.Io.Queue(Completed));
    errdefer gpa.destroy(completed);

    const group: *std.Io.Group = try gpa.create(std.Io.Group);
    const count: *std.atomic.Value(usize) = try gpa.create(std.atomic.Value(usize));
    count.* = .init(0);

    pending.* = .init(pending_buffer);
    completed.* = .init(completed_buffer);
    group.* = .init;

    for (0..workers) |_| {
        try group.concurrent(io, worker, .{ io, gpa, pending, completed, count });
    }
    return .{
        .group = group,
        .pending = pending,
        .completed = completed,
        .live = 0,
        .pending_count = count,
    };
}

fn worker(io: std.Io, gpa: std.mem.Allocator, pending: *std.Io.Queue(Task), completed: *std.Io.Queue(Completed), pending_count: *std.atomic.Value(usize)) void {
    while (true) {
        const task = pending.getOne(io) catch return;
        completed.putOneUncancelable(io, .{ .task = task, .result = task.compile(io, gpa) }) catch unreachable;
        _ = pending_count.fetchSub(1, .monotonic);
    }
}

pub fn spawn(self: *@This(), io: std.Io, world: *const World, section_pos: main.Vector3(i32), revision: u32) error{ Canceled, QueueFull, Closed }!void {
    const task: Task = try .init(world, section_pos, revision);
    errdefer task.deinit(.failing);
    switch (try self.pending.put(io, &.{task}, 0)) {
        0 => return error.QueueFull,
        1 => {
            self.live += 1;
            _ = self.pending_count.fetchAdd(1, .monotonic);
        },
        else => unreachable,
    }
}

pub fn popCompleted(self: *@This(), io: std.Io, gpa: std.mem.Allocator) !?Completed {
    if (self.live == 0) return null;
    var completed: Completed = undefined;
    if (self.completed.getUncancelable(io, (&completed)[0..1], 0) catch unreachable == 1) {
        completed.task.deinit(gpa);
        self.live -= 1;
        return completed;
    } else return null;
}

/// Cancel all outstanding tasks and free the pool
pub fn deinit(self: *@This(), gpa: std.mem.Allocator, io: std.Io) void {
    for (0..self.live) |_| {
        const completed = self.completed.getOneUncancelable(io) catch unreachable;
        completed.task.deinit(gpa);
    }
    self.group.cancel(io);
    self.pending.close(io);
    self.completed.close(io);

    std.debug.assert(self.pending.getOneUncancelable(io) == error.Closed);
    std.debug.assert(self.completed.getOneUncancelable(io) == error.Closed);
}

const std = @import("std");

const main = @import("main");
const render = @import("render");

const Task = render.mesher.CompilationTask;
const World = main.World;
