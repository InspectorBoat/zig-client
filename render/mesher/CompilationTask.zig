block_states: [18][18][18]Block.PhysicalState,
light: [18][18][18]packed struct { block: u4, sky: u4 },

pub const Error = error{ Canceled, OutOfMemory };

pub const Mesh = struct {
    quads: usize,
    buffer: std.ArrayList(u8),
};

pub fn getBlockState(self: *const @This(), block_pos: Vector3(i32)) Block.PhysicalState {
    return self.block_states[@intCast(block_pos.y)][@intCast(block_pos.z)][@intCast(block_pos.x)];
}
pub fn getBlock(self: *const @This(), block_pos: Vector3(i32)) Block {
    return self.block_states[@intCast(block_pos.y)][@intCast(block_pos.z)][@intCast(block_pos.x)].block;
}

pub fn create(allocator: std.mem.Allocator, section_pos: Vector3(i32), world: *const World) !*@This() {
    @setRuntimeSafety(false);

    const task = try allocator.create(@This());

    const chunk = world.chunks.get(.{ .x = section_pos.x, .z = section_pos.z }).?;
    const section = chunk.sections[@intCast(section_pos.y)].?;

    // 16^3 interior
    var i: usize = 0;
    for (1..17) |y| {
        for (1..17) |z| {
            @memcpy(task.block_states[y][z][1..17], section.block_states[i..][0..16]);

            const light_bytes = i >> 1;
            const block_bytes = section.block_light.bytes[light_bytes..][0..8];
            const sky_bytes = section.sky_light.bytes[light_bytes..][0..8];
            const dst = task.light[y][z][1..17];
            for (0..8) |b| {
                dst[2 * b + 0] = .{ .block = @truncate(block_bytes[b]), .sky = @truncate(sky_bytes[b]) };
                dst[2 * b + 1] = .{ .block = @truncate(block_bytes[b] >> 4), .sky = @truncate(sky_bytes[b] >> 4) };
            }

            i += 16;
        }
    }

    var neighbor_sections: [3][3][3]?*const World.Section = undefined;
    for (0..3) |dy| {
        const section_y = section_pos.y + @as(i32, @intCast(dy)) - 1;
        for (0..3) |dz| {
            for (0..3) |dx| {
                const neighbor_chunk_pos: Vector2xz(i32) = .{
                    .x = section_pos.x + @as(i32, @intCast(dx)) - 1,
                    .z = section_pos.z + @as(i32, @intCast(dz)) - 1,
                };
                neighbor_sections[dy][dz][dx] =
                    if (section_y < 0 or section_y > 15)
                        null
                    else if (world.chunks.get(neighbor_chunk_pos)) |neighbor_chunk|
                        neighbor_chunk.sections[@intCast(section_y)]
                    else
                        null;
            }
        }
    }

    for (0..18) |y| {
        for (0..18) |z| {
            for (0..18) |x| {
                if (y != 0 and y != 17 and x != 0 and x != 17 and z != 0 and z != 17) continue;

                const ny: usize = if (y == 0) 0 else if (y == 17) 2 else 1;
                const nz: usize = if (z == 0) 0 else if (z == 17) 2 else 1;
                const nx: usize = if (x == 0) 0 else if (x == 17) 2 else 1;
                const ly: usize = if (y == 0) 15 else if (y == 17) 0 else y - 1;
                const lz: usize = if (z == 0) 15 else if (z == 17) 0 else z - 1;
                const lx: usize = if (x == 0) 15 else if (x == 17) 0 else x - 1;

                if (neighbor_sections[ny][nz][nx]) |neighbor| {
                    const index = (ly << 8) | (lz << 4) | lx;
                    task.block_states[y][z][x] = neighbor.block_states[index];

                    const block_light: u4 = @truncate(neighbor.block_light.bytes[index / 2] >> @intCast((index & 1) * 4));
                    const sky_light: u4 = @truncate(neighbor.sky_light.bytes[index / 2] >> @intCast((index & 1) * 4));
                    task.light[y][z][x] = .{ .block = block_light, .sky = sky_light };
                } else {
                    task.block_states[y][z][x] = .air;
                    task.light[y][z][x] = .{ .block = 15, .sky = 15 };
                }
            }
        }
    }
    return task;
}

