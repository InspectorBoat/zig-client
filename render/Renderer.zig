const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Box = @import("root").Box;
const Chunk = @import("root").Chunk;
const GpuStagingBuffer = @import("GpuStagingBuffer.zig");
const GpuMemoryAllocator = @import("GpuMemoryAllocator.zig");
const LocalPlayerEntity = @import("root").LocalPlayerEntity;
const Game = @import("root").Game;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;

vao: gl.VertexArray,
program: gl.Program,
index_buffer: gl.Buffer,
debug_cube_buffer: gl.Buffer,
debug_cube_staging_buffer: GpuStagingBuffer = .{},
sections: std.AutoHashMap(Vector3(i32), SectionRenderInfo),
gpu_memory_allocator: GpuMemoryAllocator,
texture: gl.Texture,

pub fn init(allocator: std.mem.Allocator) !@This() {
    gl.enable(.depth_test);
    gl.enable(.cull_face);

    const program = try initProgram(.{@embedFile("triangle.glsl.vert")}, .{@embedFile("triangle.glsl.frag")});

    const vao = try initVao();

    const index_buffer = try initIndexBuffer(allocator);

    const debug_cube_buffer = initDebugCubeBuffer();

    const texture = initTexture();

    const sections = std.AutoHashMap(Vector3(i32), SectionRenderInfo).init(allocator);

    const gpu_memory_allocator = try GpuMemoryAllocator.init(allocator, 1024 * 1024 * 1024 * 2 - 1);

    return .{
        .vao = vao,
        .program = program,
        .index_buffer = index_buffer,
        .debug_cube_buffer = debug_cube_buffer,
        .sections = sections,
        .gpu_memory_allocator = gpu_memory_allocator,
        .texture = texture,
    };
}

pub fn initProgram(vertex_shader_source: [1][]const u8, frag_shader_source: [1][]const u8) !gl.Program {
    const vertex_shader = gl.Shader.create(.vertex);
    vertex_shader.source(1, &vertex_shader_source);

    const frag_shader = gl.Shader.create(.fragment);
    frag_shader.source(1, &frag_shader_source);

    const program = gl.Program.create();
    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();

    var log_buffer: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&log_buffer);
    const compile_log = try program.getCompileLog(fba.allocator());
    if (compile_log.len > 0) std.debug.print("{s}", .{compile_log});

    program.use();

    return program;
}

pub fn initVao() !gl.VertexArray {
    const vao = gl.VertexArray.create();
    vao.bind();

    vao.enableVertexAttribute(0);
    vao.attribFormat(
        0,
        3,
        .float,
        false,
        0,
    );
    vao.attribBinding(0, 0);

    return vao;
}

pub fn initIndexBuffer(allocator: std.mem.Allocator) !gl.Buffer {
    const primitive_restart_index: u32 = std.math.maxInt(u32);

    const indices = try allocator.create([1024 * 1024 * 8]u32);
    defer allocator.destroy(indices);

    var index: u32 = 0;
    for (indices, 1..) |*element, i| {
        if (i % 5 == 0) {
            element.* = primitive_restart_index;
        } else {
            element.* = index;
            index += 1;
        }
    }
    const index_buffer = gl.Buffer.create();
    index_buffer.storage(u32, 1024 * 1024 * 8, @ptrCast(indices), .{});
    index_buffer.bind(.element_array_buffer);

    gl.enable(.primitive_restart);
    gl.primitiveRestartIndex(primitive_restart_index);

    return index_buffer;
}

pub fn initDebugCubeBuffer() gl.Buffer {
    const debug_cube_buffer = gl.Buffer.create();
    debug_cube_buffer.storage(f32, 36 * 3 * 1024, null, .{ .dynamic_storage = true });
    return debug_cube_buffer;
}

pub fn initTexture() gl.Texture {
    const texture = gl.Texture.create(.@"2d_array");
    texture.storage3D(1, .rgb8, 16, 16, 256);

    var texture_data: [16 * 16 * 256 * 3]u8 = undefined;
    var rand_impl = std.Random.DefaultPrng.init(155215);
    const rand = rand_impl.random();
    rand.bytes(&texture_data);

    texture.subImage3D(
        0,
        0,
        0,
        0,
        16,
        16,
        256,
        .rgb,
        .unsigned_byte,
        &texture_data,
    );
    texture.bindTo(0);
    texture.parameter(.wrap_s, .repeat);
    texture.parameter(.wrap_t, .repeat);
    texture.parameter(.wrap_r, .repeat);

    texture.parameter(.min_filter, .nearest);
    texture.parameter(.mag_filter, .nearest);

    gl.uniform1i(2, 0);
    return texture;
}

pub fn renderFrame(self: *@This(), ingame: *const Game.IngameGame) void {
    const mvp = getMvpMatrix(ingame.world.player, ingame.partial_tick);
    gl.uniformMatrix4fv(0, true, &.{mvp.data});

    var entries = self.sections.iterator();
    while (entries.next()) |entry| {
        self.renderSection(
            entry.key_ptr.*,
            entry.value_ptr.*,
        );
    }

    self.renderDebug();
}

