const quarantine = @import("llm-code-quarantine");
const main = @import("main");

const Vector2xy = main.Vector2xy;
const Menu = main.Menu;

on_frame: quarantine.FixedFifo(Input, 256) = .init(),
on_tick: quarantine.FixedFifo(Input, 128) = .init(),

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
