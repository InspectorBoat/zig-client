const std = @import("std");
const Vector3 = @import("root").Vector3;
const World = @import("root").World;
const ConcreteBlockState = @import("root").ConcreteBlockState;
const GpuStagingBuffer = @import("GpuStagingBuffer.zig");
const CompiledSectionQueue = @import("CompiledSectionQueue.zig");
const Box = @import("root").Box;
const Direction = @import("root").Direction;

section_pos: Vector3(i32),
block_states: [18 * 18 * 18]ConcreteBlockState,
block_light: std.PackedIntArray(u4, 18 * 18 * 18),
sky_light: std.PackedIntArray(u4, 18 * 18 * 18),

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

pub fn compile(task: @This(), compiled_section_queue: *CompiledSectionQueue, allocator: std.mem.Allocator) void {
    const start = std.time.Instant.now() catch unreachable;
    var staging: GpuStagingBuffer = .{ .backer = std.ArrayList(u8).init(allocator) };
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
                            staging.writeBox(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32), @intFromEnum(task.block_states[index].block)) catch |e| std.debug.panic("Compile thread fucked up: {}\n", .{e});
                            continue;
                        }

                        var unculled_faces = std.EnumSet(Direction).initFull();
                        if (task.block_states[index - 1].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.West);
                            }
                        }
                        if (task.block_states[index + 1].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.East);
                            }
                        }
                        if (task.block_states[index - 18 * 18].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.Down);
                            }
                        }
                        if (task.block_states[index + 18 * 18].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.Up);
                            }
                        }
                        if (task.block_states[index - 18].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.North);
                            }
                        }
                        if (task.block_states[index + 18].getRaytraceHitbox()[0]) |other_box| {
                            if (other_box.equals(Box(f64).cube())) {
                                unculled_faces.remove(.South);
                            }
                        }

                        staging.writeBoxFaces(box.min.add(pos_vec).floatCast(f32), box.max.add(pos_vec).floatCast(f32), @intFromEnum(task.block_states[index].block), unculled_faces) catch |e| std.debug.panic("Compile thread fucked up: {}\n", .{e});
                    }
                }
            }
        }
    }

    std.debug.print("compiling section took {} ms\n", .{(std.time.Instant.now() catch unreachable).since(start) / std.time.ns_per_ms});

    compiled_section_queue.add(.{
        .section_pos = task.section_pos,
        .buffer = staging.backer,
    }) catch |e| std.debug.panic("Compile thread fucked up: {}\n", .{e});
}

pub const CompiledSection = struct {
    section_pos: Vector3(i32),
    buffer: std.ArrayList(u8),
};
