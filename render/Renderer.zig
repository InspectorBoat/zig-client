const std = @import("std");

const main = @import("main");
const render = @import("render");
const za = @import("zalgebra");
const gl = @import("zgl");
const zigimg = @import("zigimg");

const Block = main.Block;
const Chunk = main.Chunk;
const Vector2xy = main.Vector2xy;
const Client = main.Client;
const LocalPlayerEntity = main.Entity.LocalPlayer;
const Vector2xz = main.Vector2xz;
const Vector3 = main.Vector3;
const World = main.World;
const GpuMemoryAllocator = render.GpuMemoryAllocator;
const gui = render.gui;
const ChunkTracker = render.mesher.ChunkTracker;
const CompilationTask = render.mesher.CompilationTask;
const CompilationTracker = render.mesher.CompilationTracker;
const GpuStagingBuffer = render.mesher.GpuStagingBuffer;
const resource_pack = render.resource_pack;
const BakedModel = resource_pack.BakedModel;
const Mat4 = za.Mat4;

pub const TextureHandle = enum(u16) { _ };

allocator: std.mem.Allocator,
vao: gl.VertexArray,
terrain_program: gl.Program,
index_buffer: gl.Buffer,
gpu_memory_allocator: GpuMemoryAllocator,
/// Block textures
texture: gl.Texture,

/// Collects compiled geometry from in-flight tasks
compilation_tracker: CompilationTracker,
/// Tracks whether a chunk and its sections are ready to be compiled or rendered
chunk_tracker: ChunkTracker,

lookup_table: std.AutoHashMapUnmanaged(Block.VirtualState, BakedModel),

// Debug
debug_program: gl.Program,
debug_buffer: gl.Buffer,
@"3d_debug_staging_buffer": GpuStagingBuffer,
@"2d_debug_staging_buffer": GpuStagingBuffer,
@"3d_vao": gl.VertexArray,
@"2d_vao": gl.VertexArray,
debug_options: struct {
    terrain_draw_mode: gl.DrawMode = .fill,
    chunk_borders: bool = false,
    inventory: bool = false,
} = .{},

pub fn init(io: std.Io, allocator: std.mem.Allocator) !@This() {
    gl.enable(.depth_test);
    gl.enable(.cull_face);

    const terrain_program = try initProgram(allocator, "shader/terrain.glsl.vert", "shader/terrain.glsl.frag");
    const index_buffer = try initIndexBuffer(allocator);
    const gpu_memory_allocator: GpuMemoryAllocator = try .init(allocator, 1024 * 1024 * 1024 * 2 - 1);
    const vao: gl.VertexArray = .create();

    const compilation_tracker: CompilationTracker = try .init(allocator, 128);
    const chunk_tracker: ChunkTracker = .init;

    const debug_program = try initProgram(allocator, "shader/debug.glsl.vert", "shader/debug.glsl.frag");
    const debug_buffer: gl.Buffer = .create();
    debug_buffer.storage(f32, 6 * 5 * 1024, null, .{ .dynamic_storage = true });
    const @"3d_debug_staging_buffer": GpuStagingBuffer = .{ .backer = .empty, .allocator = allocator };
    const @"2d_debug_staging_buffer": GpuStagingBuffer = .{ .backer = .empty, .allocator = allocator };

    const @"3d_vao" = try init3dVao();
    const @"2d_vao" = try init2dVao();

    vao.elementBuffer(index_buffer);
    @"3d_vao".elementBuffer(index_buffer);
    @"2d_vao".elementBuffer(index_buffer);

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const blockstate_to_model_lookup_table, const named_block_textures = try resource_pack.init(
        io,
        allocator,
        arena.allocator(),
        try .openDirAbsolute(io, "/home/inspectorboat/src/zig-client/vanilla-pack", .{}),
    );
    const texture = try initTexture(allocator, named_block_textures);

    std.log.scoped(.resource_pack).debug("resource pack loading used {} mb", .{arena.queryCapacity() / 1024 / 1024});
    return .{
        .allocator = allocator,

        .vao = vao,
        .terrain_program = terrain_program,
        .index_buffer = index_buffer,
        .gpu_memory_allocator = gpu_memory_allocator,
        .texture = texture,

        .compilation_tracker = compilation_tracker,
        .chunk_tracker = chunk_tracker,

        .lookup_table = blockstate_to_model_lookup_table,

        .debug_buffer = debug_buffer,
        .debug_program = debug_program,
        .@"3d_debug_staging_buffer" = @"3d_debug_staging_buffer",
        .@"2d_debug_staging_buffer" = @"2d_debug_staging_buffer",
        .@"3d_vao" = @"3d_vao",
        .@"2d_vao" = @"2d_vao",
    };
}

