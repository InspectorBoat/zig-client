const std = @import("std");
const Vector3 = @import("root").Vector3;
const World = @import("root").World;
const ConcreteBlockState = @import("root").ConcreteBlockState;
const ConcreteBlock = @import("root").ConcreteBlock;
const GpuStagingBuffer = @import("GpuStagingBuffer.zig");
const CompilationResultQueue = @import("CompilationResultQueue.zig");
const Box = @import("root").Box;
const Direction = @import("root").Direction;
const PackedNibbleArray = @import("util").PackedNibbleArray;

section_pos: Vector3(i32),
block_states: [18 * 18 * 18]ConcreteBlockState,
block_light: PackedNibbleArray(18 * 18 * 18),
sky_light: PackedNibbleArray(18 * 18 * 18),
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
    const task = try allocator.create(@This());
    task.section_pos = section_pos;
    task.revision = revision;
    const base_block_pos = section_pos.scaleUniform(16).sub(.{ .x = 1, .y = 1, .z = 1 });
    for (0..18) |y| {
        for (0..18) |z| {
            for (0..18) |x| {
                const pos = base_block_pos.add(.{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) });
                const index = (y * 18 * 18) + (z * 18) + (x);
                task.block_states[index] = world.getBlockState(pos);
                task.block_light.set(index, world.getBlockLight(pos));
                task.sky_light.set(index, world.getSkyLight(pos));
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

pub fn compile(task: *@This(), allocator: std.mem.Allocator) !CompilationResult.CompiledSection {
    // const start = @import("util").Timer.init();
    // defer std.debug.print("section compiled in {d} ms\n", .{start.ms()});
    var staging: GpuStagingBuffer = .{ .backer = try std.ArrayList(u8).initCapacity(allocator, 4096) };
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

                        const sky_light: std.enums.EnumFieldStruct(Direction, u8, null) = .{
                            .West = task.sky_light.get(index - 1),
                            .East = task.sky_light.get(index + 1),
                            .Down = task.sky_light.get(index - 18 * 18),
                            .Up = task.sky_light.get(index + 18 * 18),
                            .North = task.sky_light.get(index - 18),
                            .South = task.sky_light.get(index + 18),
                        };
                        const block_light: std.enums.EnumFieldStruct(Direction, u8, null) = .{
                            .West = task.block_light.get(index - 1),
                            .East = task.block_light.get(index + 1),
                            .Down = task.block_light.get(index - 18 * 18),
                            .Up = task.block_light.get(index + 18 * 18),
                            .North = task.block_light.get(index - 18),
                            .South = task.block_light.get(index + 18),
                        };

                        if (!box.equals(Box(f64).cube())) {
                            try staging.writeBox(
                                box.min.add(pos_vec).floatCast(f32),
                                box.max.add(pos_vec).floatCast(f32),
                                @intFromEnum(task.block_states[index].block),
                                sky_light,
                                block_light,
                            );
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

                        try staging.writeBoxFaces(
                            box.min.add(pos_vec).floatCast(f32),
                            box.max.add(pos_vec).floatCast(f32),
                            @intFromEnum(task.block_states[index].block),
                            unculled_faces,
                            sky_light,
                            block_light,
                        );
                    }
                }
            }
        }
    }
    // std.debug.print("quads: {}\n", .{staging.backer.items.len / (@bitSizeOf(GpuStagingBuffer.GpuQuad) / 8)});
    return .{
        .buffer = staging.backer,
        .quads = staging.backer.items.len / (@bitSizeOf(GpuStagingBuffer.GpuQuad) / 8),
    };
}
