//! A minimal fixed-size thread pool.
//!
//! Tasks are type-erased: each one is copied into a heap-allocated closure
//! that a worker thread runs and then frees.

const std = @import("std");
const Mutex = @import("Mutex.zig").Mutex;
const Condition = @import("Mutex.zig").Condition;

/// A type-erased queued task. Only ever created by `ThreadPool.spawn`.
const Task = struct {
    run: *const fn (*anyopaque, *ThreadPool) void,
    context: *anyopaque,
};

pub const ThreadPool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    queue: std.Deque(Task),
    mutex: Mutex = .{},
    /// Signalled when a task is queued or when the pool is shutting down.
    cond: Condition = .{},
    threads: []std.Thread = &.{},
    /// How many entries of `threads` have actually been spawned.
    spawned: usize = 0,
    shutdown: bool = false,

    pub const Options = struct {
        /// Number of worker threads to run tasks on.
        n_jobs: usize = 1,
    };

    /// `self` must have been allocated with `allocator`, and must not be
    /// initialized already.
    pub fn init(self: *Self, allocator: std.mem.Allocator, options: Options) !void {
        self.* = .{
            .allocator = allocator,
            .queue = .empty,
            .threads = &.{},
        };

        self.threads = try allocator.alloc(std.Thread, options.n_jobs);
        errdefer {
            // Ask the workers we did start to exit, then reclaim the array.
            self.mutex.lock();
            self.shutdown = true;
            self.cond.broadcast();
            self.mutex.unlock();
            for (self.threads[0..self.spawned]) |thread| thread.join();
            allocator.free(self.threads);
        }

        for (self.threads) |*thread| {
            thread.* = try std.Thread.spawn(.{}, worker, .{self});
            self.spawned += 1;
        }
    }

    /// Blocks until every queued task has finished.
    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        self.shutdown = true;
        self.cond.broadcast();
        self.mutex.unlock();

        for (self.threads) |thread| thread.join();
        self.allocator.free(self.threads);
        self.threads = &.{};
        self.spawned = 0;

        self.queue.deinit(self.allocator);
    }

    /// Queues `func(args...)` to run on a worker thread. Returns as soon as
    /// the task is queued; the arguments are copied into the queue.
    pub fn spawn(self: *Self, comptime func: anytype, args: anytype) !void {
        const Args = @TypeOf(args);

        // One closure type per (function, argument type) pair, so that the
        // concrete argument type survives being type-erased. `func` is
        // captured at comptime rather than stored, so no runtime function
        // pointer is needed.
        const Closure = struct {
            args: Args,

            pub fn run(context: *anyopaque, pool: *ThreadPool) void {
                const closure: *@This() = @ptrCast(@alignCast(context));
                @call(.auto, func, closure.args);
                pool.allocator.destroy(closure);
            }
        };

        const closure = try self.allocator.create(Closure);
        errdefer self.allocator.destroy(closure);
        closure.* = .{ .args = args };

        self.mutex.lock();
        defer self.mutex.unlock();
        // Worker threads only exit once shutdown is set and the queue has
        // drained, so there is nothing to reject here.
        self.queue.pushBack(self.allocator, .{ .run = Closure.run, .context = closure }) catch {
            self.allocator.destroy(closure);
            return error.OutOfMemory;
        };
        self.cond.signal();
    }

    fn worker(self: *Self) void {
        while (true) {
            self.mutex.lock();
            while (self.queue.len == 0 and !self.shutdown) {
                self.cond.wait(&self.mutex);
            }
            if (self.queue.len == 0) {
                // Only reachable once shutdown is set and the queue is empty.
                self.mutex.unlock();
                return;
            }
            const task = self.queue.popFront().?;
            self.mutex.unlock();

            task.run(task.context, self);
        }
    }
};

test "ThreadPool runs every queued task before deinit returns" {
    const Counter = struct {
        var mutex: Mutex = .init;
        var value: usize = 0;

        fn increment(_: *usize) void {
            mutex.lock();
            defer mutex.unlock();
            value += 1;
        }
    };

    var pool: ThreadPool = undefined;
    try pool.init(std.testing.allocator, .{ .n_jobs = 1 });

    var dummy: usize = 0;
    try pool.spawn(Counter.increment, .{&dummy});
    try pool.spawn(Counter.increment, .{&dummy});
    try pool.spawn(Counter.increment, .{&dummy});

    // deinit drains the queue before joining, so no explicit wait is needed.
    pool.deinit();

    Counter.mutex.lock();
    defer Counter.mutex.unlock();
    try std.testing.expectEqual(@as(usize, 3), Counter.value);
}
