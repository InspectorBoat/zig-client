const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const common = @import("common");
const Game = @import("common").Game;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const GpuStagingBuffer = @import("./GpuStagingBuffer.zig");
const glfw_helper = @import("./glfw_helper.zig");
const WindowInput = @import("./WindowInput.zig");
const Renderer = @import("./Renderer.zig");
const LocalPlayerEntity = @import("common").LocalPlayerEntity;

var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
var window_input: WindowInput = undefined;
var renderer: Renderer = undefined;

pub fn onStartup() !void {
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

pub fn onFrame(game: *Game) !bool {
    if (window_input.window.shouldClose()) return true;
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

            const mvp = getMvpMatrix(ingame.world.player);
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
        },
        else => {},
    }
    window_input.window.swapBuffers();
    return false;
}

pub fn getMvpMatrix(player: LocalPlayerEntity) Mat4 {
    const eye_pos = player.getEyePos();
    const player_pos_cast = za.Vec3_f64.new(
        -eye_pos.x,
        -eye_pos.y,
        -eye_pos.z,
    ).cast(f32);

    const projection = za.perspective(90.0, 640.0 / 640.0, 0.05, 1000.0);
    const view = Mat4.mul(
        Mat4.fromEulerAngles(Vec3.new(-player.base.rotation.pitch, 0, 0)),
        Mat4.fromEulerAngles(Vec3.new(0, -player.base.rotation.yaw, 0)),
    );

    const model = Mat4.fromTranslate(player_pos_cast);

    return projection.mul(view.mul(model));
}

pub fn handleInputIngame(ingame: *Game.IngameState) void {
    var player = &ingame.world.player;

    player.base.rotation.yaw += @floatCast(window_input.mouse_delta.x / 20);
    player.base.rotation.pitch += @floatCast(window_input.mouse_delta.z / 20);

    window_input.mouse_delta = .{ .x = 0, .z = 0 };
    player.base.rotation.pitch = std.math.clamp(player.base.rotation.pitch, -90, 90);

    player.input = .{
        .jump = window_input.keys.get(.space),
        .sneak = window_input.keys.get(.left_shift),
        .steer = .{
            .x = @floatFromInt(@as(i8, @intFromBool(window_input.keys.get(.a))) - @as(i8, @intFromBool(window_input.keys.get(.d)))),
            .z = @floatFromInt(@as(i8, @intFromBool(window_input.keys.get(.s))) - @as(i8, @intFromBool(window_input.keys.get(.w)))),
        },
    };
}

pub fn onChunkUpdate(chunk_pos: common.Vector2(i32), chunk: *common.Chunk) !void {
    for (chunk.sections, 0..) |maybe_section, section_y| {
        if (section_y < 3 or section_y > 4) continue;
        if (maybe_section) |section| {
            var staging = GpuStagingBuffer{};

            const buffer = gl.Buffer.create();
            // place blocks in chunk
            for (0..16) |x| {
                for (0..16) |y| {
                    for (0..16) |z| {
                        const pos = (y << 8) | (z << 4) | (x << 0);
                        if (section.block_states[pos].id != 0) {
                            staging.writeCube(.{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                        }
                    }
                }
            }
            buffer.storage(u8, staging.write_index, @ptrCast(staging.getSlice()), .{});

            try renderer.sections.put(
                .{ .x = chunk_pos.x, .y = @intCast(section_y), .z = chunk_pos.z },
                .{
                    .buffer = buffer,
                    .vertices = staging.write_index / @sizeOf(f32),
                },
            );
        }
    }
}
