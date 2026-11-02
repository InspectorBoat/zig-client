const window_ns: u64 = 1_000_000_000;
const capacity = 1024;

samples: [capacity]i96,
head: usize = 0, // oldest sample
len: usize = 0,

pub const init: @This() = .{ .samples = undefined };

/// Record a frame timestamp in monotonic nanoseconds.
pub fn update(self: *@This(), now_ns: i96) void {
    self.prune(now_ns);

    if (self.len < capacity) {
        const index = (self.head + self.len) % capacity;
        self.samples[index] = now_ns;
        self.len += 1;
    } else {
        // Keep the newest `capacity` timestamps if the buffer fills.
        self.samples[self.head] = now_ns;
        self.head = (self.head + 1) % capacity;
    }
}

/// Return the average FPS over the retained frame timestamps.
/// Call with the current monotonic time so old samples expire.
pub fn fps(self: *@This(), now_ns: i96) f64 {
    self.prune(now_ns);
    if (self.len < 2) return 0;

    const oldest = self.samples[self.head];
    const newest = self.samples[(self.head + self.len - 1) % capacity];
    const span_ns = newest - oldest;
    if (span_ns == 0) return 0;

    return @as(f64, @floatFromInt(self.len - 1)) *
        1_000_000_000.0 /
        @as(f64, @floatFromInt(span_ns));
}

fn prune(self: *@This(), now_ns: i96) void {
    const cutoff = if (now_ns >= window_ns) now_ns - window_ns else 0;

    while (self.len > 0 and self.samples[self.head] < cutoff) {
        self.head = (self.head + 1) % capacity;
        self.len -= 1;
    }
}
