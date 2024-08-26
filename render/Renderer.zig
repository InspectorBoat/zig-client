const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Box = @import("root").Box;
const Chunk = @import("root").Chunk;
const GpuStagingBuffer = @import("terrain/GpuStagingBuffer.zig");
const GpuMemoryAllocator = @import("GpuMemoryAllocator.zig");
const LocalPlayerEntity = @import("root").LocalPlayerEntity;
const Game = @import("root").Game;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const Direction = @import("root").Direction;
const ConcreteBlockState = @import("root").ConcreteBlockState;
const World = @import("root").World;
const SectionCompileTask = @import("terrain/SectionCompileTask.zig");
const CompilationResult = @import("terrain/SectionCompileTask.zig").CompilationResult;
const CompilationResultQueue = @import("terrain/CompilationResultQueue.zig");

vao: gl.VertexArray,
program: gl.Program,
index_buffer: gl.Buffer,
sections: std.AutoHashMap(Vector3(i32), SectionRenderInfo),
gpu_memory_allocator: GpuMemoryAllocator,
texture: gl.Texture,
compile_thread_pool: *std.Thread.Pool,
compilation_result_queue: CompilationResultQueue,

pub fn init(allocator: std.mem.Allocator) !@This() {
    gl.enable(.depth_test);
    // gl.enable(.cull_face);
    const program = try initProgram(.{@embedFile("shader/triangle.glsl.vert")}, .{@embedFile("shader/triangle.glsl.frag")});

    const vao = try initVao();

    const index_buffer = try initIndexBuffer(allocator);

    const texture = initTexture();

    const sections = std.AutoHashMap(Vector3(i32), SectionRenderInfo).init(allocator);

    const gpu_memory_allocator = try GpuMemoryAllocator.init(allocator, 1024 * 1024 * 1024 * 2 - 1);

    const compile_thread_pool = try initCompileThreadPool(allocator);

    const compilation_result_queue = CompilationResultQueue.init(allocator);

    return .{
        .vao = vao,
        .program = program,
        .index_buffer = index_buffer,
        .sections = sections,
        .gpu_memory_allocator = gpu_memory_allocator,
        .texture = texture,
        .compile_thread_pool = compile_thread_pool,
        .compilation_result_queue = compilation_result_queue,
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

pub fn initTexture() gl.Texture {
    const texture = gl.Texture.create(.@"2d_array");

    const texture_size = 4;
    const color_channels = 4;
    const texture_count = 256;

    texture.storage3D(1, .rgba8, texture_size, texture_size, texture_count);

    var texture_data: [texture_count * texture_size * texture_size * color_channels]u8 = undefined;
    var rand_impl = std.Random.DefaultPrng.init(155215);
    const rand = rand_impl.random();
    for (0..texture_count) |i| {
        const block = texture_data[i * texture_size * texture_size * color_channels ..][0 .. texture_size * texture_size * color_channels];
        for (0..texture_size * texture_size) |j| {
            const color: [color_channels]u8 = .{ rand.int(u8), rand.int(u8), rand.int(u8), 255 };
            @memcpy(block[j * color_channels ..][0..color_channels], &color);
        }
    }

    texture.subImage3D(
        0,
        0,
        0,
        0,
        texture_size,
        texture_size,
        texture_count,
        .rgba,
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

pub fn initCompileThreadPool(allocator: std.mem.Allocator) !*std.Thread.Pool {
    const pool = try allocator.create(std.Thread.Pool);
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = 2,
    });
    return pool;
}

pub fn renderFrame(self: *@This(), ingame: *const Game.IngameGame) !void {
    try self.uploadCompilationResults(@import("render.zig").gpa_impl.allocator());

    const mvp = getMvpMatrix(ingame.world.player, ingame.partial_tick);
    gl.uniformMatrix4fv(0, true, &.{mvp.data});

    var entries = self.sections.iterator();
    while (entries.next()) |entry| {
        self.renderSection(
            entry.key_ptr.*,
            entry.value_ptr.*,
        );
    }
}

pub fn renderSection(self: *@This(), section_pos: Vector3(i32), section: SectionRenderInfo) void {
    // uniform for section pos
    self.program.uniform3f(
        1,
        @floatFromInt(section_pos.x),
        @floatFromInt(section_pos.y),
        @floatFromInt(section_pos.z),
    );

    // bind buffer as ssbo at offset
    self.gpu_memory_allocator.backing_buffer.bindRange(
        .shader_storage_buffer,
        0,
        @intCast(section.segment.offset),
        @intCast(section.segment.length),
    );

    // draw chunk
    gl.drawElements(
        .triangle_strip,
        // count includes primitive restart indices, thus there are actually 5 indices per quad
        section.quads * 5,
        .unsigned_int,
        0,
    );
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

pub fn dispatchSectionCompileTask(self: *@This(), section_pos: Vector3(i32), world: *World, allocator: std.mem.Allocator) !void {
    try self.compile_thread_pool.spawn(
        SectionCompileTask.runTask,
        .{
            SectionCompileTask.create(section_pos, world),
            &self.compilation_result_queue,
            allocator,
        },
    );
    // const task = SectionCompileTask.create(section_pos, world);
    // SectionCompileTask.compile(
    //     &task,
    //     &self.compilation_result_queue,
    //     allocator,
    // );
}

pub fn uploadCompilationResults(self: *@This(), allocator: std.mem.Allocator) !void {
    if (self.compilation_result_queue.sections.first == null) return;

    while (self.compilation_result_queue.pop()) |compilation_result| {
        switch (compilation_result.result) {
            .Complete => |compiled_section| {
                defer compiled_section.buffer.deinit();

                const mesh_data = compiled_section.buffer.items;
                if (mesh_data.len == 0) continue;

                const segment = try self.gpu_memory_allocator.alloc(mesh_data.len, allocator);
                self.gpu_memory_allocator.subData(segment, mesh_data);

                try self.sections.put(
                    compilation_result.section_pos,
                    .{
                        .quads = compiled_section.quads,
                        .segment = segment,
                    },
                );
            },
            .Error => |_| {},
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
    quads: usize,
};

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}
