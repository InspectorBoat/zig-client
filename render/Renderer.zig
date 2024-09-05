const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const root = @import("root");
const Vector3 = root.Vector3;
const Vector2xz = root.Vector2xz;
const Box = root.Box;
const Chunk = root.Chunk;
const LocalPlayerEntity = root.Entity.LocalPlayer;
const GpuStagingBuffer = @import("terrain/GpuStagingBuffer.zig");
const GpuMemoryAllocator = @import("GpuMemoryAllocator.zig");
const Game = root.Game;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const Direction = root.Direction;
const ConcreteBlockState = root.ConcreteBlockState;
const World = root.World;
const CompilationTask = @import("terrain/CompilationTask.zig");
const CompilationResult = @import("terrain/CompilationTask.zig").CompilationResult;
const CompilationResultQueue = @import("terrain/CompilationResultQueue.zig");
const ChunkTracker = @import("terrain/ChunkTracker.zig");

vao: gl.VertexArray,
terrain_program: gl.Program,
entity_program: gl.Program,
index_buffer: gl.Buffer,
entity_buffer: gl.Buffer,
gpu_memory_allocator: GpuMemoryAllocator,
texture: gl.Texture,
compile_thread_pool: *std.Thread.Pool,
compilation_result_queue: CompilationResultQueue,
allocator: std.mem.Allocator,
chunk_tracker: ChunkTracker,

pub fn init(allocator: std.mem.Allocator) !@This() {
    gl.enable(.depth_test);
    // gl.enable(.cull_face);
    const terrain_program = try initProgram("shader/terrain.glsl.vert", "shader/terrain.glsl.frag", allocator);
    const entity_program = try initProgram("shader/entity.glsl.vert", "shader/entity.glsl.frag", allocator);

    const vao = try initVao();

    const index_buffer = try initIndexBuffer(allocator);

    const texture = initTexture();

    const gpu_memory_allocator: GpuMemoryAllocator = try .init(allocator, 1024 * 1024 * 1024 * 2 - 1);

    const compile_thread_pool = try initCompileThreadPool(allocator);

    const compilation_result_queue: CompilationResultQueue = .init(allocator);

    const chunk_tracker: ChunkTracker = .init(allocator);

    const entity_buffer = gl.Buffer.create();
    entity_buffer.storage(f32, 6 * 5 * 1024, null, .{ .dynamic_storage = true });

    return .{
        .vao = vao,
        .terrain_program = terrain_program,
        .entity_program = entity_program,
        .index_buffer = index_buffer,
        .entity_buffer = entity_buffer,
        .gpu_memory_allocator = gpu_memory_allocator,
        .texture = texture,
        .compile_thread_pool = compile_thread_pool,
        .compilation_result_queue = compilation_result_queue,
        .allocator = allocator,
        .chunk_tracker = chunk_tracker,
    };
}

pub fn initProgram(vertex_shader_path: []const u8, frag_shader_path: []const u8, allocator: std.mem.Allocator) !gl.Program {
    const vertex_shader_file = try std.fs.cwd().openFile(vertex_shader_path, .{});
    defer vertex_shader_file.close();

    const vertex_shader_source = try vertex_shader_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(vertex_shader_source);

    const frag_shader_file = try std.fs.cwd().openFile(frag_shader_path, .{});
    defer frag_shader_file.close();

    const frag_shader_source = try frag_shader_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(frag_shader_source);

    const vertex_shader = gl.Shader.create(.vertex);
    vertex_shader.source(1, &vertex_shader_source);

    const frag_shader = gl.Shader.create(.fragment);
    frag_shader.source(1, &frag_shader_source);

    const program = gl.Program.create();
    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();

    var log_buffer: [8192]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&log_buffer);
    const compile_log = try program.getCompileLog(fba.allocator());
    if (compile_log.len > 0) std.debug.print("{s}", .{compile_log});

    return program;
}