pub fn renderSection(self: *@This(), section_pos: Vector3(i32), section: SectionRenderInfo) void {
    // uniform for section pos
    self.program.uniform3f(
        1,
        @floatFromInt(section_pos.x),
        @floatFromInt(section_pos.y),
        @floatFromInt(section_pos.z),
    );

    // bind buffer at offset
    self.vao.vertexBuffer(
        0,
        self.gpu_memory_allocator.backing_buffer,
        section.segment.offset,
        3 * @sizeOf(f32),
    );

    // draw chunk
    gl.drawElements(
        .triangle_fan,
        // count includes primitive restart indices, thus there are actually 5 indices per quad
        section.vertices / 4 * 5,
        .unsigned_int,
        0,
    );
}

pub fn renderCrosshairTarget(self: *@This(), ingame: *const Game.IngameGame) void {
    switch (ingame.world.player.crosshair) {
        .miss => {},
        .block => |block| {
            const offset_pos = block.block_pos.dir(block.dir).intToFloat(f32);
            self.debug_cube_staging_buffer.writeBox(
                offset_pos,
                offset_pos.add(.{ .x = 1, .y = 1, .z = 1 }),
            );
        },
        .entity => {},
    }
}

pub fn renderDebug(self: *@This()) void {
    // upload debug cube buffer to gpu
    self.debug_cube_buffer.subData(
        0,
        u8,
        @ptrCast(self.debug_cube_staging_buffer.getSlice()),
    );

    // set chunk pos uniform for debug cubes (0, 0, 0)
    self.program.uniform3f(
        1,
        0.0,
        0.0,
        0.0,
    );

    // bind debug cube buffer
    self.vao.vertexBuffer(
        0,
        self.debug_cube_buffer,
        0,
        3 * @sizeOf(f32),
    );
    gl.polygonMode(.front_and_back, .line);
    // render debug cubes
    gl.drawElements(
        .triangle_fan,
        self.debug_cube_staging_buffer.write_index / @sizeOf(f32) / 3 * 5,
        .unsigned_int,
        0,
    );

    gl.polygonMode(.front_and_back, .fill);

    self.debug_cube_staging_buffer.write_index = 0;
}

pub fn getMvpMatrix(player: LocalPlayerEntity, partial_tick: f64) Mat4 {
    const eye_pos = player.getInterpolatedEyePos(partial_tick, lerp);

    const player_pos_cast = za.Vec3_f64.new(
        -eye_pos.x,
        -eye_pos.y,
        -eye_pos.z,
    ).cast(f32);

    const projection = za.perspective(90.0, @as(f32, @floatFromInt(@import("render.zig").window_input.window_size.x)) / @as(f32, @floatFromInt(@import("render.zig").window_input.window_size.z)), 0.05, 1000.0);
    const view = Mat4.mul(
        Mat4.fromEulerAngles(Vec3.new(player.base.rotation.pitch, 0, 0)),
        Mat4.fromEulerAngles(Vec3.new(0, player.base.rotation.yaw + 180, 0)),
    );

    const model = Mat4.fromTranslate(player_pos_cast);

    return projection.mul(view.mul(model));
}

pub fn compileChunk(self: *@This(), chunk_pos: Vector2(i32), chunk: *const Chunk, allocator: std.mem.Allocator) !void {
    for (chunk.sections, 0..) |maybe_section, section_y| {
        if (section_y < 3) continue;
        if (maybe_section) |section| {
            var staging = GpuStagingBuffer{};

            // place blocks in chunk
            for (0..16) |x| {
                for (0..16) |y| {
                    for (0..16) |z| {
                        const pos = (y << 8) | (z << 4) | (x << 0);
                        // TODO: Change this
                        for (section.block_states[pos].getRaytraceHitbox()) |maybe_box| {
                            if (maybe_box) |box| {
                                const pos_vec: Vector3(f64) = .{
                                    .x = @floatFromInt(x),
                                    .y = @floatFromInt(y),
                                    .z = @floatFromInt(z),
                                };
                                staging.writeBox(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32));
                            }
                        }
                    }
                }
            }
            if (staging.write_index == 0) continue;

            const segment = try self.gpu_memory_allocator.alloc(staging.write_index, allocator);
            self.gpu_memory_allocator.subData(segment, staging.getSlice());

            try self.sections.put(
                .{ .x = chunk_pos.x, .y = @intCast(section_y), .z = chunk_pos.z },
                .{
                    .segment = segment,
                    .vertices = staging.write_index / @sizeOf(f32) / 3,
                },
            );
        }
    }
}

pub fn unloadChunk(self: *@This(), chunk_pos: Vector2(i32), allocator: std.mem.Allocator) !void {
    for (0..16) |section_y| {
        const entry = self.sections.fetchRemove(.{ .x = chunk_pos.x, .y = @intCast(section_y), .z = chunk_pos.z }) orelse continue;
        try self.gpu_memory_allocator.free(entry.value.segment, allocator);
    }
}

pub const SectionRenderInfo = struct {
    segment: GpuMemoryAllocator.Segment,
    vertices: usize,
};

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}
