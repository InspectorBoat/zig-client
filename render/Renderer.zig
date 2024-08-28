const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Vector3 = @import("root").Vector3;
const Vector2xz = @import("root").Vector2xz;
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
const CompilationTask = @import("terrain/CompilationTask.zig");
const CompilationResult = @import("terrain/CompilationTask.zig").CompilationResult;
const CompilationResultQueue = @import("terrain/CompilationResultQueue.zig");
const CompileStatusTracker = @import("terrain/CompileStatusTracker.zig");

vao: gl.VertexArray,
program: gl.Program,
index_buffer: gl.Buffer,
sections: std.AutoHashMap(Vector3(i32), SectionRenderInfo),
gpu_memory_allocator: GpuMemoryAllocator,
texture: gl.Texture,
compile_thread_pool: *std.Thread.Pool,
compilation_result_queue: CompilationResultQueue,
allocator: std.mem.Allocator,
compile_status_tracker: CompileStatusTracker,

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

    const compile_status_tracker = CompileStatusTracker.init(allocator);

    return .{
        .vao = vao,
        .program = program,
        .index_buffer = index_buffer,
        .sections = sections,
        .gpu_memory_allocator = gpu_memory_allocator,
        .texture = texture,
        .compile_thread_pool = compile_thread_pool,
        .compilation_result_queue = compilation_result_queue,
        .allocator = allocator,
        .compile_status_tracker = compile_status_tracker,
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

    const texture_size = 8;
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

    // const section_pos: Vector3(i32) = .{
    //     .x = @intFromFloat(ingame.world.player.base.pos.x / 16.0),
    //     .y = @intFromFloat(ingame.world.player.base.pos.y / 16.0),
    //     .z = @intFromFloat(ingame.world.player.base.pos.z / 16.0),
    // };
    // std.debug.print("section_pos: {}", .{section_pos});
    // const chunk_info = self.compile_status_tracker.chunks.get(.{ .x = section_pos.x, .z = section_pos.z }) orelse {
    //     std.debug.print("chunk info missing\n", .{});
    //     return;
    // };
    // const section_info = switch (chunk_info) {
    //     .Rendering => |sections| sections[@intCast(section_pos.y)],
    //     .Waiting => {
    //         std.debug.print("section waiting for neighbors\n", .{});
    //         return;
    //     },
    // };
    // std.debug.print("{}\n", .{section_info});

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
    section.buffer.bindBase(.shader_storage_buffer, 0);

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

    const projection = za.perspective(90.0, @as(f32, @floatFromInt(@import("render.zig").window_input.window_size.x)) / @as(f32, @floatFromInt(@import("render.zig").window_input.window_size.y)), 0.05, 1000.0);
    const view = Mat4.mul(
        Mat4.fromEulerAngles(Vec3.new(player.base.rotation.pitch, 0, 0)),
        Mat4.fromEulerAngles(Vec3.new(0, player.base.rotation.yaw + 180, 0)),
    );

    const model = Mat4.fromTranslate(player_pos_cast);

    return projection.mul(view.mul(model));
}

pub fn onChunkUpdate(self: *@This(), chunk_pos: Vector2xz(i32)) !void {
    try self.compile_status_tracker.markChunkPresent(chunk_pos);
}

pub fn onBlockUpdate(self: *@This(), block_pos: Vector3(i32)) !void {
    try self.compile_status_tracker.markBlockPosDirty(block_pos);
}