pub fn initVao() !gl.VertexArray {
    const vao = gl.VertexArray.create();
    vao.bind();
    vao.enableVertexAttribute(0);
    vao.attribFormat(0, 3, .float, false, 0);
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

pub fn initTexture() gl.Texture {
    const texture = gl.Texture.create(.@"2d_array");

    const texture_size = 1;
    const color_channels = 4;
    const texture_count = 256;

    texture.storage3D(1, .rgba8, texture_size, texture_size, texture_count);

    var texture_data: [texture_count * texture_size * texture_size * color_channels]u8 = undefined;
    var rand_impl: std.Random.DefaultPrng = .init(155215);
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

    return texture;
}

pub fn initCompileThreadPool(allocator: std.mem.Allocator) !*std.Thread.Pool {
    const pool = try allocator.create(std.Thread.Pool);
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = 1,
    });
    return pool;
}

pub fn renderFrame(self: *@This(), ingame: *const Game.IngameGame) !void {
    const mvp = getMvpMatrix(ingame.world.player, ingame.partial_tick);
    self.terrain_program.use();
    self.terrain_program.uniform1i(2, 0);
    self.terrain_program.uniformMatrix4(0, true, &.{mvp.data});
    self.entity_program.uniformMatrix4(0, true, &.{mvp.data});

    var entries = self.chunk_tracker.chunks.iterator();
    while (entries.next()) |entry| {
        const chunk_pos = entry.key_ptr.*;
        switch (entry.value_ptr.*) {
            .Rendering => |sections| {
                for (sections, 0..) |section, y| {
                    self.renderSection(.{ .x = chunk_pos.x, .y = @intCast(y), .z = chunk_pos.z }, section.render_info orelse continue);
                }
            },
            .Waiting => {},
        }
    }
    try self.renderEntities(&ingame.world);
}

pub fn renderSection(self: *@This(), section_pos: Vector3(i32), section: ChunkTracker.SectionRenderInfo) void {
    // uniform for section pos
    self.terrain_program.uniform3f(
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

pub fn renderEntities(self: *@This(), world: *const World) !void {
    var buffer: GpuStagingBuffer = .{ .backer = .init(self.allocator) };
    defer buffer.backer.deinit();
    self.entity_program.use();
    self.vao.bind();
    self.vao.vertexBuffer(0, self.entity_buffer, 0, 3 * @sizeOf(f32));
    var iter = world.entities.entities.iterator();
    var entity_count: usize = 0;
    while (iter.next()) |entry| {
        const entity = entry.key_ptr.*;
        switch (entity.*) {
            .removed => continue,
            inline else => |specific_entity| {
                const pos: Vector3(f64) = specific_entity.base.pos;
                const min = pos.sub(.{
                    .x = specific_entity.base.width * 0.5,
                    .y = 0,
                    .z = specific_entity.base.width * 0.5,
                });
                const max = pos.add(.{
                    .x = specific_entity.base.width * 0.5,
                    .y = specific_entity.base.height,
                    .z = specific_entity.base.width * 0.5,
                });
                try buffer.writeDebugCube(min.floatCast(f32), max.floatCast(f32));
                entity_count += 1;
            },
        }
    }
    self.entity_buffer.subData(0, u8, buffer.backer.items);
    gl.drawElements(.triangle_strip, entity_count * 6 * 5, .unsigned_int, 0);
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
    self.chunk_tracker.markChunkPresent(chunk_pos) catch |e| switch (e) {
        error.ChunkAlreadyExists => {}, // TODO: Figure out why this happens
        else => return e,
    };
}

pub fn onBlockUpdate(self: *@This(), block_pos: Vector3(i32)) !void {
    try self.chunk_tracker.markBlockPosDirty(block_pos);
}

pub fn updateAndDispatchDirtySections(self: *@This(), world: *const World, allocator: std.mem.Allocator) !void {
    const start: @import("util").Timer = .init();

    var iter = self.chunk_tracker.chunks.iterator();
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
                if (section_info.needsRecompile()) {
                    if (maybe_section) |_| {
                        // Send recompilation request if section is non-null
                        try self.dispatchCompilationTask(
                            .{ .x = chunk_pos.x, .y = @intCast(y), .z = chunk_pos.z },
                            world,
                            section_info.current_revision,
                            allocator,
                        );
                        section_info.alertCompilationDispatch();
                    } else {
                        // Fake recompilation and remove mesh data
                        section_info.alertCompilationDispatch();
                        section_info.alertCompilationRecieved(section_info.latest_sent_revision.?) catch unreachable;

                        if (section_info.render_info) |render_info| {
                            try self.gpu_memory_allocator.free(render_info.segment);
                            section_info.render_info = null;
                        }
                    }
                }
            }
        }

        if (start.ms() > 3) return;
    }
}

