const std = @import("std");
const Vector3 = @import("root").Vector3;
const World = @import("root").World;
const GpuStagingBuffer = @import("GpuStagingBuffer.zig");
const CompilationResultQueue = @import("CompilationResultQueue.zig");
const Box = @import("root").Box;
const Direction = @import("root").Direction;
const PhysicalState = @import("root").Block.PhysicalState;
const VirtualState = @import("root").Block.VirtualState;
const PackedNibbleArray = @import("util").PackedNibbleArray;

section_pos: Vector3(i32),
block_states: [18][18][18]VirtualState,
block_light: PackedNibbleArray(18, 18, 18),
sky_light: PackedNibbleArray(18, 18, 18),
revision: u32,

pub const CompilationResult = struct {
    section_pos: Vector3(i32),
    revision: u32,
    result: union(enum) {
        Success: CompiledSection,
        Error: error{OutOfMemory},
    },

    pub const CompiledSection = struct {
        quads: usize,
        buffer: std.ArrayList(u8),
    };
};

pub fn create(section_pos: Vector3(i32), world: *const World, revision: u32, allocator: std.mem.Allocator) !*@This() {
    @setRuntimeSafety(false);

    const task = try allocator.create(@This());
    task.section_pos = section_pos;
    task.revision = revision;
    const base_block_pos: Vector3(i32) = .sub(
        .mul(section_pos, .splat(16)),
        .{ .x = 1, .y = 1, .z = 1 },
    );
    for (0..18) |y| {
        for (0..18) |z| {
            for (0..18) |x| {
                const block_pos: Vector3(i32) = .add(base_block_pos, .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                task.block_states[x][y][z] = .resolve(world.getBlockState(block_pos), world, block_pos);
                task.block_light.set(x, y, z, world.getBlockLight(block_pos));
                task.sky_light.set(x, y, z, world.getSkyLight(block_pos));
            }
        }
    }
    return task;
}

pub fn runTask(task: *@This(), result_queue: *CompilationResultQueue, allocator: std.mem.Allocator) void {
    defer allocator.destroy(task);
    result_queue.add(.{
        .section_pos = task.section_pos,
        .revision = task.revision,
        .result = if (compile(task, allocator)) |compiled_section|
            .{ .Success = compiled_section }
        else |e|
            .{ .Error = e },
    }) catch std.debug.panic("TODO!", .{});
}

const Renderer = @import("../Renderer.zig");

pub fn compile(task: *@This(), allocator: std.mem.Allocator) !CompilationResult.CompiledSection {
    @setRuntimeSafety(false);

    // const start: @import("llm-code-quarantine").Timer = .init();
    // defer std.debug.print("section compiled in {d} ms\n", .{start.ms()});
    var total: usize = 0;
    var staging: GpuStagingBuffer = try .initCapacity(allocator, 4096);
    // place blocks in chunk
    for (1..17) |x| {
        for (1..17) |y| {
            for (1..17) |z| {
                const model = @import("../render.zig").renderer.lookup_table.get(task.block_states[x][y][z]) orelse continue;

                for (model.faces) |face| {
                    const pos_vec: Vector3(f32) = .{
                        .x = @floatFromInt(x - 1),
                        .y = @floatFromInt(y - 1),
                        .z = @floatFromInt(z - 1),
                    };

                    const sky_light = if (face.cullface) |cullface| switch (cullface) {
                        .west => task.sky_light.get(x - 1, y, z),
                        .east => task.sky_light.get(x + 1, y, z),
                        .down => task.sky_light.get(x, y - 1, z),
                        .up => task.sky_light.get(x, y + 1, z),
                        .north => task.sky_light.get(x, y, z - 1),
                        .south => task.sky_light.get(x, y, z + 1),
                    } else task.sky_light.get(x, y, z);

                    const block_light = if (face.cullface) |cullface| switch (cullface) {
                        .west => task.block_light.get(x - 1, y, z),
                        .east => task.block_light.get(x + 1, y, z),
                        .down => task.block_light.get(x, y - 1, z),
                        .up => task.block_light.get(x, y + 1, z),
                        .north => task.block_light.get(x, y, z - 1),
                        .south => task.block_light.get(x, y, z + 1),
                    } else task.block_light.get(x, y, z);

                    if (face.cullface) |cullface| {
                        const culling_blocks = @import("face_culling_blocks.zig").@"export";
                        switch (cullface) {
                            .west => if (culling_blocks.get(task.block_states[x - 1][y][z])) continue,
                            .east => if (culling_blocks.get(task.block_states[x + 1][y][z])) continue,
                            .down => if (culling_blocks.get(task.block_states[x][y - 1][z])) continue,
                            .up => if (culling_blocks.get(task.block_states[x][y + 1][z])) continue,
                            .north => if (culling_blocks.get(task.block_states[x][y][z - 1])) continue,
                            .south => if (culling_blocks.get(task.block_states[x][y][z + 1])) continue,
                        }
                    }

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
                    total += 1;
                }
            }
        }
    }
    return .{
        .buffer = staging.backer,
        .quads = total,
    };
}
