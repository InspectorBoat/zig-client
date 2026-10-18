const std = @import("std");

const main = @import("main");

const Box = main.Box;
const Direction = main.Direction;
const MathHelper = main.MathHelper;
const Rotation2 = main.Rotation2;
const Vector3 = main.Vector3;
const World = main.World;

pub const HitType = enum { block, entity, miss };

pub const HitResult = union(HitType) {
    block: struct {
        block_pos: Vector3(i32),
        /// in local space already
        pos: Vector3(f64),
        dir: Direction,
    },
    entity: struct {
        entity_network_id: i32,
        pos: Vector3(f64),
        dir: Direction,
    },
    miss,

    const RayTraceOptions = struct {
        ignore_liquids: bool = true,
        ignore_blocks_without_collision: bool = false,
    };

    pub fn rayTraceBlocks(
        comptime options: RayTraceOptions,
        world: *const World,
        origin: Vector3(f64),
        rotation: Rotation2(f32),
        range: f64,
    ) @This() {
        var from = origin;
        const to: Vector3(f64) = .add(origin, .mul(rotationToVec(rotation), .splat(range)));

        if (from.anyNaN() or to.anyNaN()) @panic("NaN");

        var from_block_pos: Vector3(i32) = .{
            .x = floor(from.x),
            .y = floor(from.y),
            .z = floor(from.z),
        };
        const to_block_pos: Vector3(i32) = .{
            .x = floor(to.x),
            .y = floor(to.y),
            .z = floor(to.z),
        };

        for (0..10) |_| {
            if (from.anyNaN() or to.anyNaN()) @panic("NaN");

            if (from_block_pos.equals(to_block_pos)) {
                return .miss;
            }

            const next_grid_pos: Vector3(f64) = .{
                .x = if (from_block_pos.x < to_block_pos.x)
                    @as(f64, @floatFromInt(from_block_pos.x)) + 1.0
                else if (from_block_pos.x > to_block_pos.x)
                    @floatFromInt(from_block_pos.x)
                else
                    999.0,

                .y = if (from_block_pos.y < to_block_pos.y)
                    @as(f64, @floatFromInt(from_block_pos.y)) + 1.0
                else if (from_block_pos.y > to_block_pos.y)
                    @floatFromInt(from_block_pos.y)
                else
                    999.0,

                .z = if (from_block_pos.z < to_block_pos.z)
                    @as(f64, @floatFromInt(from_block_pos.z)) + 1.0
                else if (from_block_pos.z > to_block_pos.z)
                    @floatFromInt(from_block_pos.z)
                else
                    999.0,
            };

            const delta: Vector3(f64) = .sub(to, from);

            var ray_progress: Vector3(f64) = .{
                .x = if (from_block_pos.x != to_block_pos.x) (next_grid_pos.x - from.x) / delta.x else 999.0,
                .y = if (from_block_pos.y != to_block_pos.y) (next_grid_pos.y - from.y) / delta.y else 999.0,
                .z = if (from_block_pos.z != to_block_pos.z) (next_grid_pos.z - from.z) / delta.z else 999.0,
            };

            if (ray_progress.x == -0.0) ray_progress.x = -1.0E-4;
            if (ray_progress.y == -0.0) ray_progress.y = -1.0E-4;
            if (ray_progress.z == -0.0) ray_progress.z = -1.0E-4;

            const dir: Direction = blk: {
                if (ray_progress.x < ray_progress.y and ray_progress.x < ray_progress.z)
                    break :blk if (to_block_pos.x > from_block_pos.x) .west else .east
                else if (ray_progress.y < ray_progress.z)
                    break :blk if (to_block_pos.y > from_block_pos.y) .down else .up
                else
                    break :blk if (to_block_pos.z > from_block_pos.z) .north else .south;
            };

            from = switch (dir) {
                .west, .east => .{ .x = next_grid_pos.x, .y = from.y + delta.y * ray_progress.x, .z = from.z + delta.z * ray_progress.x },
                .down, .up => .{ .x = from.x + delta.x * ray_progress.y, .y = next_grid_pos.y, .z = from.z + delta.z * ray_progress.y },
                .north, .south => .{ .x = from.x + delta.x * ray_progress.z, .y = from.y + delta.y * ray_progress.z, .z = next_grid_pos.z },
            };

            from_block_pos = .{
                .x = floor(from.x) - if (dir == .east) @as(i32, 1) else 0,
                .y = floor(from.y) - if (dir == .up) @as(i32, 1) else 0,
                .z = floor(from.z) - if (dir == .south) @as(i32, 1) else 0,
            };

            const block = world.resolveVirtualBlockState(from_block_pos);

            var local_hitboxes_buffer: [5]Box(f64) = undefined;
            var local_hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&local_hitboxes_buffer);

            block.getRaytraceHitboxes(&local_hitboxes);

            for (local_hitboxes.items) |hitbox| {
                if (Vector3(f64).equals(hitbox.min, .origin()) and Vector3(f64).equals(hitbox.max, .origin())) continue;

                if (options.ignore_blocks_without_collision and false) continue; // TODO: implement block#getCollisionShape
                if (options.ignore_liquids and block == .water) continue; // TODO: implement water level

                const hit_result = rayTraceHitbox(
                    hitbox,
                    .sub(from, .{
                        .x = from_block_pos.x,
                        .y = from_block_pos.y,
                        .z = from_block_pos.z,
                    }),
                    .sub(to, .{
                        .x = from_block_pos.x,
                        .y = from_block_pos.y,
                        .z = from_block_pos.z,
                    }),
                );
                if (hit_result == .block) {
                    return .{
                        .block = .{
                            .block_pos = from_block_pos,
                            .dir = hit_result.block.dir,
                            .pos = hit_result.block.pos,
                        },
                    };
                }
            }
        }

        return .miss;
    }

    pub fn rayTraceEntities(
        world: *const World,
        origin: Vector3(f64),
        rotation: Rotation2(f32),
        range: f64,
    ) @This() {
        const to: Vector3(f64) = .add(origin, .mul(rotationToVec(rotation), .splat(range)));
        var closest_hit_distance: f64 = std.math.inf(f64);
        var hit_result: @This() = .miss;

        var iter = world.entity_tracker.entities_by_network_id.iterator();
        while (iter.next()) |entry| {
            const entity = entry.value_ptr.*;
            const entity_network_id = entry.key_ptr.*;

            const hitbox: Box(f64) = switch (entity.*) {
                .removed => continue,
                inline else => |specific_entity| blk: {
                    const pos: Vector3(f64) = specific_entity.base.pos;
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
                    break :blk .{ .min = min, .max = max };
                },
            };

            switch (rayTraceHitbox(hitbox, origin, to)) {
                .block => |hit| {
                    const dist = hit.pos.distanceSquared(origin);
                    if (dist < closest_hit_distance) {
                        closest_hit_distance = dist;
                        hit_result = .{ .entity = .{
                            .entity_network_id = entity_network_id,
                            .pos = hit.pos,
                            .dir = hit.dir,
                        } };
                    }
                },
                else => {},
            }
        }
        return hit_result;
    }

    pub fn rayTraceWorld(
        comptime options: RayTraceOptions,
        world: *const World,
        origin: Vector3(f64),
        rotation: Rotation2(f32),
        range: f64,
    ) @This() {
        const block_hit_result = rayTraceBlocks(options, world, origin, rotation, range);
        const entity_hit_result = rayTraceEntities(world, origin, rotation, range);
        const block_hit_distance = switch (block_hit_result) {
            .block => |hit| hit.pos.distanceSquared(origin),
            else => std.math.inf(f64),
        };
        const entity_hit_distance = switch (entity_hit_result) {
            .entity => |hit| hit.pos.distanceSquared(origin),
            else => std.math.inf(f64),
        };
        return if (block_hit_distance < entity_hit_distance) block_hit_result else entity_hit_result;
    }

    fn between(min: anytype, mid: anytype, max: anytype) bool {
        return mid >= min and mid <= max;
    }

    pub fn rayTraceHitbox(hitbox: Box(f64), from: Vector3(f64), to: Vector3(f64)) @This() {
        const maybe_clip_min_x = interpolateToTargetX(from, to, hitbox.min.x);
        const maybe_clip_min_y = interpolateToTargetY(from, to, hitbox.min.y);
        const maybe_clip_min_z = interpolateToTargetZ(from, to, hitbox.min.z);

        const maybe_clip_max_x = interpolateToTargetX(from, to, hitbox.max.x);
        const maybe_clip_max_y = interpolateToTargetY(from, to, hitbox.max.y);
        const maybe_clip_max_z = interpolateToTargetZ(from, to, hitbox.max.z);

        var hit_pos: ?Vector3(f64) = null;
        var dir: ?Direction = null;
        if (maybe_clip_min_x) |clip_min_x| {
            if (between(hitbox.min.y, clip_min_x.y, hitbox.max.y) and between(hitbox.min.z, clip_min_x.z, hitbox.max.z)) {
                hit_pos = clip_min_x;
                dir = .west;
            }
        }
        if (maybe_clip_min_y) |clip_min_y| {
            if (between(hitbox.min.x, clip_min_y.x, hitbox.max.x) and between(hitbox.min.z, clip_min_y.z, hitbox.max.z)) {
                if (hit_pos == null or clip_min_y.distance(from) < hit_pos.?.distance(from)) {
                    hit_pos = clip_min_y;
                    dir = .down;
                }
            }
        }
        if (maybe_clip_min_z) |clip_min_z| {
            if (between(hitbox.min.x, clip_min_z.x, hitbox.max.x) and between(hitbox.min.y, clip_min_z.y, hitbox.max.y)) {
                if (hit_pos == null or clip_min_z.distance(from) < hit_pos.?.distance(from)) {
                    hit_pos = clip_min_z;
                    dir = .north;
                }
            }
        }
        if (maybe_clip_max_x) |clip_max_x| {
            if (between(hitbox.min.y, clip_max_x.y, hitbox.max.y) and between(hitbox.min.z, clip_max_x.z, hitbox.max.z)) {
                if (hit_pos == null or clip_max_x.distance(from) < hit_pos.?.distance(from)) {
                    hit_pos = clip_max_x;
                    dir = .east;
                }
            }
        }
        if (maybe_clip_max_y) |clip_max_y| {
            if (between(hitbox.min.x, clip_max_y.x, hitbox.max.x) and between(hitbox.min.z, clip_max_y.z, hitbox.max.z)) {
                if (hit_pos == null or clip_max_y.distance(from) < hit_pos.?.distance(from)) {
                    hit_pos = clip_max_y;
                    dir = .up;
                }
            }
        }
        if (maybe_clip_max_z) |clip_max_z| {
            if (between(hitbox.min.x, clip_max_z.x, hitbox.max.x) and between(hitbox.min.y, clip_max_z.y, hitbox.max.y)) {
                if (hit_pos == null or clip_max_z.distance(from) < hit_pos.?.distance(from)) {
                    hit_pos = clip_max_z;
                    dir = .south;
                }
            }
        }
        return if (hit_pos != null) .{
            .block = .{
                .block_pos = undefined,
                .dir = dir.?,
                .pos = hit_pos.?,
            },
        } else .miss;
    }

    pub fn interpolateToTargetX(from: Vector3(f64), to: Vector3(f64), x_plane: f64) ?Vector3(f64) {
        const delta: Vector3(f64) = .sub(to, from);

        if (delta.x * delta.x < @as(f32, 0.0000001)) return null;

        const ray_progress = (x_plane - from.x) / delta.x;
        if (ray_progress < 0.0 or ray_progress > 1.0) {
            return null;
        }
        return .add(from, .mul(delta, .splat(ray_progress)));
    }
    pub fn interpolateToTargetY(from: Vector3(f64), to: Vector3(f64), y_plane: f64) ?Vector3(f64) {
        const delta: Vector3(f64) = .sub(to, from);
        if (delta.y * delta.y < @as(f32, 0.0000001)) {
            return null;
        } else {
            const ray_progress = (y_plane - from.y) / delta.y;
            if (ray_progress < 0.0 or ray_progress > 1.0) {
                return null;
            }
            return .add(from, .mul(delta, .splat(ray_progress)));
        }
    }
    pub fn interpolateToTargetZ(from: Vector3(f64), to: Vector3(f64), z_plane: f64) ?Vector3(f64) {
        const delta: Vector3(f64) = .sub(to, from);
        if (delta.z * delta.z < @as(f32, 0.0000001)) {
            return null;
        } else {
            const ray_progress = (z_plane - from.z) / delta.z;
            if (ray_progress < 0.0 or ray_progress > 1.0) {
                return null;
            }
            return .add(from, .mul(delta, .splat(ray_progress)));
        }
    }

    pub fn floor(n: f64) i32 {
        const i: i32 = @intFromFloat(n);
        return if (n < @as(f64, @floatFromInt(i))) i - 1 else i;
    }

    pub fn rotationToVec(rotation: Rotation2(f32)) Vector3(f64) {
        const x = MathHelper.sin(-rotation.yaw * @as(f32, @floatCast(std.math.pi / 180.0)) - @as(f32, std.math.pi));
        const z = MathHelper.cos(-rotation.yaw * @as(f32, @floatCast(std.math.pi / 180.0)) - @as(f32, std.math.pi));
        const y = MathHelper.sin(-rotation.pitch * @as(f32, @floatCast(std.math.pi / 180.0)));
        const pitch_scalar = -MathHelper.cos(-rotation.pitch * @as(f32, @floatCast(std.math.pi / 180.0)));
        return .{
            .x = @floatCast(x * pitch_scalar),
            .y = @floatCast(y),
            .z = @floatCast(z * pitch_scalar),
        };
    }
};