pub fn initProgram(allocator: std.mem.Allocator, vertex_shader_path: []const u8, frag_shader_path: []const u8) !gl.Program {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    const vertex_shader_source = try std.Io.Dir.cwd().readFileAlloc(
        io,
        vertex_shader_path,
        allocator,
        .unlimited,
    );
    defer allocator.free(vertex_shader_source);

    const frag_shader_source = try std.Io.Dir.cwd().readFileAlloc(
        io,
        frag_shader_path,
        allocator,
        .unlimited,
    );
    defer allocator.free(frag_shader_source);

    const vertex_shader: gl.Shader = .create(.vertex);
    vertex_shader.source(1, &vertex_shader_source);
    vertex_shader.compile();
    try checkShader(allocator, vertex_shader);

    const frag_shader: gl.Shader = .create(.fragment);
    frag_shader.source(1, &frag_shader_source);
    frag_shader.compile();
    try checkShader(allocator, frag_shader);

    const program: gl.Program = .create();
    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();
    try checkProgram(allocator, program);

    return program;
}

fn checkShader(allocator: std.mem.Allocator, shader: gl.Shader) !void {
    const shader_type: gl.ShaderType = @fromBackingInt(@intCast(shader.get(.shader_type)));
    const compiled = shader.get(.compile_status) == @intFromBool(true);

    if (!compiled) {
        std.log.scoped(.compile_shaders).err("{s} shader failed to compile", .{@tagName(shader_type)});
    }
    const log = try shader.getCompileLog(allocator);
    defer allocator.free(log);

    if (log.len > 0) {
        std.log.scoped(.compile_shaders).info("{s} shader compile log: {s}", .{ @tagName(shader_type), log });
    }
}

fn checkProgram(allocator: std.mem.Allocator, program: gl.Program) !void {
    const linked = program.get(.link_status) == @intFromBool(true);

    if (!linked) {
        std.log.scoped(.link_program).err("program failed to link", .{});
    }
    const log = try program.getCompileLog(allocator);
    defer allocator.free(log);

    if (log.len > 0) {
        std.log.scoped(.link_program).info("program compile log: {s}", .{log});
    }
}

pub fn init3dVao() !gl.VertexArray {
    const vao: gl.VertexArray = .create();
    vao.enableVertexAttribute(0);
    vao.attribFormat(0, 3, .float, false, 0);
    vao.attribBinding(0, 0);

    return vao;
}

pub fn init2dVao() !gl.VertexArray {
    const vao: gl.VertexArray = .create();

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
    const index_buffer: gl.Buffer = .create();
    index_buffer.storage(u32, 1024 * 1024 * 8, @ptrCast(indices), .{});

    gl.enable(.primitive_restart);
    gl.primitiveRestartIndex(primitive_restart_index);

    return index_buffer;
}

