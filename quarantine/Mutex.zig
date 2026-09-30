//! Minimal synchronization primitives.
//!
//! Simple spin-and-yield equivalents of the mutex and condition variable,
//! kept free of any `Io` dependency so existing call sites don't need one
//! threaded through them.

const std = @import("std");

pub const Mutex = struct {
    locked_flag: std.atomic.Value(bool) = .init(false),

    pub const init: Mutex = .{};

    pub fn tryLock(self: *Mutex) bool {
        return self.locked_flag.cmpxchgStrong(false, true, .acquire, .monotonic) == null;
    }

    pub fn lock(self: *Mutex) void {
        while (!self.tryLock()) {
            std.Thread.yield() catch {};
        }
    }

    pub fn unlock(self: *Mutex) void {
        self.locked_flag.store(false, .release);
    }
};

/// A condition variable that is signalled by bumping `epoch`.
///
/// `wait` must be called while holding `mutex`, and the caller must re-check
/// its predicate afterwards: this is a spin loop, so a signal arriving while
/// nobody is waiting is simply folded into the epoch.
pub const Condition = struct {
    epoch: std.atomic.Value(u32) = .init(0),

    pub const init: Condition = .{};

    pub fn wait(self: *Condition, mutex: *Mutex) void {
        // Read the epoch while still holding the mutex: any signal from now
        // on must come from a thread that could only enqueue after we unlock.
        const observed = self.epoch.load(.acquire);
        mutex.unlock();

        while (self.epoch.load(.acquire) == observed) {
            std.Thread.yield() catch {};
        }

        mutex.lock();
    }

    pub fn signal(self: *Condition) void {
        _ = self.epoch.fetchAdd(@as(u32, 1), .release);
    }

    pub fn broadcast(self: *Condition) void {
        self.signal();
    }
};

test "Mutex serializes access" {
    var mutex: Mutex = .init;
    try std.testing.expect(mutex.tryLock());
    mutex.unlock();

    mutex.lock();
    mutex.unlock();
}

test "Condition wait returns after a signal" {
    const Shared = struct {
        mutex: Mutex = .init,
        cond: Condition = .init,
        ready: bool = false,

        fn waiter(shared: *@This()) void {
            shared.mutex.lock();
            defer shared.mutex.unlock();
            while (!shared.ready) {
                shared.cond.wait(&shared.mutex);
            }
        }
    };

    var shared: Shared = .{};
    const thread = try std.Thread.spawn(.{}, Shared.waiter, .{&shared});

    shared.mutex.lock();
    shared.ready = true;
    shared.cond.signal();
    shared.mutex.unlock();

    thread.join();
    try std.testing.expect(shared.ready);
}