pub fn recompileAllChunks(self: *@This()) !void {
    var iter = self.chunk_tracker.chunks.iterator();
    while (iter.next()) |entry| {
        const chunk = entry.value_ptr;
        switch (chunk.*) {
            .Rendering => |*sections| {
                for (sections) |*section| {
                    try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
                    section.bumpRevision();
                }
            },
            .Waiting => {},
        }
    }
    // std.debug.assert(self.gpu_memory_allocator.detectLeaks() == false);
    self.gpu_memory_allocator.deinit();
    self.gpu_memory_allocator = try .init(self.allocator, 1024 * 1024 * 1024 * 2 - 1);
}

pub fn dispatchCompilationTask(self: *@This(), section_pos: Vector3(i32), world: *const World, revision: u32, allocator: std.mem.Allocator) !void {
    try self.compile_thread_pool.spawn(
        CompilationTask.runTask,
        .{
            try CompilationTask.create(section_pos, world, revision, allocator),
            &self.compilation_result_queue,
            allocator,
        },
    );
}

pub fn dispatchCompilationTaskSync(self: *@This(), section_pos: Vector3(i32), world: *const World, revision: u32, allocator: std.mem.Allocator) !void {
    CompilationTask.runTask(
        try CompilationTask.create(section_pos, world, revision, allocator),
        &self.compilation_result_queue,
        allocator,
    );
}

pub fn uploadCompilationResults(self: *@This()) !void {
    if (self.compilation_result_queue.sections.first == null) return;

    const start: @import("util").Timer = .init();

    while (self.compilation_result_queue.pop()) |compilation_result| {
        switch (compilation_result.result) {
            .Success => |compiled_section| {
                defer compiled_section.buffer.deinit();

                const chunk_pos: Vector2xz(i32) = .{ .x = compilation_result.section_pos.x, .z = compilation_result.section_pos.z };
                const section_y: usize = @intCast(compilation_result.section_pos.y);

                // Return if chunk is no longer being tracked
                const section_compile_info = &(self.chunk_tracker.chunks.getPtr(chunk_pos) orelse continue).Rendering[section_y];

                // Notify compile tracker
                section_compile_info.alertCompilationRecieved(compilation_result.revision) catch |e| switch (e) {
                    error.DuplicateRevision => std.debug.panic("duplicate revision recieved: {}\n", .{compilation_result.revision}),
                    // Return if revision is outdated
                    error.OutdatedRevision => continue,
                };

                const buffer_data = compiled_section.buffer.items;
                var render_info: ?ChunkTracker.SectionRenderInfo = null;
                if (buffer_data.len > 0) {
                    // Store rendering info
                    // Allocate gpu memory and upload segment
                    const segment = try self.gpu_memory_allocator.alloc(buffer_data.len);
                    self.gpu_memory_allocator.subData(segment, buffer_data);
                    render_info = .{
                        .quads = buffer_data.len / (@bitSizeOf(GpuStagingBuffer.GpuQuad) / 8),
                        .segment = segment,
                    };
                }
                try section_compile_info.replaceRenderInfo(render_info, &self.gpu_memory_allocator);
            },
            .Error => |e| std.debug.print("Error meshing section at {}: {}", .{ compilation_result.section_pos, e }),
        }
        if (start.ms() > 3) return;
    }
}

pub fn onUnloadChunk(self: *@This(), chunk_pos: Vector2xz(i32)) !void {
    const chunk = self.chunk_tracker.chunks.getPtr(chunk_pos).?;
    switch (chunk.*) {
        .Rendering => |*sections| {
            for (sections) |*section| {
                try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
            }
        },
        .Waiting => {},
    }
    self.chunk_tracker.removeChunk(chunk_pos);
}

pub fn unloadAllChunks(self: *@This()) !void {
    var iter = self.chunk_tracker.chunks.iterator();
    while (iter.next()) |entry| {
        const chunk = entry.value_ptr;
        switch (chunk.*) {
            .Rendering => |*sections| {
                for (sections) |*section| {
                    try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
                }
            },
            .Waiting => {},
        }
    }
    self.chunk_tracker.chunks.clearAndFree();
}

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}