/// Uploads every decoded sprite as one layer of a 2D array texture.
///
/// Layer N is `named_block_textures.values()[N]`, which is the same index
/// `ResolvedBlockModel.Element.Face.TextureHandle` resolves to.
pub fn initTexture(allocator: std.mem.Allocator, named_block_textures: std.array_hash_map.String(zigimg.Image)) !gl.Texture {
    const texture: gl.Texture = .create(.@"2d_array");

    // every block sprite is 16x16; anything else is truncated to its top-left
    // corner for now. Animation strips land here too and lose every frame but
    // the first.
    const layer_size = 16;
    const channels = 4;
    const layer_count = named_block_textures.count();
    const bytes_per_layer = layer_size * layer_size * channels;

    texture.storage3D(1, .rgba8, layer_size, layer_size, layer_count);

    const texture_data = try allocator.alloc(u8, bytes_per_layer * layer_count);
    defer allocator.free(texture_data);
    @memset(texture_data, 0);

    var truncated: usize = 0;
    var converted: usize = 0;
    var failed: usize = 0;

    defer std.log.scoped(.resource_pack).debug(
        "{d} sprite layers: {d} truncated to {d}x{d}, {d} converted, {d} failed",
        .{ layer_count, truncated, layer_size, layer_size, converted, failed },
    );

    for (named_block_textures.keys(), named_block_textures.values(), 0..) |name, *image, layer| {
        if (image.width != layer_size or image.height != layer_size) truncated += 1;

        // most sprites decode straight to rgba8; anything else
        // we convert with zigimg
        var owned_storage: ?zigimg.color.PixelStorage = null;
        defer if (owned_storage) |s| s.deinit(allocator);

        if (image.pixels != .rgba32) {
            owned_storage = zigimg.PixelFormatConverter.convert(allocator, &image.pixels, .rgba32) catch {
                std.log.scoped(.resource_pack).warn("could not convert {s} to rgba8, leaving it blank", .{name});
                failed += 1;
                continue;
            };
            converted += 1;
        }

        const pixels = switch (image.pixels) {
            .rgba32 => |p| p,
            else => owned_storage.?.rgba32,
        };

        // This is a really shitty hack,
        // but I'm tired of looking at monochrome grass all day
        const tint: Vector3(f32) = if (std.mem.eql(u8, name, "grass_top") or std.mem.eql(u8, name, "grass_side_overlay"))
            .{ .x = 0.52, .y = 0.7, .z = 0.3 }
        else if (std.mem.eql(u8, name, "tallgrass") or std.mem.startsWith(u8, name, "double_plant_grass"))
            .{ .x = 0.45, .y = 0.6, .z = 0.3 }
        else if (std.mem.containsAtLeast(u8, name, 1, "leaves"))
            .{ .x = 0.22, .y = 0.45, .z = 0.15 }
        else
            .splat(1);

        const dst = texture_data[layer * bytes_per_layer ..][0..bytes_per_layer];
        const rows = @min(image.height, layer_size);
        const cols = @min(image.width, layer_size);
        for (0..rows) |y| {
            for (0..cols) |x| {
                const color = pixels[y * image.width + x];
                const out = (y * layer_size + x) * channels;
                dst[out + 0] = @round(@as(f32, color.r) * tint.x);
                dst[out + 1] = @round(@as(f32, color.g) * tint.y);
                dst[out + 2] = @round(@as(f32, color.b) * tint.z);
                dst[out + 3] = color.a;
            }
        }
    }

    texture.subImage3D(
        0,
        0,
        0,
        0,
        layer_size,
        layer_size,
        layer_count,
        .rgba,
        .unsigned_byte,
        texture_data.ptr,
    );
    texture.bindTo(0);
    texture.parameter(.wrap_s, .repeat);
    texture.parameter(.wrap_t, .repeat);
    texture.parameter(.wrap_r, .repeat);

    texture.parameter(.min_filter, .nearest);
    texture.parameter(.mag_filter, .nearest);

    return texture;
}

