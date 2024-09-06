const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const root = @import("root");
const Client = root.Client;
const EventHandler = root.EventHandler;
const Events = root.Events;
const glfw_helper = @import("glfw_helper.zig");
const WindowInput = @import("WindowInput.zig");
const Renderer = @import("Renderer.zig");

var gpa_impl: std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }) = .{};
pub var window_input: WindowInput = undefined;
pub var renderer: Renderer = undefined;

pub const event_listeners = .{
    onStartup,
    onFrame,
    onChunkUpdate,
    onUnloadChunk,
    onBlockUpdate,
    onExit,
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
    window_input = .init(window, gpa);
    window_input.setGlfwInputCallbacks();

    // initialize renderer
    renderer = try .init(gpa);
}

pub fn onFrame(frame: Events.Frame) !void {
    if (window_input.window.shouldClose()) {
        try EventHandler.dispatch(Events.Exit, .{});
        return;
    }
    const client = frame.client;
    glfw.pollEvents();

    gl.clearColor(
        if (client.* == .idle) 1.0 else 0.75,
        if (client.* == .connecting) 1.0 else 0.75,
        if (client.* == .game) 1.0 else 0.75,
        1,
    );
    gl.clear(.{ .color = true, .depth = true });

    switch (client.*) {
        .game => |*game| {
            try handleInputIngame(game);
            try renderer.updateAndDispatchDirtySections(&game.world, gpa_impl.allocator());
            try renderer.uploadCompilationResults();
            try renderer.renderFrame(game);
        },
        .connecting => |*connecting_game| handleInputConnecting(connecting_game),
        .idle => |*idle_game| handleInputIdle(idle_game),
    }
    window_input.window.swapBuffers();
}

pub fn onChunkUpdate(chunk_update: Events.ChunkUpdate) !void {
    try renderer.onChunkUpdate(chunk_update.chunk_pos);
}

pub fn onUnloadChunk(unload_chunk: Events.UnloadChunk) !void {
    try renderer.onUnloadChunk(unload_chunk.chunk_pos);
}

pub fn onBlockUpdate(block_update: Events.BlockUpdate) !void {
    try renderer.onBlockUpdate(block_update.block_pos);
}

pub fn onExit(_: Events.Exit) !void {
    try renderer.unloadAllChunks();
    renderer.gpu_memory_allocator.deinit();
    renderer.compile_thread_pool.deinit();
    gpa_impl.allocator().destroy(renderer.compile_thread_pool);
    _ = gpa_impl.detectLeaks();
    std.debug.print("gpu memory leaks: {}\n", .{renderer.gpu_memory_allocator.detectLeaks()});
}

pub fn handleInputIdle(_: *Client.Idle) void {
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

pub fn handleInputConnecting(_: *Client.Connecting) void {
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

pub fn handleInputIngame(game: *Client.Game) !void {
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .tab => if (key.action == .press) {
                        if (window_input.maximized) window_input.window.restore() else window_input.window.maximize();
                    },
                    .escape => window_input.window.setShouldClose(true),
                    .f => gl.polygonMode(.front_and_back, .line),
                    .g => gl.polygonMode(.front_and_back, .fill),
                    .k => if (key.action == .press) try renderer.recompileAllChunks(),
                    .l => if (key.action == .press) {
                        @import("log").reload_shader(.{});
                        renderer.terrain_program.delete();
                        renderer.terrain_program = try Renderer.initProgram("shader/terrain.glsl.vert", "shader/terrain.glsl.frag", gpa_impl.allocator());
                        renderer.entity_program = try Renderer.initProgram("shader/entity.glsl.vert", "shader/entity.glsl.frag", gpa_impl.allocator());
                    },
                    else => {},
                }
            },
            .MouseButton => |button| blk: {
                switch (button.button) {
                    .left => if (button.action == .press) {
                        try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });

                        if (game.world.player.crosshair != .block) break :blk;

                        try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
                            .action = .StartDestroyBlock,
                            .block_pos = game.world.player.crosshair.block.block_pos,
                            .face = game.world.player.crosshair.block.dir,
                        } });
                        try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
                            .action = .FinishDestroyBlock,
                            .block_pos = game.world.player.crosshair.block.block_pos,
                            .face = game.world.player.crosshair.block.dir,
                        } });
                    },
                    else => {},
                }
            },
            .Size => |size| {
                gl.viewport(0, 0, @intCast(size.width), @intCast(size.height));
            },
            else => {},
        }
    }

    var player = &game.world.player;

    player.base.rotation.yaw -= @floatCast(window_input.mouse_delta.x / 5);
    player.base.rotation.pitch -= @floatCast(window_input.mouse_delta.y / 5);

    window_input.mouse_delta = .{ .x = 0, .y = 0 };
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
