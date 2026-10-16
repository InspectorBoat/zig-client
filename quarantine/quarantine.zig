//! Replacement implementations for library surface that is absent from the
//! current Zig standard library.
//!
//! Nothing here is original to zig-client; each module stands in for a
//! `std` facility and is kept out of `util/` so the two are not confused.

pub const MathHelper = @import("MathHelper.zig");
pub const FixedFifo = @import("Fifo.zig").FixedFifo;
pub const Condition = @import("Mutex.zig").Condition;
pub const Mutex = @import("Mutex.zig").Mutex;
pub const ThreadPool = @import("ThreadPool.zig").ThreadPool;

test {
    _ = @import("Fifo.zig");
    _ = @import("Mutex.zig");
    _ = @import("ThreadPool.zig");
}
