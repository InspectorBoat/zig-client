on_frame: std.Deque(Input),
on_tick: std.Deque(Input),

pub const empty: @This() = .{
    .on_frame = .empty,
    .on_tick = .empty,
};

pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .on_frame = try .initCapacity(allocator, capacity),
        .on_tick = try .initCapacity(allocator, capacity),
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    self.on_frame.deinit(allocator);
    self.on_tick.deinit(allocator);
}

pub fn queueOnFrame(self: *@This(), allocator: std.mem.Allocator, input: Input) !void {
    try self.on_frame.pushBack(allocator, input);
}
pub fn queueOnTick(self: *@This(), allocator: std.mem.Allocator, input: Input) !void {
    try self.on_tick.pushBack(allocator, input);
}

pub const Input = union(enum) {
    rotate: Vector2xy(i32),
    movement: union(enum) {
        forward: bool,
        left: bool,
        right: bool,
        back: bool,
        jump: bool,
        sprint: bool,
        sneak: bool,
    },
    hand: union(enum) {
        attack: bool,
        pick: bool,
        use: bool,
        hotkey: i32,
        scroll: i32,
        drop: bool,
    },
    open_screen,
    close_screen,
    inventory: Menu.Action,
};

const std = @import("std");

const main = @import("main");

const Menu = main.Menu;
const Vector2xy = main.Vector2xy;