pub fn renderFrame(self: *@This(), game: *const Client.Game) !void {
    const mvp = getMvpMatrix(game.world.player, game.partial_tick);
    {
        self.terrain_program.use();
        self.vao.bind();
        self.terrain_program.uniform1i(16, 0);
        self.terrain_program.uniformMatrix4(0, true, &.{mvp.data});

        self.terrain_program.uniform1i(2, @intFromBool(true));
        self.terrain_program.uniform4f(3, 0.719411765, 0.767843137, 0.921568627, 1);
        self.terrain_program.uniform1f(4, 100);
        self.terrain_program.uniform1f(5, 200);
        self.terrain_program.uniform1f(6, 0.01);
        self.terrain_program.uniform1i(7, 9729);
        self.terrain_program.uniform1i(8, 34139);

        const mv = getMvMatrix(game.world.player, game.partial_tick);
        self.terrain_program.uniformMatrix4(9, true, &.{mv.data});

        gl.polygonMode(.front_and_back, self.debug_options.terrain_draw_mode);

        var entries = self.chunk_tracker.chunks.iterator();
        while (entries.next()) |entry| {
            const chunk_pos = entry.key_ptr.*;
            switch (entry.value_ptr.*) {
                .rendering => |sections| {
                    for (sections, 0..) |section, y| {
                        self.renderSection(.{ .x = chunk_pos.x, .y = @intCast(y), .z = chunk_pos.z }, section.render_info orelse continue);
                    }
                },
                .waiting => {},
            }
        }
    }
    {
        self.debug_program.uniformMatrix4(0, true, &.{mvp.data});

        try self.bufferCrosshair(&game.world);
        try self.bufferEntities(&game.world, game.partial_tick);
        try self.bufferBlockBreaking(&game.world);
        if (self.debug_options.chunk_borders) try self.bufferChunkDebug(&game.world);

        self.render3dDebug();
    }
    {
        const identity: za.Mat4 = .identity();
        self.debug_program.uniformMatrix4(0, true, &.{identity.data});

        if (self.debug_options.inventory) {
            try gui.bufferInventory(self, &game.world, render.window_input.mousePosInClipSpace());
        }

        self.render2dDebug();
    }
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
    gl.bindBufferRange(
        self.gpu_memory_allocator.backing_buffer,
        .shader_storage_buffer,
        0,
        @intCast(section.segment.offset),
        @intCast(section.segment.length),
    );

    // draw chunk
    gl.drawElements(
        .triangle_fan,
        // count includes primitive restart indices, thus there are actually 5 indices per quad
        section.quads * 5,
        .unsigned_int,
        0,
    );
}

pub fn bufferEntities(self: *@This(), world: *const World, partial_tick: f64) !void {
    var iter = world.entity_tracker.entities.iterator();
    while (iter.next()) |entry| {
        const entity = entry.key_ptr.*;
        switch (entity.*) {
            .removed => continue,
            inline else => |specific_entity| {
                const pos: Vector3(f64) = .add(
                    specific_entity.base.prev_pos,
                    .mul(
                        .sub(specific_entity.base.pos, specific_entity.base.prev_pos),
                        .splat(partial_tick),
                    ),
                );
                const min: Vector3(f64) = .sub(pos, .{
                    .x = specific_entity.base.width * 0.5,
                    .y = 0,
                    .z = specific_entity.base.width * 0.5,
                });
                const max: Vector3(f64) = .add(pos, .{
                    .x = specific_entity.base.width * 0.5,
                    .y = specific_entity.base.height,
                    .z = specific_entity.base.width * 0.5,
                });
                try self.@"3d_debug_staging_buffer".writeDebugCube(.floatCast(min), .floatCast(max));
            },
        }
    }
}

