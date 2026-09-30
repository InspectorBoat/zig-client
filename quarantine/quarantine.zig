//! Replacement implementations for library surface that is absent from the
//! current Zig standard library.
//!
//! Nothing here is original to zig-client; each module stands in for a
//! `std` facility and is kept out of `util/` so the two are not confused.

const std = @import("std");

pub const Fifo = @import("Fifo.zig").Fifo;
pub const FixedFifo = @import("Fifo.zig").FixedFifo;
pub const ThreadPool = @import("ThreadPool.zig").ThreadPool;
pub const Mutex = @import("Mutex.zig").Mutex;
pub const Condition = @import("Mutex.zig").Condition;
pub const Timer = @import("Timer.zig").Timer;
pub const monotonicNanos = @import("Timer.zig").monotonicNanos;

test {
    _ = @import("Fifo.zig");
    _ = @import("Mutex.zig");
    _ = @import("ThreadPool.zig");
    _ = @import("Timer.zig");
}
