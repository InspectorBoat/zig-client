const std = @import("std");
const Vector2 = @import("main").Vector3;
const glfw = @import("mach-glfw");
const gl = @import("zgl");
pub fn initGlfw() error{GlfwInitFailed}!void {
    if (!glfw.init(.{})) {
        std.log.err("failed to init glfw: {?s}", .{glfw.getErrorString()});
        return error.GlfwInitFailed;
    }
}

pub fn initGlfwWindow() error{GlfwWindowFailed}!glfw.Window {
    const window = glfw.Window.create(640, 640, "client", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 6,
    }) orelse {
        std.log.err("failed to create glfw window: {?s}", .{glfw.getErrorString()});
        return error.GlfwWindowFailed;
    };
    glfw.makeContextCurrent(window);
    return window;
}

pub fn setGlfwErrorCallback() void {
    glfw.setErrorCallback(glfwErrorCallback);
}

pub fn glfwErrorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn setGlErrorCallback() void {
    gl.debugMessageCallback(void{}, glErrorCallback);
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
    try gl.binding.load(void{}, getProcAddress);
}

pub fn getProcAddress(_: void, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}