pub fn bufferCrosshair(self: *@This(), world: *const World) !void {
    switch (world.crosshair) {
        .block => |block| {
            const virtual_state = world.resolveVirtualBlockState(block.block_pos);

            var hitboxes_buffer: [5]main.Box(f64) = undefined;
            var hitboxes: std.ArrayList(main.Box(f64)) = .initBuffer(&hitboxes_buffer);
            virtual_state.getCollisionHitboxes(&hitboxes);

            for (hitboxes.items) |hitbox| {
                try self.@"3d_debug_staging_buffer".writeDebugCube(
                    .add(.floatCast(hitbox.min), .floatFromInt(block.block_pos)),
                    .add(.floatCast(hitbox.max), .floatFromInt(block.block_pos)),
                );
            }
        },
        .entity => |entity| {
            _ = entity;
            // try self.@"3d_debug_staging_buffer".writeDebugCube(
            //     .sub(.floatCast(entity.pos), .{ .x = 0.25, .y = 0.25, .z = 0.25 }),
            //     .add(.floatCast(entity.pos), .{ .x = 0.25, .y = 0.25, .z = 0.25 }),
            // );
        },
        .miss => return,
    }
}

pub fn bufferChunkDebug(self: *@This(), world: *const World) !void {
    const player = world.player;
    const block_pos: Vector3(i32) = .intFromFloat(player.base.pos);
    const section_pos: Vector3(i32) = .divFloor(block_pos, .splat(16));
    const min: Vector3(i32) = .mul(section_pos, .splat(16));
    const max: Vector3(i32) = .mul(.add(section_pos, .splat(1)), .splat(16));
    try self.@"3d_debug_staging_buffer".writeDebugCube(.floatFromInt(min), .floatFromInt(max));
}

pub fn bufferBlockBreaking(self: *@This(), world: *const World) !void {
    if (world.mining_state) |mining_state| {
        const radius: f32 = mining_state.progress / 2.0;
        const center: Vector3(f32) = .add(.floatFromInt(mining_state.block_pos), .splat(0.5));
        try self.@"3d_debug_staging_buffer".writeDebugCube(
            .sub(center, .splat(radius)),
            .add(center, .splat(radius)),
        );
    }
}

pub fn render3dDebug(self: *@This()) void {
    gl.disable(.depth_test);
    gl.disable(.cull_face);

    defer gl.enable(.depth_test);
    defer gl.enable(.cull_face);

    self.debug_program.use();
    self.@"3d_vao".bind();
    self.@"3d_vao".vertexBuffer(0, self.debug_buffer, 0, 3 * @sizeOf(f32));
    gl.polygonMode(.front_and_back, .line);

    self.debug_buffer.subData(0, u8, self.@"3d_debug_staging_buffer".backer.items);
    gl.drawElements(.triangle_strip, self.@"3d_debug_staging_buffer".backer.items.len / @sizeOf(f32) / 3 / 4 * 5, .unsigned_int, 0);

    self.@"3d_debug_staging_buffer".backer.items.len = 0;
}

pub fn render2dDebug(self: *@This()) void {
    gl.disable(.depth_test);
    gl.disable(.cull_face);

    defer gl.enable(.depth_test);
    defer gl.enable(.cull_face);

    self.debug_program.use();
    self.@"2d_vao".bind();
    self.@"2d_vao".vertexBuffer(0, self.debug_buffer, 0, 3 * @sizeOf(f32));
    gl.polygonMode(.front_and_back, .fill);

    self.debug_buffer.subData(0, u8, self.@"2d_debug_staging_buffer".backer.items);
    gl.drawElements(.triangle_strip, self.@"2d_debug_staging_buffer".backer.items.len / @sizeOf(f32) / 3 / 4 * 5, .unsigned_int, 0);

    self.@"2d_debug_staging_buffer".backer.items.len = 0;
}

pub fn getMvpMatrix(player: LocalPlayerEntity, partial_tick: f64) Mat4 {
    const eye_pos = player.getInterpolatedEyePos(partial_tick, lerp);

    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);

    const projection: Mat4 = za.perspective(90.0, window_width / window_height, 0.05, 1000.0);

    const view: Mat4 = .mul(
        .fromEulerAngles(.new(player.base.rotation.pitch, 0, 0)),
        .fromEulerAngles(.new(0, player.base.rotation.yaw + 180, 0)),
    );

    const model: Mat4 = .fromTranslate(.new(
        @floatCast(-eye_pos.x),
        @floatCast(-eye_pos.y),
        @floatCast(-eye_pos.z),
    ));

    return .mul(projection, .mul(view, model));
}

