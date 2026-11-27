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
    glfw_helper.setGlfwErrorCallback();
    try glfw_helper.initGlfw();

    const window = try glfw_helper.initGlfwWindow(switch (build_options.graphics) {
        .normal => true,
        .silent => false,
        .headless => comptime unreachable,
    });
    window.setInputModeCursor(.disabled);

    try glfw_helper.loadGlPointers();
    glfw_helper.setGlErrorCallback();

    window_input = .init(gpa, window);
    window_input.setGlfwInputCallbacks();

    renderer = try .init(startup.io, gpa);
}

pub fn onFrame(frame: Events.Frame) !void {
    if (window_input.window.shouldClose()) {
        main.signalExit();
    }
    const client = frame.client;
    {
        const zone = tracy.Zone.begin(.{ .name = "Poll events", .src = @src(), .color = .light_blue });
        defer zone.end();
        glfw.pollEvents();
    }

    switch (client.*) {
        .idle => gl.clearColor(1.0, 0.75, 0.75, 1),
        .connecting => gl.clearColor(0.75, 1.0, 0.75, 1),
        .game => gl.clearColor(0.72, 0.77, 0.92, 1),
    }
    {
        const zone: tracy.Zone = .begin(.{ .name = "Clear", .src = @src(), .color = .light_blue });
        defer zone.end();
        gl.clear(.{ .color = true, .depth = true });
    }

    switch (client.*) {
        .game => |*game| {
            try handleInputIngame(frame.io, frame.gpa, game, frame.input_queue.?);
            const start: std.Io.Timestamp = .now(frame.io, .real);

            try renderer.updateAndDispatchDirtySections(frame.io, start, &game.world);
            try renderer.uploadCompilationResults(frame.io, frame.gpa, start);
            try renderer.renderFrame(frame.io, frame.gpa, game);
        },
        .connecting => |*connecting_game| {
            handleInputConnecting(connecting_game);
        },
        .idle => |*idle_game| {
            handleInputIdle(idle_game);
        },
    }
    {
        const zone = tracy.Zone.begin(.{ .name = "Swap buffers", .src = @src(), .color = .light_blue });
        defer zone.end();
        window_input.window.swapBuffers();
    }
}

pub fn onChunkUpdate(chunk_update: Events.ChunkUpdate) !void {
    try renderer.onChunkUpdate(chunk_update.gpa, chunk_update.chunk_pos);
}

pub fn onUnloadChunk(unload_chunk: Events.UnloadChunk) !void {
    try renderer.onUnloadChunk(unload_chunk.chunk_pos);
}

pub fn onBlockUpdate(block_update: Events.BlockUpdate) !void {
    try renderer.onBlockUpdate(block_update.block_pos);
}

pub fn onExit(exit: Events.Exit) !void {
    try renderer.deinit(exit.io, exit.gpa);
    window_input.deinit();
    if (renderer.gpu_memory_allocator.detectLeaks()) std.log.scoped(.render).err("gpu memory leak detected", .{});
}

