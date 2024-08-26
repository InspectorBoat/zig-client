const std = @import("std");
const Vector3 = @import("root").Vector3;
const World = @import("root").World;
const ConcreteBlockState = @import("root").ConcreteBlockState;
const ConcreteBlock = @import("root").ConcreteBlock;
const GpuStagingBuffer = @import("GpuStagingBuffer.zig");
const CompilationResultQueue = @import("CompilationResultQueue.zig");
const Box = @import("root").Box;
const Direction = @import("root").Direction;

section_pos: Vector3(i32),
block_states: [18 * 18 * 18]ConcreteBlockState,
block_light: std.PackedIntArray(u4, 18 * 18 * 18),
sky_light: std.PackedIntArray(u4, 18 * 18 * 18),

pub const CompilationResult = struct {
    section_pos: Vector3(i32),
    result: union(enum) {
        Complete: CompiledSection,
        Error: error{OutOfMemory},
    },

    pub const CompiledSection = struct {
        quads: usize,
        buffer: std.ArrayList(u8),
    };
};

pub fn create(section_pos: Vector3(i32), world: *World) @This() {
    var compile_task: @This() = .{
        .section_pos = section_pos,
        .block_states = undefined,
        .block_light = undefined,
        .sky_light = undefined,
    };
    const base_block_pos = section_pos.scaleUniform(16).sub(.{ .x = 1, .y = 1, .z = 1 });
    for (0..18) |y| {
        for (0..18) |z| {
            for (0..18) |x| {
                const pos = base_block_pos.add(.{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                const index = (y * 18 * 18) + (z * 18) + (x);
                compile_task.block_states[index] = world.getBlockState(pos);
                // compile_task.block_light[index] = world.getBlockLight(pos);
                // compile_task.sky_light[index] = world.getSkyLight(pos);
            }
        }
    }
    return compile_task;
}

pub fn runTask(task: @This(), result_queue: *CompilationResultQueue, allocator: std.mem.Allocator) void {
    result_queue.add(.{
        .section_pos = task.section_pos,
        .result = if (compile(task, allocator)) |compiled_section|
            .{ .Complete = compiled_section }
        else |e|
            .{ .Error = e },
    }) catch std.debug.panic("TODO!", .{});
}

pub fn compile(task: @This(), allocator: std.mem.Allocator) !CompilationResult.CompiledSection {
    var staging: GpuStagingBuffer = .{ .backer = std.ArrayList(u8).initCapacity(allocator, 4096) catch |e| std.debug.panic("Compile thread fucked up: {}\n", .{e}) };
    // place blocks in chunk
    for (1..17) |x| {
        for (1..17) |y| {
            for (1..17) |z| {
                const index = (y * 18 * 18) + (z * 18) + (x);
                // TODO: Change this
                for (task.block_states[index].getRaytraceHitbox()) |maybe_box| {
                    if (maybe_box) |box| {
                        const pos_vec: Vector3(f64) = .{
                            .x = @floatFromInt(x - 1),
                            .y = @floatFromInt(y - 1),
                            .z = @floatFromInt(z - 1),
                        };

                        if (!box.equals(Box(f64).cube())) {
                            try staging.writeBox(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32), @intFromEnum(task.block_states[index].block));
                            continue;
                        }

                        const culling_blocks = @import("face_culling_blocks.zig").@"export";
                        var unculled_faces = std.EnumSet(Direction).initFull();
                        if (culling_blocks.get(task.block_states[index - 1].block)) {
                            unculled_faces.remove(.West);
                        }
                        if (culling_blocks.get(task.block_states[index + 1].block)) {
                            unculled_faces.remove(.East);
                        }
                        if (culling_blocks.get(task.block_states[index - 18 * 18].block)) {
                            unculled_faces.remove(.Down);
                        }
                        if (culling_blocks.get(task.block_states[index + 18 * 18].block)) {
                            unculled_faces.remove(.Up);
                        }
                        if (culling_blocks.get(task.block_states[index - 18].block)) {
                            unculled_faces.remove(.North);
                        }
                        if (culling_blocks.get(task.block_states[index + 18].block)) {
                            unculled_faces.remove(.South);
                        }

                        try staging.writeBoxFaces(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32), @intFromEnum(task.block_states[index].block), unculled_faces);
                    }
                }
            }
        }
    }

    return .{
        .buffer = staging.backer,
        .quads = staging.backer.items.len / (@bitSizeOf(GpuStagingBuffer.GpuQuad) / 8),
    };
}
