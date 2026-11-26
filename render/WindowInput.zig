window: glfw.Window,

events: std.Deque(Event),
allocator: std.mem.Allocator,
keys: std.EnumSet(glfw.Key) = .empty,
mouse_pos: Vector2xy(f64) = .{ .x = 0, .y = 0 },
last_set_mouse_input_mode: glfw.Window.InputModeCursor = .normal,
maximized: bool = false,
window_size: Vector2xy(i32) = .{ .x = 640, .y = 640 },
framebuffer_size: Vector2xy(u32) = .{ .x = 640, .y = 640 },

pub const Event = union(enum) {
    pos: Vector2xy(i32),
    size: Vector2xy(i32),
    close,
    refresh,
    focus: bool,
    iconify: bool,
    maximize: bool,
    framebuffer_size: Vector2xy(u32),
    content_scale: Vector2xy(f32),
    key: struct { key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods },
    /// Codepoint
    char: u21,
    mouse_button: struct { button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods },
    cursor_pos: struct { pos: Vector2xy(f64), delta: Vector2xy(f64) },
    cursor_enter: bool,
    scroll: Vector2xy(f64),
    drop: struct { paths: [][*:0]const u8 },
};

pub fn init(allocator: std.mem.Allocator, window: glfw.Window) @This() {
    return .{
        .window = window,
        .events = .empty,
        .allocator = allocator,
    };
}

pub fn deinit(self: *@This()) void {
    self.events.deinit(self.allocator);
}

pub fn mousePosInClipSpace(self: *const @This()) Vector2xy(f32) {
    const window_size: Vector2xy(f32) = .floatFromInt(self.window_size);

    const normalized: Vector2xy(f32) = .sub(
        .mul(
            .div(.floatCast(self.mouse_pos), window_size),
            .splat(2),
        ),
        .splat(1),
    );

    return .floatCast(.{ .x = normalized.x, .y = -normalized.y });
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
    window_input.events.pushBack(window_input.allocator, .{ .pos = .{
        .x = xpos,
        .y = ypos,
    } }) catch unreachable;
}
pub fn sizeCallback(window: glfw.Window, width: i32, height: i32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{ .size = .{
        .x = width,
        .y = height,
    } }) catch unreachable;
    window_input.window_size = .{ .x = width, .y = height };
}
pub fn closeCallback(window: glfw.Window) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .close) catch unreachable;
}
pub fn refreshCallback(window: glfw.Window) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .refresh) catch unreachable;
}
pub fn focusCallback(window: glfw.Window, focused: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .focus = focused,
    }) catch unreachable;
}
pub fn iconifyCallback(window: glfw.Window, iconified: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .iconify = iconified,
    }) catch unreachable;
}
pub fn maximizeCallback(window: glfw.Window, maximized: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .maximize = maximized,
    }) catch unreachable;
    std.log.scoped(.window).debug("maximized: {}", .{maximized});
    window_input.maximized = maximized;
}
pub fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .framebuffer_size = .{ .x = width, .y = height },
    }) catch unreachable;
    window_input.framebuffer_size = .{ .x = width, .y = height };
}
pub fn contentScaleCallback(window: glfw.Window, xscale: f32, yscale: f32) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .content_scale = .{ .x = xscale, .y = yscale },
    }) catch unreachable;
}
pub fn keyCallback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .key = .{ .key = key, .scancode = scancode, .action = action, .mods = mods },
    }) catch unreachable;
    window_input.keys.setPresent(key, if (action == .release) false else true);
}
pub fn charCallback(window: glfw.Window, codepoint: u21) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .char = codepoint,
    }) catch unreachable;
}
pub fn mouseButtonCallback(window: glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .mouse_button = .{ .button = button, .action = action, .mods = mods },
    }) catch unreachable;
}

pub fn cursorPosCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    var window_input: *@This() = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    const pos: Vector2xy(f64) = .{ .x = xpos, .y = ypos };
    const delta: Vector2xy(f64) = .sub(window_input.mouse_pos, pos);

    window_input.events.pushBack(window_input.allocator, .{
        .cursor_pos = .{ .pos = pos, .delta = delta },
    }) catch unreachable;

    window_input.mouse_pos = pos;
}
pub fn cursorEnterCallback(window: glfw.Window, entered: bool) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .cursor_enter = entered,
    }) catch unreachable;
}
pub fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .scroll = .{ .x = xoffset, .y = yoffset },
    }) catch unreachable;
}
pub fn dropCallback(window: glfw.Window, paths: [][*:0]const u8) void {
    var window_input = window.getUserPointer(@This()) orelse {
        std.log.err("glfw user pointer not found!", .{});
        return;
    };
    window_input.events.pushBack(window_input.allocator, .{
        .drop = .{ .paths = paths },
    }) catch unreachable;
}

const std = @import("std");

const glfw = @import("mach-glfw");
const Vector2xy = @import("main").Vector2xy;
