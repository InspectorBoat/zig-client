section_pos: Vector3(i32),
revision: u32,
sections: [3][3][3]?*World.Section,

pub const Error = error{OutOfMemory};

pub const Mesh = struct {
    buffer: std.ArrayList(u8),
};

pub fn getBlockState(self: *const @This(), block_pos: Vector3(i32)) Block.PhysicalState {
    const section_pos: Vector3(u2) = .{
        .x = @intCast((block_pos.x >> 4) + 1),
        .y = @intCast((block_pos.y >> 4) + 1),
        .z = @intCast((block_pos.z >> 4) + 1),
    };
    const section = self.sections[section_pos.y][section_pos.z][section_pos.x] orelse return .air;
    const local_block_pos: Vector3(u16) = .{
        .x = @intCast(block_pos.x & 0xf),
        .y = @intCast(block_pos.y & 0xf),
        .z = @intCast(block_pos.z & 0xf),
    };
    return section.block_states[@intCast(local_block_pos.y << 8 | local_block_pos.z << 4 | local_block_pos.x << 0)];
}
pub fn getBlock(self: *const @This(), block_pos: anytype) Block {
    return self.getBlockState(block_pos).block;
}

pub fn getLight(self: *const @This(), block_pos: Vector3(i32)) World.Light {
    const section_pos: Vector3(u2) = .{
        .x = @intCast((block_pos.x >> 4) + 1),
        .y = @intCast((block_pos.y >> 4) + 1),
        .z = @intCast((block_pos.z >> 4) + 1),
    };
    const section = self.sections[section_pos.y][section_pos.z][section_pos.x] orelse return .{ .block = 0, .sky = 0 };
    const local_block_pos: Vector3(u16) = .{
        .x = @intCast(block_pos.x & 0xf),
        .y = @intCast(block_pos.y & 0xf),
        .z = @intCast(block_pos.z & 0xf),
    };
    return section.light[local_block_pos.y][local_block_pos.z][local_block_pos.x];
}

pub fn init(world: *const World, section_pos: Vector3(i32), revision: u32) !@This() {
    var sections: [3][3][3]?*World.Section = @splat(@splat(@splat(null)));

    for (0..3) |dy| {
        for (0..3) |dz| {
            for (0..3) |dx| {
                const neighbor_pos: Vector3(i32) = .{
                    .x = section_pos.x + @as(i32, @intCast(dx)) - 1,
                    .y = section_pos.y + @as(i32, @intCast(dy)) - 1,
                    .z = section_pos.z + @as(i32, @intCast(dz)) - 1,
                };
                sections[dy][dz][dx] =
                    if (neighbor_pos.y < 0 or neighbor_pos.y > 15)
                        null
                    else if (world.chunks.get(.{ .x = neighbor_pos.x, .z = neighbor_pos.z })) |neighbor_chunk|
                        if (neighbor_chunk.sections[@intCast(neighbor_pos.y)]) |section| section.borrow() else null
                    else
                        null;
            }
        }
    }

    return .{ .sections = sections, .revision = revision, .section_pos = section_pos };
}

pub fn deinit(self: @This(), gpa: std.mem.Allocator) void {
    for (self.sections) |y| for (y) |z| for (z) |maybe_section| if (maybe_section) |section| section.release(gpa);
}

pub fn compile(task: @This(), gpa: std.mem.Allocator) Error!Mesh {
    @setRuntimeSafety(false);

    var staging: GpuStagingBuffer = try .initCapacity(gpa, 4096);
    errdefer staging.deinit();

    var cull_table: [16][16][16]CullMask = undefined;
    const culling_blocks = block_attributes.culls_adjacent_faces;
    for (0..16) |y| {
        for (0..16) |z| {
            for (0..16) |x| {
                const block_pos: Vector3(i32) = .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) };

                cull_table[y][z][x] = .{
                    // zig fmt: off
                    .west  = culling_blocks.contains(task.getBlock(block_pos.west())),
                    .east  = culling_blocks.contains(task.getBlock(block_pos.east())),
                    .down  = culling_blocks.contains(task.getBlock(block_pos.down())),
                    .up    = culling_blocks.contains(task.getBlock(block_pos.up())),
                    .north = culling_blocks.contains(task.getBlock(block_pos.north())),
                    .south = culling_blocks.contains(task.getBlock(block_pos.south())),
                    // zig fmt: on
                };
            }
        }
    }

    for (0..16) |y| {
        for (0..16) |z| {
            for (0..16) |x| {
                const cull = cull_table[y][z][x];
                if (cull == CullMask.all) continue;

                const block_pos: Vector3(i32) = .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) };

                const block_state: Block.VirtualState = .resolve(task.getBlockState(block_pos), task, block_pos);
                const model = render.renderer.blockstate_to_model_lookup.get(block_state) orelse continue;

                for (render.renderer.faces[model.idx..][0..model.len]) |face| {
                    if (face.cullface) |cullface| if (cull.get(cullface)) continue;

                    const light: World.Light = if (face.cullface) |cullface|
                        task.getLight(block_pos.dir(cullface))
                    else
                        .{ .block = 15, .sky = 15 };

                    for (face.pos, face.uv) |vertex_pos, uv| {
                        try staging.writeVertex(
                            .add(.floatFromInt(block_pos), vertex_pos),
                            light.block,
                            light.sky,
                            face.texture,
                            uv,
                            face.cullface,
                        );
                    }
                }
            }
        }
    }
    return .{
        .buffer = staging.backer,
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
const Vector2xz = main.Vector2xz;
const Vector3 = main.Vector3;
const World = main.World;
const CompilationTracker = render.mesher.CompilationTracker;
const GpuStagingBuffer = render.mesher.GpuStagingBuffer;
