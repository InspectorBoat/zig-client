pub fn initGlfw() error{GlfwInitFailed}!void {
    if (!glfw.init(.{ .platform = .wayland })) {
        std.log.err("failed to init glfw: {?s}", .{glfw.getErrorString()});
        return error.GlfwInitFailed;
    }
}

pub fn initGlfwWindow(_: bool) error{GlfwWindowFailed}!glfw.Window {
    return glfw.Window.create(0, 0, "", null, null, .{}).?;
}

pub fn setGlfwErrorCallback() void {}

pub fn glfwErrorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn setGlErrorCallback() void {
    gl.debugMessageCallback({}, glErrorCallback);
}
pub fn glErrorCallback(source: gl.DebugSource, msg_type: gl.DebugMessageType, id: usize, severity: gl.DebugSeverity, message: []const u8) void {
    std.log.err("gl: source: {} msg_type: {} id: {} severity: {} message: {s}", .{
        source,
        msg_type,
        id,
        severity,
        message,
    });
}

pub fn loadGlPointers() !void {
    try gl.binding.load({}, getProcAddress);
}

pub fn getProcAddress(_: void, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}

const std = @import("std");

const glfw = @import("mach-glfw");
const gl = @import("zgl");