pub fn updateAndDispatchDirtySections(self: *@This(), world: *const World, allocator: std.mem.Allocator) !void {
    var iter = self.compile_status_tracker.chunks.iterator();
    while (iter.next()) |entry| {
        const chunk_pos = entry.key_ptr.*;
        const chunk_info = entry.value_ptr;
        if (chunk_info.* == .Waiting and chunk_info.Waiting.isReady()) {
            chunk_info.* = .{ .Rendering = .{.{}} ** 16 };
        }
        if (chunk_info.* == .Rendering) {
            const chunk: *const Chunk = world.chunks.get(chunk_pos).?;

            // Only dispatch task if section actually exists, even if adjacent chunks update
            for (&chunk_info.Rendering, chunk.sections, 0..) |*section_info, maybe_section, y| {
                if (section_info.needsRecompile() and maybe_section != null) {
                    try self.dispatchCompilationTask(
                        .{ .x = chunk_pos.x, .y = @intCast(y), .z = chunk_pos.z },
                        world,
                        section_info.current_revision,
                        allocator,
                    );
                    section_info.alertCompilationDispatch();
                }
            }
        }
    }
}

pub fn dispatchCompilationTask(self: *@This(), section_pos: Vector3(i32), world: *const World, revision: u32, allocator: std.mem.Allocator) !void {
    // try self.compile_thread_pool.spawn(
    //     CompilationTask.runTask,
    //     .{
    //         try CompilationTask.create(section_pos, world, revision, allocator),
    //         &self.compilation_result_queue,
    //         allocator,
    //     },
    // );
    CompilationTask.runTask(
        try CompilationTask.create(section_pos, world, revision, allocator),
        &self.compilation_result_queue,
        allocator,
    );
}

pub fn uploadCompilationResults(self: *@This(), _: std.mem.Allocator) !void {
    if (self.compilation_result_queue.sections.first == null) return;

    while (self.compilation_result_queue.pop()) |compilation_result| {
        switch (compilation_result.result) {
            .Success => |compiled_section| {
                defer compiled_section.buffer.deinit();
                const debug = compilation_result.section_pos.equals(.{ .x = 25, .y = 4, .z = 10 });

                if (debug) {
                    // std.debug.print("recieved backer.items={*}\n", .{compiled_section.buffer.items.ptr});
                }

                // Deallocate existing segment
                if (self.sections.fetchRemove(compilation_result.section_pos)) |entry| {
                    entry.value.buffer.delete();
                }

                // Notify compile tracker
                const chunk_pos: Vector2xz(i32) = .{ .x = compilation_result.section_pos.x, .z = compilation_result.section_pos.z };
                const section_y: usize = @intCast(compilation_result.section_pos.y);
                // return if chunk is no longer being tracked
                const chunk_compile_info = self.compile_status_tracker.chunks.getPtr(chunk_pos) orelse continue;
                chunk_compile_info.Rendering[section_y].latest_received_revision = compilation_result.revision;

                const mesh_data = compiled_section.buffer.items;
                if (mesh_data.len == 0) {
                    continue;
                }

                // Allocate gpu memory and upload segment
                // const segment = try self.gpu_memory_allocator.alloc(mesh_data.len, allocator);
                const buffer = gl.Buffer.create();
                buffer.storage(u8, mesh_data.len, mesh_data.ptr, .{});
                // self.gpu_memory_allocator.subData(segment, mesh_data);

                // if (debug) std.debug.print("quads={d}\n", .{compiled_section.quads});
                // Store rendering info
                try self.sections.put(
                    compilation_result.section_pos,
                    .{
                        .quads = compiled_section.quads,
                        .segment = undefined,
                        .buffer = buffer,
                    },
                );
            },
            .Error => |e| std.debug.print("Error meshing section at {}: {}", .{ compilation_result.section_pos, e }),
        }
    }
}

pub fn onUnloadChunk(self: *@This(), chunk_pos: Vector2xz(i32), _: std.mem.Allocator) !void {
    self.compile_status_tracker.removeChunk(chunk_pos);
    for (0..16) |section_y| {
        const entry = self.sections.fetchRemove(.{ .x = chunk_pos.x, .y = @intCast(section_y), .z = chunk_pos.z }) orelse continue;
        entry.value.buffer.delete();
        // try self.gpu_memory_allocator.free(entry.value.segment, allocator);
    }
}

pub const SectionRenderInfo = struct {
    segment: GpuMemoryAllocator.Segment,
    buffer: gl.Buffer,
    quads: usize,
};

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}
