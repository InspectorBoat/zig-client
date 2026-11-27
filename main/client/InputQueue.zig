on_frame: std.Deque(Input),
on_tick: std.Deque(Input),

pub const empty: @This() = .{
    .on_frame = .empty,
    .on_tick = .empty,
};

pub fn initCapacity(gpa: std.mem.Allocator, capacity: usize) !@This() {
    return .{
        .on_frame = try .initCapacity(gpa, capacity),
        .on_tick = try .initCapacity(gpa, capacity),
    };
}

pub fn deinit(self: *@This(), gpa: std.mem.Allocator) void {
    self.on_frame.deinit(gpa);
    self.on_tick.deinit(gpa);
}

pub fn queueOnFrame(self: *@This(), gpa: std.mem.Allocator, input: Input) !void {
    try self.on_frame.pushBack(gpa, input);
}
pub fn queueOnTick(self: *@This(), gpa: std.mem.Allocator, input: Input) !void {
    try self.on_tick.pushBack(gpa, input);
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
    menu_button: struct {
        button_id: i8,
    },
    /// Text input for anvil renaming / sign editing.
    char: u21,
    text_backspace,
    sign_row: i8,
};

const std = @import("std");

const main = @import("main");

const Menu = main.Menu;
const Vector2xy = main.Vector2xy;
