const std = @import("std");

/// Monotonic nanoseconds, since an unspecified point in the past.
pub fn monotonicNanos() u64 {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    return @intCast(std.Io.Clock.awake.now(io).nanoseconds);
}

pub const Timer = struct {
    start: u64,

    pub fn init() @This() {
        return .{ .start = monotonicNanos() };
    }

    pub inline fn ns(self: @This()) f64 {
        return @floatFromInt(monotonicNanos() - self.start);
    }

    pub inline fn ms(self: @This()) f64 {
        return self.ns() / @as(f64, @floatFromInt(std.time.ns_per_ms));
    }
};

test "monotonic clock advances and Timer measures elapsed time" {
    const first = monotonicNanos();
    const second = monotonicNanos();
    try std.testing.expect(second >= first);

    const timer: Timer = .init();
    try std.testing.expect(timer.ns() >= 0);
}
