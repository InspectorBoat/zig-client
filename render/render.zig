const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const root = @import("root");
const Game = @import("root").Game;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const GpuStagingBuffer = @import("./GpuStagingBuffer.zig");
const glfw_helper = @import("./glfw_helper.zig");
const WindowInput = @import("./WindowInput.zig");
const Renderer = @import("./Renderer.zig");
const LocalPlayerEntity = @import("root").LocalPlayerEntity;
const EventHandler = @import("root").EventHandler;
const Events = @import("root").Events;

pub var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
pub var window_input: WindowInput = undefined;
pub var renderer: Renderer = undefined;

pub const event_listeners = .{ onStartup, onFrame, onChunkUpdate };

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
            gl.enable(.depth_test);

            const mvp = getMvpMatrix(ingame.world.player, ingame.partial_tick);
            gl.uniformMatrix4fv(0, true, @as([*]const [4][4]f32, @ptrCast(mvp.getData()))[0..1]);

            var entries = renderer.sections.iterator();
            while (entries.next()) |entry| {
                // pos uniform
                const pos = entry.key_ptr.*;
                renderer.program.uniform3f(1, @floatFromInt(pos.x), @floatFromInt(pos.y), @floatFromInt(pos.z));

                // bind buffer
                renderer.vao.vertexBuffer(0, entry.value_ptr.buffer, 0, 3 * @sizeOf(f32));

                gl.drawArrays(.triangles, 0, entry.value_ptr.vertices);
            }

            renderer.debug_cube_buffer.subData(0, u8, @ptrCast(renderer.debug_cube_staging_buffer.getSlice()));

            renderer.program.uniform3f(1, 0.0, 0.0, 0.0);
            renderer.vao.vertexBuffer(0, renderer.debug_cube_buffer, 0, 3 * @sizeOf(f32));
            gl.drawArrays(
                .triangles,
                0,
                renderer.debug_cube_staging_buffer.write_index / @sizeOf(f32) / 3,
            );
        },
        else => {},
    }
    window_input.window.swapBuffers();
    // return false;
}

pub fn onChunkUpdate(chunk_update: Events.ChunkUpdate) !void {
    const chunk_pos: Vector2(i32) = chunk_update.chunk_pos;
    const chunk: *root.Chunk = chunk_update.chunk;
    for (chunk.sections, 0..) |maybe_section, section_y| {
        if (section_y < 3) continue;
        if (maybe_section) |section| {
            var staging = GpuStagingBuffer{};

            const buffer = gl.Buffer.create();
            // place blocks in chunk
            for (0..16) |x| {
                for (0..16) |y| {
                    for (0..16) |z| {
                        const pos = (y << 8) | (z << 4) | (x << 0);
                        for (section.block_states[pos].getRaytraceHitbox()) |maybe_box| {
                            if (maybe_box) |box| {
                                const pos_vec: Vector3(f64) = .{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) };
                                staging.writeBox(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32));
                            }
                        }
                        // if (section.block_states[pos].block != .air) {
                        // staging.writeCube(.{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                        // }
                    }
                }
            }
            buffer.storage(u8, staging.write_index, @ptrCast(staging.getSlice()), .{});

            try renderer.sections.put(
                .{ .x = chunk_pos.x, .y = @intCast(section_y), .z = chunk_pos.z },
                .{
                    .buffer = buffer,
                    .vertices = staging.write_index / @sizeOf(f32) / 3,
                },
            );
        }
    }
}

pub fn getMvpMatrix(player: LocalPlayerEntity, partial_tick: f64) Mat4 {
    const eye_pos = player.getInterpolatedEyePos(partial_tick, lerp);

    const player_pos_cast = za.Vec3_f64.new(
        -eye_pos.x,
        -eye_pos.y,
        -eye_pos.z,
    ).cast(f32);

    const projection = za.perspective(90.0, @as(f32, @floatFromInt(window_input.window_size.x)) / @as(f32, @floatFromInt(window_input.window_size.z)), 0.05, 1000.0);
    const view = Mat4.mul(
        Mat4.fromEulerAngles(Vec3.new(player.base.rotation.pitch, 0, 0)),
        Mat4.fromEulerAngles(Vec3.new(0, player.base.rotation.yaw + 180, 0)),
    );

    const model = Mat4.fromTranslate(player_pos_cast);

    return projection.mul(view.mul(model));
}

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}

pub fn handleInputIngame(ingame: *Game.IngameState) void {
    while (window_input.events.readItem()) |event| {
        switch (event) {
            .Key => |key| {
                switch (key.key) {
                    .tab => {
                        if (key.action == .press) {
                            if (window_input.maximized) window_input.window.restore() else window_input.window.maximize();
                        }
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
