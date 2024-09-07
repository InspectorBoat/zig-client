const std = @import("std");
const Vector2xy = @import("root").Vector2xy;
const glfw = @import("mach-glfw");

window: glfw.Window,

events: std.fifo.LinearFifo(Event, .Dynamic),
keys: std.EnumArray(glfw.Key, bool) = .initFill(false),
mouse_pos: ?Vector2xy(f64) = null,
maximized: bool = false,
window_size: Vector2xy(i32) = .{ .x = 640, .y = 640 },

pub const Event = union(enum) {
    Pos: Vector2xy(i32),
    Size: Vector2xy(i32),
    Close,
    Refresh,
    Focus: bool,
    Iconify: bool,
    Maximize: bool,
    FramebufferSize: Vector2xy(u32),
    ContentScale: Vector2xy(f32),
    Key: struct { key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods },
    /// Codepoint
    Char: u21,
    MouseButton: struct { button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods },
    CursorPos: struct { pos: Vector2xy(f64), delta: Vector2xy(f64) },
    CursorEnter: bool,
    Scroll: Vector2xy(f64),
    Drop: struct { paths: [][*:0]const u8 },
};

pub fn init(window: glfw.Window, allocator: std.mem.Allocator) @This() {
    return .{
        .window = window,
        .events = .init(allocator),
    };
}

pub fn setGlfwInputCallbacks(self: *@This()) void {
    self.window.setUserPointer(self);

    self.window.setPosCallback(posCallback);
    self.window.setSizeCallback(sizeCallback);
    self.window.setCloseCallback(closeCallback);
    self.window.setRefreshCallback(refreshCallback);
    self.window.setFocusCallback(focusCallback);
    self.window.setIconifyCallback(iconifyCallback);
    self.window.setMaximizeCallback(maximizeCallback);
    self.window.setFramebufferSizeCallback(framebufferSizeCallback);
    self.window.setContentScaleCallback(contentScaleCallback);
    self.window.setKeyCallback(keyCallback);
    self.window.setCharCallback(charCallback);
    self.window.setMouseButtonCallback(mouseButtonCallback);
    self.window.setCursorPosCallback(cursorPosCallback);
    self.window.setCursorEnterCallback(cursorEnterCallback);
    self.window.setScrollCallback(scrollCallback);
    self.window.setDropCallback(dropCallback);
}

pub fn posCallback(window: glfw.Window, xpos: i32, ypos: i32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{ .Pos = .{
        .x = xpos,
        .y = ypos,
    } }) catch unreachable;
}
pub fn sizeCallback(window: glfw.Window, width: i32, height: i32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{ .Size = .{
        .x = height,
        .y = width,
    } }) catch unreachable;
    window_input.window_size = .{ .x = width, .y = height };
}
pub fn closeCallback(window: glfw.Window) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.Close) catch unreachable;
}
pub fn refreshCallback(window: glfw.Window) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.Refresh) catch unreachable;
}
pub fn focusCallback(window: glfw.Window, focused: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Focus = focused,
    }) catch unreachable;
}
pub fn iconifyCallback(window: glfw.Window, iconified: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Iconify = iconified,
    }) catch unreachable;
}
pub fn maximizeCallback(window: glfw.Window, maximized: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Maximize = maximized,
    }) catch unreachable;
    window_input.maximized = maximized;
}
pub fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .FramebufferSize = .{ .x = width, .y = height },
    }) catch unreachable;
}
pub fn contentScaleCallback(window: glfw.Window, xscale: f32, yscale: f32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .ContentScale = .{ .x = xscale, .y = yscale },
    }) catch unreachable;
}
pub fn keyCallback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Key = .{ .key = key, .scancode = scancode, .action = action, .mods = mods },
    }) catch unreachable;
    window_input.keys.set(key, if (action == .release) false else true);
}
pub fn charCallback(window: glfw.Window, codepoint: u21) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Char = codepoint,
    }) catch unreachable;
}
pub fn mouseButtonCallback(window: glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .MouseButton = .{ .button = button, .action = action, .mods = mods },
    }) catch unreachable;
}

pub fn cursorPosCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    var window_input: *@This() = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    const pos: Vector2xy(f64) = .{ .x = xpos, .y = ypos };
    const delta: Vector2xy(f64) = if (window_input.mouse_pos) |prev_pos| prev_pos.sub(pos) else .{ .x = 0, .y = 0 };

    window_input.events.writeItem(.{
        .CursorPos = .{ .pos = pos, .delta = delta },
    }) catch unreachable;

    window_input.mouse_pos = pos;
}
pub fn cursorEnterCallback(window: glfw.Window, entered: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .CursorEnter = entered,
    }) catch unreachable;
}
pub fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Scroll = .{ .x = xoffset, .y = yoffset },
    }) catch unreachable;
}
pub fn dropCallback(window: glfw.Window, paths: [][*:0]const u8) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Drop = .{ .paths = paths },
    }) catch unreachable;
}
