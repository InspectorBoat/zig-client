tps: f32 = 20.0,
start: std.Io.Timestamp,
last: std.Io.Timestamp,
total_ticks: usize = 0,

pub fn init(io: std.Io) !@This() {
    const now: std.Io.Timestamp = .now(io, .awake);
    return .{
        .start = now,
        .last = now,
    };
}

pub const TicksElapsed = usize;
pub const PartialTick = f64;

/// Returns the amount of ticks elapsed since the last time `advance` was called and the progress from the last tick to the next
pub fn advance(self: *@This(), io: std.Io) struct { TicksElapsed, PartialTick } {
    const now: std.Io.Timestamp = .now(io, .awake);
    defer self.last = now;

    const last_tick_ordinal = tickOrdinal(self.last, self.tps);
    const current_tick_ordinal = tickOrdinal(now, self.tps);

    const ticks_elapsed: usize = @intCast(current_tick_ordinal - last_tick_ordinal);

    const last_tick = lastTick(now, self.tps);
    const partial_tick = std.math.lossyCast(f64, last_tick.durationTo(now).nanoseconds) / std.time.ns_per_s * self.tps;
    return .{ @min(ticks_elapsed, 10), partial_tick };
}

pub fn nanosPerTick(tps: f32) i96 {
    return @intFromFloat(@as(f32, std.time.ns_per_s) / tps);
}

pub fn tickOrdinal(timestamp: std.Io.Timestamp, tps: f32) i96 {
    const nanos_per_tick: i96 = nanosPerTick(tps);

    return @divFloor(timestamp.nanoseconds, nanos_per_tick);
}

pub fn lastTick(timestamp: std.Io.Timestamp, tps: f32) std.Io.Timestamp {
    const nanos_per_tick: i96 = nanosPerTick(tps);

    return .{ .nanoseconds = @divFloor(timestamp.nanoseconds, nanos_per_tick) * nanos_per_tick };
}

const std = @import("std");
