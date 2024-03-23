const std = @import("std");
const Vector2 = @import("main").Vector2;
const glfw = @import("mach-glfw");

window: glfw.Window,

events: std.fifo.LinearFifo(Event, .Dynamic),
keys: std.EnumArray(glfw.Key, bool) = std.EnumArray(glfw.Key, bool).initFill(false),
mouse_delta: Vector2(f64) = .{ .x = 0, .z = 0 },
mouse_pos: ?Vector2(f64) = null,
maximized: bool = false,
window_size: Vector2(i32) = .{ .x = 640, .z = 640 },

pub const Event = union(enum) {
    Pos: struct { xpos: i32, ypos: i32 },
    Size: struct { width: i32, height: i32 },
    Close,
    Refresh,
    Focus: struct { focused: bool },
    Iconify: struct { iconified: bool },
    Maximize: struct { maximized: bool },
    FramebufferSize: struct { width: u32, height: u32 },
    ContentScale: struct { xscale: f32, yscale: f32 },
    Key: struct { key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods },
    Char: struct { codepoint: u21 },
    MouseButton: struct { button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods },
    CursorPos: struct { xpos: f64, ypos: f64 },
    CursorEnter: struct { entered: bool },
    Scroll: struct { xoffset: f64, yoffset: f64 },
    Drop: struct { paths: [][*:0]const u8 },
};

pub fn init(window: glfw.Window, allocator: std.mem.Allocator) @This() {
    return .{
        .window = window,
        .events = std.fifo.LinearFifo(Event, .Dynamic).init(allocator),
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
        .xpos = xpos,
        .ypos = ypos,
    } }) catch unreachable;
}
pub fn sizeCallback(window: glfw.Window, width: i32, height: i32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{ .Size = .{
        .height = height,
        .width = width,
    } }) catch unreachable;
    window_input.window_size = .{ .x = width, .z = height };
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
        .Focus = .{ .focused = focused },
    }) catch unreachable;
}
pub fn iconifyCallback(window: glfw.Window, iconified: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Iconify = .{ .iconified = iconified },
    }) catch unreachable;
}
pub fn maximizeCallback(window: glfw.Window, maximized: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Maximize = .{ .maximized = maximized },
    }) catch unreachable;
    window_input.maximized = maximized;
}
pub fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .FramebufferSize = .{ .width = width, .height = height },
    }) catch unreachable;
}
pub fn contentScaleCallback(window: glfw.Window, xscale: f32, yscale: f32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .ContentScale = .{ .xscale = xscale, .yscale = yscale },
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
        .Char = .{ .codepoint = codepoint },
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
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .CursorPos = .{ .xpos = xpos, .ypos = ypos },
    }) catch unreachable;
    const new_pos = .{ .x = xpos, .z = ypos };
    if (window_input.mouse_pos) |prev_mouse_pos| {
        window_input.mouse_delta = window_input.mouse_delta.add(prev_mouse_pos.sub(new_pos));
    }
    window_input.mouse_pos = new_pos;
}
pub fn cursorEnterCallback(window: glfw.Window, entered: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .CursorEnter = .{ .entered = entered },
    }) catch unreachable;
}
pub fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.writeItem(.{
        .Scroll = .{ .xoffset = xoffset, .yoffset = yoffset },
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
