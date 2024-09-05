const std = @import("std");

tps: f32 = 20.0,
tps_scale: f32 = 1.0,
timer: std.time.Timer,
total_ticks: usize = 0,
last_nanos: u64 = 0,

pub fn init() !@This() {
    return .{
        .timer = try .start(),
    };
}

pub const TicksElapsed = usize;
pub const PartialTick = f64;

/// Returns the amount of ticks elapsed since the last time `advance` was called and the progress from the last tick to the next
pub fn advance(self: *@This()) struct { TicksElapsed, PartialTick } {
    const current_nanos = self.timer.read();
    // the amount of ticks elapsed since the last time advance was called
    var ticks_elapsed: usize = 0;

    // this variable is stepped through each instant at which a tick occurs
    var nanos = self.last_nanos;
    while (true) {
        const next_tick_nanos = self.nextTickNanos(nanos);
        if (current_nanos < next_tick_nanos) {
            break;
        }
        nanos = next_tick_nanos;
        ticks_elapsed += 1;
    }
    const last_tick_nanos = self.lastTickNanos(nanos);
    const nanos_since_last_tick = current_nanos - last_tick_nanos;
    const partial_tick = @as(f64, @floatFromInt(nanos_since_last_tick)) / @as(f64, @floatFromInt(self.nanosPerTick()));
    self.last_nanos = current_nanos;

    if (ticks_elapsed > 10) ticks_elapsed = 10;
    self.total_ticks += ticks_elapsed;

    return .{ ticks_elapsed, partial_tick };
}

/// Calculates the amount of nanoseconds between each tick
pub fn nanosPerTick(self: @This()) u64 {
    const scaled_tps = self.tps * self.tps_scale;
    return @intFromFloat(@as(f32, std.time.ns_per_s) / scaled_tps);
}

/// Given the current time in nanoseconds, returns the last time in nanoseconds at which a tick occurred
pub fn lastTickNanos(self: *@This(), time: u64) u64 {
    const nanos_per_tick = self.nanosPerTick();

    const last_tick_ordinal = time / nanos_per_tick;
    return last_tick_ordinal * nanos_per_tick;
}

/// Given the current time in nanoseconds, returns the next time in nanoseconds at which a tick will occur
pub fn nextTickNanos(self: @This(), time: u64) u64 {
    const nanos_per_tick = self.nanosPerTick();

    const last_tick_ordinal = time / nanos_per_tick;
    const next_tick_ordinal = last_tick_ordinal + 1;

    return next_tick_ordinal * nanos_per_tick;
}
