const std = @import("std");
const Vector3 = @import("../type/vector.zig").Vector3;
const Rotation2 = @import("../type/rotation.zig").Rotation2;
const World = @import("../world/World.zig");
const Direction = @import("../type/direction.zig").Direction;
const Hitbox = @import("./Hitbox.zig");

const HitType = enum { miss, block, entity };

hit_type: HitType,
hit_pos: ?Vector3(f64),
dir: ?Direction,

pub fn rayTrace(world: World, eye_pos: Vector3(f64), rotation: Rotation2(f32), range: f64, comptime options: struct { allow_liquids: bool = false, ignore_blocks_without_collision: bool = false, weird_flag: bool = false }) if (options.weird_flag) ?@This() else @This() {
    var from = eye_pos;
    const to = eye_pos.add(rotationToVec(rotation).scaleUniform(range));

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

    // TODO: fast path: inside block

    for (0..201) |_| {
        if (from.anyNaN() or to.anyNaN()) @panic("NaN");
        if (from.equals(to)) {
            return if (options.weird_flag) null else @This(){
                .hit_type = .miss,
                .hit_pos = null,
                .dir = null,
            };
        }

        // The corresponding coordinate for where we would hit the next grid plane along each axis, ignoring other oxes
        const next_grid_intersection: Vector3(f64) = .{
            .x = if (from_block_pos.x < to_block_pos.x) @floatFromInt(from_block_pos.x + 1) else if (from_block_pos.x > to_block_pos.x) @floatFromInt(from_block_pos.x + 1) else 999,
            .y = if (from_block_pos.y < to_block_pos.y) @floatFromInt(from_block_pos.y + 1) else if (from_block_pos.y > to_block_pos.y) @floatFromInt(from_block_pos.y + 1) else 999,
            .z = if (from_block_pos.z < to_block_pos.z) @floatFromInt(from_block_pos.z + 1) else if (from_block_pos.z > to_block_pos.z) @floatFromInt(from_block_pos.z + 1) else 999,
        };

        const delta = to.sub(from);

        // How far we have to travel along the total ray to reach that grid plane
        var ray_progress: Vector3(f64) = .{
            .x = if (from_block_pos.x != to_block_pos.x) (next_grid_intersection.x - from.x) / delta.x else 999.0,
            .y = if (from_block_pos.y != to_block_pos.y) (next_grid_intersection.y - from.y) / delta.y else 999.0,
            .z = if (from_block_pos.z != to_block_pos.z) (next_grid_intersection.z - from.z) / delta.z else 999.0,
        };

        // Floating point weirdness
        if (ray_progress.x == 0.0) ray_progress.x = -1.0e-4;
        if (ray_progress.y == 0.0) ray_progress.y = -1.0e-4;
        if (ray_progress.z == 0.0) ray_progress.z = -1.0e-4;

        const dir: Direction = blk: {
            if (ray_progress.x < ray_progress.y and ray_progress.x < ray_progress.z) {
                from = .{ .x = next_grid_intersection.x, .y = from.y + delta.y * ray_progress.y, .z = from.z + delta.z * ray_progress.z };
                break :blk if (to_block_pos.x > from_block_pos.x) .West else .East;
            } else if (ray_progress.y < ray_progress.z) {
                from = .{ .x = from.x + delta.x * ray_progress.x, .y = next_grid_intersection.y, .z = from.z + delta.z * ray_progress.z };
                break :blk if (to_block_pos.y > from_block_pos.y) .Down else .Up;
            } else {
                from = .{ .x = from.x + delta.x * ray_progress.x, .y = from.y + delta.y * ray_progress.y, .z = next_grid_intersection.z };
                break :blk if (to_block_pos.z > from_block_pos.z) .North else .South;
            }
        };

        from_block_pos = .{
            .x = floor(from.x) - if (dir == .East) @as(i32, 1) else 0,
            .y = floor(from.y) - if (dir == .Up) @as(i32, 1) else 0,
            .z = floor(from.z) - if (dir == .South) @as(i32, 1) else 0,
        };

        const block = world.getBlock(from_block_pos);
        for (world.getBlockState(from_block_pos).toConcreteBlockState(world, from_block_pos).getRaytraceHitbox()) |hitbox| {
            if (hitbox.min.x == 0 and hitbox.min.y == 0 and hitbox.min.z == 0 and hitbox.max.x == 0 and hitbox.max.y == 0 and hitbox.max.z == 0) continue;
            if (!options.ignore_blocks_without_collision or true) { // TODO: implement block#getCollisionShape
                if (block != .water or options.allow_liquids) { // TODO: implement water level
                    if (rayTraceHitbox(hitbox, from, to)) |hit_result| {
                        return hit_result;
                    }
                }
            }
        }
    }
    return .{ .hit_type = .miss, .hit_pos = null, .dir = null };
}

