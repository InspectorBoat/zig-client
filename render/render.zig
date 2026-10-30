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

pub fn onStartup(startup: Events.Startup) !void {
    const gpa = startup.gpa;
    // initialize glfw
    glfw_helper.setGlfwErrorCallback();
    try glfw_helper.initGlfw();

    // initialize window
    const window = try glfw_helper.initGlfwWindow(true);
    window.setInputModeCursor(.disabled);

    // initialize opengl
    try glfw_helper.loadGlPointers();
    glfw_helper.setGlErrorCallback();

    // initialize window_input
    window_input = .init(gpa, window);
    window_input.setGlfwInputCallbacks();

    // initialize renderer
    renderer = try .init(startup.io, gpa);
}

pub fn onFrame(frame: Events.Frame) !void {
    if (window_input.window.shouldClose()) {
        main.signalExit();
    }
    const client = frame.client;
    glfw.pollEvents();

    switch (client.*) {
        .idle => gl.clearColor(1.0, 0.75, 0.75, 1),
        .connecting => gl.clearColor(0.75, 1.0, 0.75, 1),
        .game => gl.clearColor(0.72, 0.77, 0.92, 1),
    }
    gl.clear(.{ .color = true, .depth = true });

    switch (client.*) {
        .game => |*game| {
            try handleInputIngame(frame.io, frame.allocator, game, frame.input_queue.?);
            try renderer.updateAndDispatchDirtySections(frame.io, game.gpa, &game.world);
            try renderer.uploadCompilationResults(frame.io);
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

pub fn onExit(exit: Events.Exit) !void {
    try renderer.deinit(exit.io);
    window_input.deinit();
    std.debug.print("gpu memory leaks: {}\n", .{renderer.gpu_memory_allocator.detectLeaks()});
}

pub fn handleInputIdle(_: *const Client.Idle) void {
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            .ContentScale => |content_scale| {
                std.log.scoped(.content_scale).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .FramebufferSize => |framebuffer_size| {
                std.log.scoped(.framebuffer_size).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }
}

pub fn handleInputConnecting(_: *const Client.Connecting) void {
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            .ContentScale => |content_scale| {
                std.log.scoped(.content_scale).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .FramebufferSize => |framebuffer_size| {
                std.log.scoped(.framebuffer_size).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }
}

pub fn handleInputIngame(io: std.Io, allocator: std.mem.Allocator, game: *const Client.Game, input_queue: *Client.InputQueue) !void {
    window_input.window.setInputModeCursor(if (game.world.menu_screen_open) .normal else .disabled);

    var cursor_delta: Vector2xy(f64) = .origin;
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .Key => |key| {
                if (key.action == .repeat) continue;
                if (game.world.menu_screen_open) {
                    switch (key.key) {
                        .one, .two, .three, .four, .five, .six, .seven, .eight, .nine => |num| {
                            if (key.action == .release) continue;
                            if (gui.onHotbarKey(
                                &game.world,
                                window_input.mousePosInClipSpace(),
                                @intCast(@backingInt(num) - @backingInt(glfw.Key.one)),
                            )) |action| {
                                try input_queue.queueOnTick(allocator, .{ .inventory = action });
                            }
                            continue;
                        },
                        .q => {
                            if (key.action == .release) continue;
                            if (gui.onDropKey(
                                &game.world,
                                window_input.mousePosInClipSpace(),
                                window_input.keys.get(.left_control),
                            )) |action| {
                                try input_queue.queueOnTick(allocator, .{ .inventory = action });
                            }
                            continue;
                        },

                        else => {},
                    }
                }

                switch (key.key) {
                    .tab => if (key.action == .press) {
                        if (window_input.maximized) window_input.window.restore() else window_input.window.maximize();
                    },
                    .escape => window_input.window.setShouldClose(true),
                    .h => if (key.action == .press) {
                        renderer.debug_options.chunk_borders = !renderer.debug_options.chunk_borders;
                    },
                    .e => if (key.action == .press) {
                        if (game.world.menu_screen_open)
                            try input_queue.queueOnTick(allocator, .close_screen)
                        else
                            try input_queue.queueOnTick(allocator, .open_screen);
                        renderer.debug_options.inventory = !renderer.debug_options.inventory;
                    },
                    .f => if (key.action == .press) {
                        renderer.debug_options.terrain_draw_mode = switch (renderer.debug_options.terrain_draw_mode) {
                            .fill => .line,
                            .line => .fill,
                            .point => unreachable,
                        };
                    },
                    .k => if (key.action == .press) try renderer.recompileAllChunks(),
                    .r => if (key.action == .press) {
                        std.log.scoped(.render).info("reloading shaders", .{});
                        renderer.terrain_program.delete();
                        renderer.debug_program.delete();
                        renderer.terrain_program = try Renderer.initProgram(io, renderer.allocator, "shader/terrain.glsl.vert", "shader/terrain.glsl.frag");
                        renderer.debug_program = try Renderer.initProgram(io, renderer.allocator, "shader/debug.glsl.vert", "shader/debug.glsl.frag");
                    },

                    .w => try input_queue.queueOnTick(allocator, .{ .movement = .{ .forward = (key.action == .press) } }),
                    .a => try input_queue.queueOnTick(allocator, .{ .movement = .{ .left = (key.action == .press) } }),
                    .s => try input_queue.queueOnTick(allocator, .{ .movement = .{ .back = (key.action == .press) } }),
                    .d => try input_queue.queueOnTick(allocator, .{ .movement = .{ .right = (key.action == .press) } }),
                    .space => try input_queue.queueOnTick(allocator, .{ .movement = .{ .jump = (key.action == .press) } }),
                    .left_shift => try input_queue.queueOnTick(allocator, .{ .movement = .{ .sneak = (key.action == .press) } }),
                    .left_control => try input_queue.queueOnTick(allocator, .{ .movement = .{ .sprint = (key.action == .press) } }),

                    .q => try input_queue.queueOnTick(allocator, .{ .hand = .{ .drop = (key.action == .press) } }),

                    .one, .two, .three, .four, .five, .six, .seven, .eight, .nine => |num| if (key.action == .press)
                        try input_queue.queueOnTick(allocator, .{ .hand = .{ .hotkey = @backingInt(num) - @backingInt(glfw.Key.one) } }),
                    else => {},
                }
            },
            .MouseButton => |button| {
                if (button.action == .repeat) continue;
                if (game.world.menu_screen_open) {
                    if (button.action == .release) continue;
                    if (button.button != .left and button.button != .right and button.button != .middle) continue;
                    try input_queue.queueOnTick(allocator, .{
                        .inventory = gui.onClick(
                            &game.world,
                            window_input.mousePosInClipSpace(),
                            button.button,
                        ),
                    });

                    continue;
                }
                switch (button.button) {
                    .left => try input_queue.queueOnTick(allocator, .{ .hand = .{ .attack = (button.action == .press) } }),
                    .right => try input_queue.queueOnTick(allocator, .{ .hand = .{ .use = (button.action == .press) } }),
                    else => {},
                }
            },
            .CursorPos => |cursor_event| {
                if (game.world.menu_screen_open) continue;
                cursor_delta = .add(cursor_delta, cursor_event.delta);
            },
            .Scroll => |scroll| {
                try input_queue.queueOnTick(allocator, .{ .hand = .{ .scroll = @round(scroll.y) } });
            },
            .ContentScale => |content_scale| {
                std.log.scoped(.content_scale).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .FramebufferSize => |framebuffer_size| {
                std.log.scoped(.framebuffer_size).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }
    if (game.world.menu_screen_open) return;
    try input_queue.queueOnFrame(allocator, .{ .rotate = .intFromFloat(cursor_delta) });
}

test {
    try glfw_helper.initGlfw();
    _ = try glfw_helper.initGlfwWindow(false);
    try glfw_helper.loadGlPointers();

    _ = GpuMemoryAllocator;
}

const std = @import("std");

const glfw = @import("mach-glfw");
const main = @import("main");
const gl = @import("zgl");

pub const GpuMemoryAllocator = @import("GpuMemoryAllocator.zig");
pub const Renderer = @import("Renderer.zig");
pub const WindowInput = @import("WindowInput.zig");
pub const glfw_helper = @import("glfw_helper.zig");
pub const gui = @import("gui.zig");
pub const mesher = @import("mesher/mesher.zig");
pub const resource_pack = @import("resource_pack/resource_pack.zig");

const Client = main.Client;
const Events = main.Events;
const Vector2xy = main.Vector2xy;