pub fn compile(task: *@This(), io: std.Io, allocator: std.mem.Allocator, tracker: *CompilationTracker, completion_token: *std.SinglyLinkedList.Node) Error!Mesh {
    @setRuntimeSafety(false);

    defer {
        tracker.addCompleted(io, completion_token);
        allocator.destroy(task);
    }

    var quad_count: usize = 0;
    var staging: GpuStagingBuffer = try .initCapacity(allocator, 4096);
    errdefer staging.deinit();

    var cull_table: [16][16][16]CullMask = undefined;
    const culling_blocks = block_attributes.culls_adjacent_faces;
    for (1..17) |y| {
        for (1..17) |z| {
            for (1..17) |x| {
                cull_table[y - 1][z - 1][x - 1] = .{
                    // zig fmt: off
                    .west =  culling_blocks.contains(task.block_states[y][z][x - 1].block),
                    .east =  culling_blocks.contains(task.block_states[y][z][x + 1].block),
                    .down =  culling_blocks.contains(task.block_states[y - 1][z][x].block),
                    .up =    culling_blocks.contains(task.block_states[y + 1][z][x].block),
                    .north = culling_blocks.contains(task.block_states[y][z - 1][x].block),
                    .south = culling_blocks.contains(task.block_states[y][z + 1][x].block),
                    // zig fmt: on
                };
            }
        }
    }

    for (1..17) |y| {
        try io.checkCancel();
        for (1..17) |z| {
            for (1..17) |x| {
                const cull = cull_table[y - 1][z - 1][x - 1];
                if (cull == CullMask.all) continue;

                const block_state: Block.VirtualState = .resolve(task.block_states[y][z][x], task, .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                const model = render.renderer.blockstate_to_model_lookup.get(block_state) orelse continue;

                for (model.faces) |face| {
                    if (face.cullface) |cullface| if (cull.get(cullface)) continue;

                    const pos_vec: Vector3(f32) = .{
                        .x = @floatFromInt(x - 1),
                        .y = @floatFromInt(y - 1),
                        .z = @floatFromInt(z - 1),
                    };

                    const light = if (face.cullface) |cullface| switch (cullface) {
                        // zig fmt: off
                        .west =>  task.light[y][z][x - 1],
                        .east =>  task.light[y][z][x + 1],
                        .down =>  task.light[y - 1][z][x],
                        .up =>    task.light[y + 1][z][x],
                        .north => task.light[y][z - 1][x],
                        .south => task.light[y][z + 1][x],
                        // zig fmt: on
                    } else task.light[y][z][x];

                    for (face.pos, face.uv) |vertex_pos, uv| {
                        try staging.writeVertex(
                            .add(pos_vec, vertex_pos),
                            light.block,
                            light.sky,
                            face.texture,
                            uv,
                            face.cullface,
                        );
                    }
                    quad_count += 1;
                }
            }
        }
    }
    return .{
        .buffer = staging.backer,
        .quads = quad_count,
    };
}

const CullMask = packed struct(u6) {
    down: bool = false,
    up: bool = false,
    north: bool = false,
    south: bool = false,
    west: bool = false,
    east: bool = false,

    pub inline fn get(self: @This(), face: Direction) bool {
        @setRuntimeSafety(false);
        return @backingInt(self) & (@as(u8, 1) << @intCast(@backingInt(face))) > 0;
    }

    const all: @This() = .{ .down = true, .up = true, .north = true, .south = true, .west = true, .east = true };

    comptime {
        for (@typeInfo(@This()).@"struct".field_names) |field_name| {
            std.debug.assert(@bitOffsetOf(@This(), field_name) == @backingInt(@field(Direction, field_name)));
        }
    }
};

const std = @import("std");

const main = @import("main");
const render = @import("render");

const block_attributes = @import("block_attributes.zig");

const Block = main.Block;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const Vector2xz = main.Vector2xz;
const World = main.World;
const CompilationTracker = render.mesher.CompilationTracker;
const GpuStagingBuffer = render.mesher.GpuStagingBuffer;