pub fn rayTraceHitbox(hitbox: Hitbox, from: Vector3(f64), to: Vector3(f64)) ?@This() {
    const maybe_clip_min_x = interpolateToTargetX(from, to, hitbox.min.x);
    const maybe_clip_min_y = interpolateToTargetX(from, to, hitbox.min.y);
    const maybe_clip_min_z = interpolateToTargetX(from, to, hitbox.min.z);

    const maybe_clip_max_x = interpolateToTargetX(from, to, hitbox.max.x);
    const maybe_clip_max_y = interpolateToTargetX(from, to, hitbox.max.y);
    const maybe_clip_max_z = interpolateToTargetX(from, to, hitbox.max.z);

    var hit_pos: ?Vector3(f64) = null;
    var dir: ?Direction = null;
    if (maybe_clip_min_x) |clip_min_x| {
        if (clip_min_x.y >= hitbox.min.y and clip_min_x.y <= hitbox.max.y and clip_min_x.z >= hitbox.min.z and clip_min_x.z <= hitbox.max.z) {
            hit_pos = clip_min_x;
            dir = .West;
        }
    }
    if (maybe_clip_min_y) |clip_min_y| {
        if (clip_min_y.x >= hitbox.min.x and clip_min_y.x <= hitbox.max.x and clip_min_y.z >= hitbox.min.z and clip_min_y.z <= hitbox.max.z) {
            if (hit_pos == null or clip_min_y.distance(from) < hit_pos.?.distance(from)) {
                hit_pos = clip_min_y;
                dir = .Down;
            }
        }
    }
    if (maybe_clip_min_z) |clip_min_z| {
        if (clip_min_z.x >= hitbox.min.x and clip_min_z.x <= hitbox.max.x and clip_min_z.y >= hitbox.min.y and clip_min_z.y <= hitbox.max.y) {
            if (hit_pos == null or clip_min_z.distance(from) < hit_pos.?.distance(from)) {
                hit_pos = clip_min_z;
                dir = .North;
            }
        }
    }
    if (maybe_clip_max_x) |clip_max_x| {
        if (clip_max_x.y >= hitbox.min.y and clip_max_x.y <= hitbox.max.y and clip_max_x.z >= hitbox.min.z and clip_max_x.z <= hitbox.max.z) {
            if (hit_pos == null or clip_max_x.distance(from) < hit_pos.?.distance(from)) {
                hit_pos = clip_max_x;
                dir = .East;
            }
        }
    }
    if (maybe_clip_max_y) |clip_max_y| {
        if (clip_max_y.x >= hitbox.min.x and clip_max_y.x <= hitbox.max.x and clip_max_y.z >= hitbox.min.z and clip_max_y.z <= hitbox.max.z) {
            if (hit_pos == null or clip_max_y.distance(from) < hit_pos.?.distance(from)) {
                hit_pos = clip_max_y;
                dir = .Up;
            }
        }
    }
    if (maybe_clip_max_z) |clip_max_z| {
        if (clip_max_z.x >= hitbox.min.x and clip_max_z.x <= hitbox.max.x and clip_max_z.y >= hitbox.min.y and clip_max_z.y <= hitbox.max.y) {
            if (hit_pos == null or clip_max_z.distance(from) < hit_pos.?.distance(from)) {
                hit_pos = clip_max_z;
                dir = .South;
            }
        }
    }
    return if (hit_pos != null) .{
        .hit_type = .block,
        .dir = dir,
        .hit_pos = hit_pos,
    } else null;
}

pub fn interpolateToTargetX(from: Vector3(f64), to: Vector3(f64), x_plane: f64) ?Vector3(f64) {
    const delta = to.sub(from);
    if (delta.x * delta.x < @as(f32, 0.0000001)) {
        return null;
    } else {
        const ray_progress = (x_plane - from.x) / delta.x;
        if (ray_progress < 0.0 or ray_progress > 1.0) {
            return null;
        }
        return from.add(delta.scaleUniform(ray_progress));
    }
}
pub fn interpolateToTargetY(from: Vector3(f64), to: Vector3(f64), y_plane: f64) ?Vector3(f64) {
    const delta = to.sub(from);
    if (delta.y * delta.y < @as(f32, 0.0000001)) {
        return null;
    } else {
        const ray_progress = (y_plane - from.y) / delta.y;
        if (ray_progress < 0.0 or ray_progress > 1.0) {
            return null;
        }
        return from.add(delta.scaleUniform(ray_progress));
    }
}
pub fn interpolateToTargetZ(from: Vector3(f64), to: Vector3(f64), z_plane: f64) ?Vector3(f64) {
    const delta = to.sub(from);
    if (delta.z * delta.z < @as(f32, 0.0000001)) {
        return null;
    } else {
        const ray_progress = (z_plane - from.z) / delta.z;
        if (ray_progress < 0.0 or ray_progress > 1.0) {
            return null;
        }
        return from.add(delta.scaleUniform(ray_progress));
    }
}

pub fn floor(n: f64) i32 {
    const i: i32 = @intFromFloat(n);
    return if (n < @as(f64, @floatFromInt(i))) i - 1 else i;
}

pub fn rotationToVec(rotation: Rotation2(f32)) Vector3(f64) {
    const x = @sin(-rotation.yaw * (std.math.pi / 180.0) - std.math.pi);
    const z = @cos(-rotation.yaw * (std.math.pi / 180.0) - std.math.pi);
    const y = @sin(-rotation.pitch * (std.math.pi / 180.0));
    const pitch_scalar = -@cos(-rotation.pitch * (std.math.pi / 180.0));
    return .{
        .x = @floatCast(x * pitch_scalar),
        .y = @floatCast(y),
        .z = @floatCast(z * pitch_scalar),
    };
}
