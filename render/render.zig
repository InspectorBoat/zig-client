const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Game = @import("root").Game;
const glfw_helper = @import("glfw_helper.zig");
const WindowInput = @import("WindowInput.zig");
const Renderer = @import("Renderer.zig");
const LocalPlayerEntity = @import("root").LocalPlayerEntity;
const EventHandler = @import("root").EventHandler;
const Events = @import("root").Events;

pub var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
pub var window_input: WindowInput = undefined;
pub var renderer: Renderer = undefined;

pub const event_listeners = .{
    onStartup,
    onFrame,
    onChunkUpdate,
    onUnloadChunk,
};

pub fn onStartup(_: Events.Startup) !void {
    const gpa = gpa_impl.allocator();

    // innitialize glfw
    glfw_helper.setGlfwErrorCallback();
    try glfw_helper.initGlfw();

    // initialize window
    const window = try glfw_helper.initGlfwWindow();
    window.setInputModeCursor(.disabled);

    // initialize opengl
    try glfw_helper.loadGlPointers();
    glfw_helper.setGlErrorCallback();

    // initialize window_input
    window_input = WindowInput.init(window, gpa);
    window_input.setGlfwInputCallbacks();

    // initialize renderer
    renderer = try Renderer.init(gpa);
}

pub fn onFrame(frame: Events.Frame) !void {
    if (window_input.window.shouldClose()) {
        try EventHandler.dispatch(Events.Exit, .{});
        return;
    }
    const game = frame.game;
    glfw.pollEvents();

    gl.clearColor(
        if (game.* == .Idle) 1 else 0,
        if (game.* == .Connecting) 1 else 0,
        if (game.* == .Ingame) 1 else 0,
        1,
    );
    gl.clear(.{ .color = true, .depth = true });

    switch (game.*) {
        .Ingame => |*ingame| {
            handleInputIngame(ingame);
            renderer.renderFrame(ingame);
        },
        .Connecting => |*connecting_game| handleInputConnecting(connecting_game),
        .Idle => |*idle_game| handleInputIdle(idle_game),
    }
    window_input.window.swapBuffers();
}

pub fn onChunkUpdate(chunk_update: Events.ChunkUpdate) !void {
    try renderer.compileChunk(chunk_update.chunk_pos, chunk_update.chunk, gpa_impl.allocator());
}

pub fn onUnloadChunk(unload_chunk: Events.UnloadChunk) !void {
    const chunk_pos = unload_chunk.chunk_pos;
    try renderer.unloadChunk(chunk_pos, gpa_impl.allocator());
}

pub fn handleInputIdle(_: *Game.IdleGame) void {
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn handleInputConnecting(_: *Game.ConnectingGame) void {
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn handleInputIngame(ingame: *Game.IngameGame) void {
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .tab => if (key.action == .press) {
                        if (window_input.maximized) window_input.window.restore() else window_input.window.maximize();
                    },
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            .Size => |size| {
                gl.viewport(0, 0, @intCast(size.width), @intCast(size.height));
            },
            else => {},
        }
    }

    var player = &ingame.world.player;

    player.base.rotation.yaw -= @floatCast(window_input.mouse_delta.x / 5);
    player.base.rotation.pitch -= @floatCast(window_input.mouse_delta.z / 5);

    window_input.mouse_delta = .{ .x = 0, .z = 0 };
    player.base.rotation.pitch = std.math.clamp(player.base.rotation.pitch, -90, 90);
    player.input = .{
        .jump = window_input.keys.get(.space),
        .sneak = window_input.keys.get(.left_shift),
        .sprint = window_input.keys.get(.left_control),
        .steer = .{
            .x = @floatFromInt(@as(i8, @intFromBool(window_input.keys.get(.a))) - @as(i8, @intFromBool(window_input.keys.get(.d)))),
            .z = @floatFromInt(@as(i8, @intFromBool(window_input.keys.get(.w))) - @as(i8, @intFromBool(window_input.keys.get(.s)))),
        },
    };
}

test {
    _ = @import("GpuMemoryAllocator.zig");
}