pub fn handleInputIdle(_: *const Client.Idle) void {
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            .content_scale => |content_scale| {
                std.log.scoped(.window).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .framebuffer_size => |framebuffer_size| {
                std.log.scoped(.window).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }
}

pub fn handleInputConnecting(_: *const Client.Connecting) void {
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .key => |key| {
                switch (key.key) {
                    .escape => window_input.window.setShouldClose(true),
                    else => {},
                }
            },
            .content_scale => |content_scale| {
                std.log.scoped(.window).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .framebuffer_size => |framebuffer_size| {
                std.log.scoped(.window).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }
}

var ignore_next_mouse_delta = false;
var suppress_mouse_release = false;
var pending_collect: ?usize = null;
var drag_armed: ?Menu.Action.Drag.Mode = null;
var drag_button: glfw.MouseButton = .left;
var last_click_slot: ?usize = null;
var last_click_button: glfw.MouseButton = .left;
var last_click_time: f64 = 0;

pub fn handleInputIngame(io: std.Io, gpa: std.mem.Allocator, game: *const Client.Game, input_queue: *Client.InputQueue) !void {
    const zone: tracy.Zone = .begin(.{ .name = "Handle input", .src = @src(), .color = .light_blue });
    defer zone.end();

    var cursor_delta: Vector2xy(f64) = .origin;
    while (window_input.events.popFront()) |event| {
        switch (event) {
            .key => |key| {
                if (key.action == .repeat) continue;
                if (game.world.menu_screen_open and key.key == .backspace and key.action == .press) {
                    try input_queue.queueOnTick(gpa, .text_backspace);
                    continue;
                }
                if (game.world.sign_editor != null and key.action == .press) {
                    switch (key.key) {
                        .up, .down, .enter, .kp_enter => {
                            const delta: i8 = if (key.key == .up) -1 else 1;
                            try input_queue.queueOnTick(gpa, .{ .sign_row = delta });
                            continue;
                        },
                        else => {},
                    }
                }
                if (game.world.menu_screen_open and game.world.sign_editor == null) {
                    switch (key.key) {
                        .one, .two, .three, .four, .five, .six, .seven, .eight, .nine => |num| {
                            if (key.action == .release) continue;
                            if (gui.onHotbarKey(
                                &game.world,
                                window_input.mousePosInClipSpace(),
                                @intCast(@backingInt(num) - @backingInt(glfw.Key.one)),
                            )) |action| {
                                try input_queue.queueOnTick(gpa, .{ .inventory = action });
                            }
                            continue;
                        },
                        .q => {
                            if (key.action == .release) continue;
                            if (gui.onDropKey(
                                &game.world,
                                window_input.mousePosInClipSpace(),
                                window_input.keys.contains(.left_control),
                            )) |action| {
                                try input_queue.queueOnTick(gpa, .{ .inventory = action });
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
                    .escape => if (key.action == .press) {
                        if (game.world.menu_screen_open) {
                            try input_queue.queueOnTick(gpa, .close_screen);
                        } else {
                            window_input.window.setShouldClose(true);
                        }
                    },
                    .h => if (key.action == .press) {
                        renderer.debug_options.chunk_borders = !renderer.debug_options.chunk_borders;
                    },
                    .e => if (key.action == .press) {
                        if (game.world.menu_screen_open)
                            try input_queue.queueOnTick(gpa, .close_screen)
                        else
                            try input_queue.queueOnTick(gpa, .open_screen);
                        renderer.debug_options.inventory = !renderer.debug_options.inventory;
                    },
                    .f => if (key.action == .press) {
                        renderer.debug_options.terrain_draw_mode = switch (renderer.debug_options.terrain_draw_mode) {
                            .fill => .line,
                            .line => .fill,
                            .point => unreachable,
                        };
                    },
                    .k => if (key.action == .press) try renderer.recompileAllChunks(io, gpa),
                    .r => if (key.action == .press) {
                        std.log.scoped(.render).info("reloading shaders", .{});
                        renderer.terrain_program.delete();
                        renderer.debug_program.delete();
                        renderer.terrain_program = try Renderer.initProgram(io, gpa, "shader/terrain.glsl.vert", "shader/terrain.glsl.frag");
                        renderer.debug_program = try Renderer.initProgram(io, gpa, "shader/debug.glsl.vert", "shader/debug.glsl.frag");
                    },
                    .o => if (key.action == .press) {
                        renderer.occlusion_culling = !renderer.occlusion_culling;
                    },

                    .w => try input_queue.queueOnTick(gpa, .{ .movement = .{ .forward = (key.action == .press) } }),
                    .a => try input_queue.queueOnTick(gpa, .{ .movement = .{ .left = (key.action == .press) } }),
                    .s => try input_queue.queueOnTick(gpa, .{ .movement = .{ .back = (key.action == .press) } }),
                    .d => try input_queue.queueOnTick(gpa, .{ .movement = .{ .right = (key.action == .press) } }),
                    .space => try input_queue.queueOnTick(gpa, .{ .movement = .{ .jump = (key.action == .press) } }),
                    .left_shift => try input_queue.queueOnTick(gpa, .{ .movement = .{ .sneak = (key.action == .press) } }),
                    .left_control => try input_queue.queueOnTick(gpa, .{ .movement = .{ .sprint = (key.action == .press) } }),

                    .q => try input_queue.queueOnTick(gpa, .{ .hand = .{ .drop = (key.action == .press) } }),

                    .one, .two, .three, .four, .five, .six, .seven, .eight, .nine => |num| if (key.action == .press)
                        try input_queue.queueOnTick(gpa, .{ .hand = .{ .hotkey = @backingInt(num) - @backingInt(glfw.Key.one) } }),
                    else => {},
                }
            },
            .mouse_button => |button| {
                if (button.action == .repeat) continue;
                if (game.world.menu_screen_open) {
                    if (game.world.sign_editor != null) continue;
                    if (button.button != .left and button.button != .right and button.button != .middle) continue;
                    const cursor_pos = window_input.mousePosInClipSpace();
                    if (button.action == .press) {
                        if (button.button == .left and game.world.menu == .other and
                            game.world.menu.other.type == .enchanting_table)
                        {
                            if (gui.enchantButtonAt(cursor_pos)) |button_id| {
                                try input_queue.queueOnTick(gpa, .{ .menu_button = .{
                                    .button_id = button_id,
                                } });
                                continue;
                            }
                        }
                        if (game.world.maybe_cursor_stack != null) {
                            // Vanilla arms the drag on press but sends all packets on release.
                            drag_armed = switch (button.button) {
                                .left => .split,
                                .right => .single,
                                else => .duplicate,
                            };
                            drag_button = button.button;
                            try input_queue.queueOnTick(gpa, .{ .inventory = .{ .drag = .{ .begin = drag_armed.? } } });
                        } else {
                            suppress_mouse_release = true;
                            const clicked: ?usize = if (gui.hoveredSlot(&game.world, cursor_pos)) |idx| @backingInt(idx) else null;
                            const is_double = clicked != null and clicked.? == (last_click_slot orelse std.math.maxInt(usize)) and
                                button.button == last_click_button and glfw.getTime() - last_click_time < 0.250;
                            pending_collect = if (is_double) clicked else null;
                            last_click_slot = clicked;
                            last_click_button = button.button;
                            last_click_time = glfw.getTime();
                            if (gui.onClick(&game.world, cursor_pos, button.button, window_input.keys.contains(.left_shift))) |action| {
                                try input_queue.queueOnTick(gpa, .{ .inventory = action });
                            }
                        }
                    } else {
                        if (suppress_mouse_release) {
                            suppress_mouse_release = false;
                            if (pending_collect) |slot_index| {
                                try input_queue.queueOnTick(gpa, .{ .inventory = .{ .collect = .{ .slot_index = @fromBackingInt(@intCast(slot_index)) } } });
                                pending_collect = null;
                            }
                            continue;
                        }
                        var actions: std.ArrayList(Menu.Action) = .empty;
                        defer actions.deinit(gpa);
                        try gui.onRelease(
                            &game.world,
                            cursor_pos,
                            button.button,
                            window_input.keys.contains(.left_shift),
                            drag_armed,
                            false,
                            &actions,
                            gpa,
                        );
                        for (actions.items) |action| try input_queue.queueOnTick(gpa, .{ .inventory = action });
                        if (drag_armed != null and button.button != drag_button) {
                            // Wrong-button release cancels the drag (no packets).
                            drag_armed = null;
                        } else if (drag_armed != null) {
                            drag_armed = null;
                        }
                    }
                    continue;
                }
                switch (button.button) {
                    .left => try input_queue.queueOnTick(gpa, .{ .hand = .{ .attack = (button.action == .press) } }),
                    .right => try input_queue.queueOnTick(gpa, .{ .hand = .{ .use = (button.action == .press) } }),
                    else => {},
                }
            },
            .cursor_pos => |cursor_event| {
                if (game.world.menu_screen_open) {
                    // Accumulate slots crossed during a click-drag.
                    if (drag_armed != null) {
                        if (gui.hoveredSlot(&game.world, window_input.mousePosInClipSpace())) |slot_index| {
                            try input_queue.queueOnTick(gpa, .{ .inventory = .{ .drag = .{ .add_slot = slot_index } } });
                        }
                    }
                    continue;
                }
                if (ignore_next_mouse_delta) {
                    ignore_next_mouse_delta = false;
                    continue;
                }
                cursor_delta = .add(cursor_delta, cursor_event.delta);
            },
            .scroll => |scroll| {
                try input_queue.queueOnTick(gpa, .{ .hand = .{ .scroll = @round(scroll.y) } });
            },
            .char => |codepoint| try input_queue.queueOnTick(gpa, .{ .char = codepoint }),
            .content_scale => |content_scale| {
                std.log.scoped(.window).info("content scale: {[x]}x{[y]}", content_scale);
            },
            .framebuffer_size => |framebuffer_size| {
                std.log.scoped(.window).info("framebuffer size: {[x]}x{[y]}", framebuffer_size);
                gl.viewport(0, 0, framebuffer_size.x, framebuffer_size.y);
            },
            else => {},
        }
    }

    const target: glfw.Window.InputModeCursor = if (game.world.menu_screen_open) .normal else .disabled;
    if (window_input.last_set_mouse_input_mode != target) {
        ignore_next_mouse_delta = true;
        window_input.last_set_mouse_input_mode = target;
        window_input.window.setInputModeCursor(target);
    }

    if (game.world.menu_screen_open) return;

    try input_queue.queueOnFrame(gpa, .{ .rotate = .round(cursor_delta) });
}

test {
    try glfw_helper.initGlfw();
    _ = try glfw_helper.initGlfwWindow(false);
    try glfw_helper.loadGlPointers();

    _ = GpuMemoryAllocator;
}

const std = @import("std");

const build_options = @import("build_options");
const quarantine = @import("llm-code-quarantine");
const glfw = @import("mach-glfw");
const main = @import("main");
const tracy = @import("tracy");
const gl = @import("zgl");

pub const GpuMemoryAllocator = @import("GpuMemoryAllocator.zig");
pub const Renderer = @import("Renderer.zig");
pub const WindowInput = @import("WindowInput.zig");
pub const glfw_helper = @import("glfw_helper.zig");
pub const gui = @import("gui.zig");
pub const mesher = @import("mesher/mesher.zig");
pub const resource_pack = @import("resource_pack/resource_pack.zig");

pub const FpsCounter = quarantine.FpsCounter;
pub const Frustum = quarantine.Frustum;
const Client = main.Client;
const Events = main.Events;
const Menu = main.Menu;
const Vector2xy = main.Vector2xy;