pub fn getMvMatrix(player: LocalPlayerEntity, partial_tick: f64) Mat4 {
    const eye_pos = player.getInterpolatedEyePos(partial_tick, lerp);

    const view: Mat4 = .mul(
        .fromEulerAngles(.new(player.base.rotation.pitch, 0, 0)),
        .fromEulerAngles(.new(0, player.base.rotation.yaw + 180, 0)),
    );

    const model: Mat4 = .fromTranslate(.new(
        @floatCast(-eye_pos.x),
        @floatCast(-eye_pos.y),
        @floatCast(-eye_pos.z),
    ));

    return .mul(view, model);
}

pub fn onChunkUpdate(self: *@This(), chunk_pos: Vector2xz(i32)) !void {
    self.chunk_tracker.markChunkPresent(self.allocator, chunk_pos) catch |e| switch (e) {
        error.ChunkAlreadyExists => {}, // TODO: Figure out why this happens
        else => return e,
    };
}

pub fn onBlockUpdate(self: *@This(), block_pos: Vector3(i32)) !void {
    try self.chunk_tracker.markAreaDirty(
        .sub(block_pos, .splat(1)),
        .add(block_pos, .splat(1)),
    );
}

pub fn updateAndDispatchDirtySections(self: *@This(), io: std.Io, allocator: std.mem.Allocator, world: *const World) !void {
    const start: std.Io.Clock.Timestamp = .now(io, .real);

    var iter = self.chunk_tracker.chunks.iterator();

    while (iter.next()) |entry| {
        const chunk_pos = entry.key_ptr.*;
        const chunk_info = entry.value_ptr;
        if (chunk_info.* == .waiting and chunk_info.waiting.isReady()) {
            chunk_info.* = .{ .rendering = @splat(.{}) };
        }
        if (chunk_info.* == .rendering) {
            const chunk: *const Chunk = world.chunks.get(chunk_pos).?;

            // Only dispatch task if section actually exists, even if adjacent chunks update
            for (&chunk_info.rendering, chunk.sections, 0..) |*section_info, maybe_section, y| {
                if (section_info.needsRecompile()) {
                    if (maybe_section) |_| {
                        // Send recompilation request if section is non-null
                        self.dispatchCompilationTask(
                            io,
                            allocator,
                            world,
                            .{ .x = chunk_pos.x, .y = @intCast(y), .z = chunk_pos.z },
                            section_info.current_revision,
                        ) catch |err| switch (err) {
                            // out of in-flight slots
                            error.QueueFull => return,
                            else => |e| return e,
                        };
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

        if (start.untilNow(io).raw.toMilliseconds() > 3) return;
    }
}

pub fn recompileAllChunks(self: *@This()) !void {
    var iter = self.chunk_tracker.chunks.iterator();
    while (iter.next()) |entry| {
        const chunk = entry.value_ptr;
        switch (chunk.*) {
            .rendering => |*sections| {
                for (sections) |*section| {
                    try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
                    section.markDirty();
                }
            },
            .waiting => {},
        }
    }
    std.debug.assert(self.gpu_memory_allocator.detectLeaks() == false);
    self.gpu_memory_allocator.deinit();
    self.gpu_memory_allocator = try .init(self.allocator, 1024 * 1024 * 1024 * 2 - 1);
}

pub fn dispatchCompilationTask(
    self: *@This(),
    io: std.Io,
    allocator: std.mem.Allocator,
    world: *const World,
    section_pos: Vector3(i32),
    revision: u32,
) !void {
    const slot = try self.compilation_tracker.take(section_pos, revision);
    errdefer self.compilation_tracker.releaseUnstarted(slot);
    slot.future = io.async(
        CompilationTask.compile,
        .{
            try .create(allocator, section_pos, world),
            io,
            allocator,
            &self.compilation_tracker,
            &slot.next_completed,
        },
    );
}

pub fn uploadCompilationResults(self: *@This(), io: std.Io) !void {
    const start: std.Io.Clock.Timestamp = .now(io, .real);

    while (self.compilation_tracker.popCompleted(io)) |completed| {
        if (completed.mesh) |mesh_const| {
            var mesh = mesh_const;
            defer mesh.buffer.deinit(self.allocator);

            const chunk_pos: Vector2xz(i32) = .{ .x = completed.section_pos.x, .z = completed.section_pos.z };
            const section_y: usize = @intCast(completed.section_pos.y);

            // Return if chunk is no longer being tracked
            const section_compile_info = &(self.chunk_tracker.chunks.getPtr(chunk_pos) orelse continue).rendering[section_y];

            // Notify compile tracker
            section_compile_info.alertCompilationRecieved(completed.revision) catch |e| switch (e) {
                error.DuplicateRevision => std.debug.panic("duplicate revision recieved for {}", .{completed.section_pos}),
                // Return if revision is outdated
                error.OutdatedRevision => std.log.scoped(.section_revision).warn("recieved outdated revision {} for {}", .{ completed.revision, completed.section_pos }),
            };
            std.log.scoped(.section_revision).debug("recieved revision {} for {}", .{ completed.revision, completed.section_pos });
            const buffer_data = mesh.buffer.items;
            var render_info: ?ChunkTracker.SectionRenderInfo = null;
            if (buffer_data.len > 0) {
                // Store rendering info
                // Allocate gpu memory and upload segment
                const segment = try self.gpu_memory_allocator.alloc(buffer_data.len);
                self.gpu_memory_allocator.subData(segment, buffer_data);
                render_info = .{
                    .quads = mesh.quads,
                    .segment = segment,
                };
            }
            try section_compile_info.replaceRenderInfo(render_info, &self.gpu_memory_allocator);
        } else |e| std.log.scoped(.section_revision).err("error meshing section at {}: {}", .{ completed.section_pos, e });
        if (start.untilNow(io).raw.toMilliseconds() > 3) return;
    }
}

pub fn onUnloadChunk(self: *@This(), chunk_pos: Vector2xz(i32)) !void {
    const chunk = self.chunk_tracker.chunks.getPtr(chunk_pos).?;
    switch (chunk.*) {
        .rendering => |*sections| {
            for (sections) |*section| {
                try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
            }
        },
        .waiting => {},
    }
    self.chunk_tracker.removeChunk(chunk_pos);
}

pub fn unloadAllChunks(self: *@This(), allocator: std.mem.Allocator) !void {
    var iter = self.chunk_tracker.chunks.iterator();
    while (iter.next()) |entry| {
        const chunk = entry.value_ptr;
        switch (chunk.*) {
            .rendering => |*sections| {
                for (sections) |*section| {
                    try section.replaceRenderInfo(null, &self.gpu_memory_allocator);
                }
            },
            .waiting => {},
        }
    }
    self.chunk_tracker.chunks.clearAndFree(allocator);
}

pub fn deinit(self: *@This(), io: std.Io) !void {
    try self.unloadAllChunks(self.allocator);
    self.gpu_memory_allocator.deinit();
    self.@"3d_debug_staging_buffer".backer.deinit(self.allocator);
    self.compilation_tracker.deinit(io);
    var iter = self.lookup_table.iterator();
    while (iter.next()) |entry| {
        self.allocator.free(entry.value_ptr.faces);
    }
    self.lookup_table.deinit(self.allocator);
}

pub fn lerp(start: f64, end: f64, progress: f64) f64 {
    return (end - start) * progress + start;
}
