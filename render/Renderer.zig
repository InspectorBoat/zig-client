const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Box = @import("root").Box;
const Chunk = @import("root").Chunk;
const GpuStagingBuffer = @import("./GpuStagingBuffer.zig");
const GpuMemoryAllocator = @import("./GpuMemoryAllocator.zig");

vao: gl.VertexArray,
program: gl.Program,
debug_cube_buffer: gl.Buffer,
debug_cube_staging_buffer: GpuStagingBuffer = .{},
sections: std.AutoHashMap(Vector3(i32), SectionRenderInfo),
gpu_memory_allocator: GpuMemoryAllocator,
texture: gl.Texture,

pub fn init(allocator: std.mem.Allocator) !@This() {
    const program = try createProgram(.{@embedFile("./triangle.glsl.vert")}, .{@embedFile("./triangle.glsl.frag")});
    program.use();

    const vao = gl.VertexArray.create();
    vao.bind();

    vao.enableVertexAttribute(0);
    vao.attribFormat(0, 3, .float, false, 0);
    vao.attribBinding(0, 0);

    var indices: [1024 * 1024]u32 = undefined;
    for (&indices, 0..) |*index, i| {
        index.* = @intCast(i);
    }
    const index_buffer = gl.Buffer.create();
    index_buffer.storage(u32, 1024 * 1024, @ptrCast(&indices), .{});
    index_buffer.bind(.element_array_buffer);

    const debug_cube_buffer = gl.Buffer.create();
    debug_cube_buffer.storage(f32, 36 * 3 * 1024, null, .{ .dynamic_storage = true });

    return .{
        .vao = vao,
        .program = program,
        .debug_cube_buffer = debug_cube_buffer,
        .sections = std.AutoHashMap(Vector3(i32), SectionRenderInfo).init(allocator),
        .gpu_memory_allocator = try GpuMemoryAllocator.init(allocator, 1024 * 1024 * 1024 * 2 - 1),
        .texture = makeTexture(),
    };
}

pub fn renderDebugBox(self: *@This(), box: Box(f64)) void {
    self.debug_cube_staging_buffer.writeBox(
        .{
            .x = @floatCast(box.min.x),
            .y = @floatCast(box.min.y),
            .z = @floatCast(box.min.z),
        },
        .{
            .x = @floatCast(box.max.x),
            .y = @floatCast(box.max.y),
            .z = @floatCast(box.max.z),
        },
    );
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
                                const pos_vec: Vector3(f64) = .{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) };
                                staging.writeBox(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32));
                            }
                        }
                    }
                }
            }
            if (staging.write_index == 0) continue;

            const segment = try self.gpu_memory_allocator.alloc(staging.write_index, allocator);
            self.gpu_memory_allocator.subData(segment, staging.getSlice());

            // const buffer = gl.Buffer.create();
            // buffer.storage(u8, staging.write_index, @ptrCast(staging.getSlice()), .{});

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

pub fn makeTexture() gl.Texture {
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
    texture.bindTo(52);
    texture.parameter(.wrap_s, .repeat);
    texture.parameter(.wrap_t, .repeat);
    texture.parameter(.wrap_r, .repeat);

    texture.parameter(.min_filter, .nearest);
    texture.parameter(.mag_filter, .nearest);

    gl.uniform1i(3, 52);
    return texture;
}

pub fn createProgram(vertex_shader_source: [1][]const u8, frag_shader_source: [1][]const u8) !gl.Program {
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
    std.debug.print("{s}", .{try program.getCompileLog(fba.allocator())});

    return program;
}
