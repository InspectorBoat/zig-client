const std = @import("std");
const root = @import("root");
const Vector2xy = root.Vector2xy;

on_frame: std.fifo.LinearFifo(Input, .{ .Static = 256 }) = .init(),
on_tick: std.fifo.LinearFifo(Input, .{ .Static = 128 }) = .init(),

pub fn queueOnFrame(self: *@This(), input: Input) !void {
    try self.on_frame.writeItem(input);
}
pub fn queueOnTick(self: *@This(), input: Input) !void {
    try self.on_tick.writeItem(input);
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
        main: bool,
        pick: bool,
        use: bool,
        hotkey: struct { i32, bool },
        scroll: i32,
        drop: bool,
    },
    inventory: union(enum) {
        toggle,
        click_stack: usize,
        drag_stack: usize,
        release_drag,
        deposit_stack: usize,
        release_deposit: usize,
        drop_item: usize,
        drop_full_stack: usize,
    },
};
