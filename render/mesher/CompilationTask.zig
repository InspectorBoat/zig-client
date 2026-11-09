block_states: [18][18][18]Block.PhysicalState,
block_light: PackedNibbleArray(18, 18, 18),
sky_light: PackedNibbleArray(18, 18, 18),

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

    const base_block_pos: Vector3(i32) = .sub(
        .mul(section_pos, .splat(16)),
        .{ .x = 1, .y = 1, .z = 1 },
    );

    const chunk = world.chunks.get(.{ .x = section_pos.x, .z = section_pos.z }).?;
    const section = chunk.sections[@intCast(section_pos.y)].?;
    {
        var i: usize = 0;
        for (1..17) |y| {
            for (1..17) |z| {
                for (1..17) |x| {
                    task.block_states[y][z][x] = section.block_states[i];
                    task.block_light.set(y, z, x, @truncate(section.block_light.bytes[i / 2] >> @as(u3, @intCast((i & 1) * 4))));
                    task.sky_light.set(y, z, x, @truncate(section.sky_light.bytes[i / 2] >> @as(u3, @intCast((i & 1) * 4))));
                    i += 1;
                }
            }
        }
    }
    for (0..18) |y| {
        for (0..18) |z| {
            for (0..18) |x| {
                if (y != 0 and y != 17 and x != 0 and x != 17 and z != 0 and z != 17) continue;
                const block_pos: Vector3(i32) = .add(base_block_pos, .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                task.block_states[y][z][x] = world.getBlockState(block_pos);
                task.block_light.set(y, z, x, world.getBlockLight(block_pos));
                task.sky_light.set(y, z, x, world.getSkyLight(block_pos));
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
                    .west = culling_blocks.contains(task.block_states[y][z][x - 1].block),
                    .east = culling_blocks.contains(task.block_states[y][z][x + 1].block),
                    .down = culling_blocks.contains(task.block_states[y - 1][z][x].block),
                    .up = culling_blocks.contains(task.block_states[y + 1][z][x].block),
                    .north = culling_blocks.contains(task.block_states[y][z - 1][x].block),
                    .south = culling_blocks.contains(task.block_states[y][z + 1][x].block),
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

                    const sky_light = if (face.cullface) |cullface| switch (cullface) {
                        // zig fmt: off
                        .west =>  task.sky_light.get(y,     z,     x - 1),
                        .east =>  task.sky_light.get(y,     z,     x + 1),
                        .down =>  task.sky_light.get(y - 1, z,     x    ),
                        .up =>    task.sky_light.get(y + 1, z,     x    ),
                        .north => task.sky_light.get(y,     z - 1, x    ),
                        .south => task.sky_light.get(y,     z + 1, x    ),
                        // zig fmt: on
                    } else task.sky_light.get(y, z, x);

                    const block_light = if (face.cullface) |cullface| switch (cullface) {
                        // zig fmt: off
                        .west =>  task.block_light.get(y,     z,     x - 1),
                        .east =>  task.block_light.get(y,     z,     x + 1),
                        .down =>  task.block_light.get(y - 1, z,     x    ),
                        .up =>    task.block_light.get(y + 1, z,     x    ),
                        .north => task.block_light.get(y,     z - 1, x    ),
                        .south => task.block_light.get(y,     z + 1, x    ),
                        // zig fmt: on
                    } else task.block_light.get(y, z, x);

                    for (face.pos, face.uv) |vertex_pos, uv| {
                        try staging.writeVertex(
                            .add(pos_vec, vertex_pos),
                            block_light,
                            sky_light,
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
const PackedNibbleArray = @import("util").PackedNibbleArray;

const block_attributes = @import("block_attributes.zig");

const Block = main.Block;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const World = main.World;
const CompilationTracker = render.mesher.CompilationTracker;
const GpuStagingBuffer = render.mesher.GpuStagingBuffer;
