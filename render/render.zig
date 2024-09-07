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
const Vector2xy = root.Vector2xy;

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
            try handleInputIngame(frame.input_queue.?);
            try renderer.updateAndDispatchDirtySections(&game.world, gpa_impl.allocator());
            try renderer.uploadCompilationResults();
            try renderer.renderFrame(game);
        },
        .connecting => |*connecting_game| {
            handleInputConnecting(connecting_game);
        },
        .idle => |*idle_game| {
            handleInputIdle(idle_game);
        },
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

pub fn handleInputIdle(_: *const Client.Idle) void {
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

pub fn handleInputConnecting(_: *const Client.Connecting) void {
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

pub fn handleInputIngame(input_queue: *Client.InputQueue) !void {
    var cursor_delta: Vector2xy(f64) = .origin();
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                if (key.action == .repeat) continue;
                switch (key.key) {
                    .tab => if (key.action == .press) {
                        if (window_input.maximized) window_input.window.restore() else window_input.window.maximize();
                    },
                    .escape => window_input.window.setShouldClose(true),
                    .f => if (key.action == .press) gl.polygonMode(.front_and_back, .line),
                    .g => if (key.action == .press) gl.polygonMode(.front_and_back, .fill),
                    .k => if (key.action == .press) try renderer.recompileAllChunks(),
                    .l => if (key.action == .press) {
                        @import("log").reload_shader(.{});
                        renderer.terrain_program.delete();
                        renderer.terrain_program = try Renderer.initProgram("shader/terrain.glsl.vert", "shader/terrain.glsl.frag", gpa_impl.allocator());
                        renderer.entity_program = try Renderer.initProgram("shader/entity.glsl.vert", "shader/entity.glsl.frag", gpa_impl.allocator());
                    },

                    .w => try input_queue.queueOnTick(.{ .movement = .{ .forward = (key.action == .press) } }),
                    .a => try input_queue.queueOnTick(.{ .movement = .{ .left = (key.action == .press) } }),
                    .s => try input_queue.queueOnTick(.{ .movement = .{ .back = (key.action == .press) } }),
                    .d => try input_queue.queueOnTick(.{ .movement = .{ .right = (key.action == .press) } }),
                    .space => try input_queue.queueOnTick(.{ .movement = .{ .jump = (key.action == .press) } }),
                    .left_shift => try input_queue.queueOnTick(.{ .movement = .{ .sneak = (key.action == .press) } }),
                    .left_control => try input_queue.queueOnTick(.{ .movement = .{ .sprint = (key.action == .press) } }),
                    .q => try input_queue.queueOnTick(.{ .hand = .{ .drop = (key.action == .press) } }),
                    else => {},
                }
            },
            .MouseButton => |button| {
                if (button.action == .repeat) continue;
                switch (button.button) {
                    .left => try input_queue.queueOnTick(.{ .hand = .{ .main = (button.action == .press) } }),
                    else => {},
                }
            },
            .Size => |size| {
                gl.viewport(0, 0, @intCast(size.x), @intCast(size.y));
            },
            .CursorPos => |cursor_event| {
                cursor_delta = cursor_delta.add(cursor_event.delta);
            },
            else => {},
        }
    }
    try input_queue.queueOnFrame(.{ .rotate = cursor_delta.floatToInt(i32) });
}

test {
    _ = @import("GpuMemoryAllocator.zig");
}
