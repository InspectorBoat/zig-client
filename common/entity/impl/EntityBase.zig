const Entity = @import("../../entity/entity.zig").Entity;
const Game = @import("../../game.zig").Game;
const Hitbox = @import("../../math/Hitbox.zig");
const Vector3 = @import("../../type/vector.zig").Vector3;
const Rotation2 = @import("../../type/rotation.zig").Rotation2;
const DataTracker = @import("../../entity/datatracker/DataTracker.zig");
const std = @import("std");

/// This struct supplies fields that every entity needs
network_id: i32,
pos: Vector3(f64) = Vector3(f64).origin(),
prev_pos: Vector3(f64) = Vector3(f64).origin(),
rotation: Rotation2(f32) = Rotation2(f32).origin(),
prev_rotation: Rotation2(f32) = Rotation2(f32).origin(),
velocity: Vector3(f64) = Vector3(f64).origin(),
colliding: struct {
    horizontal: bool = false,
    vertical: bool = false,
    in_cobweb: bool = false,
    on_ground: bool = false,
} = .{},
fall_distance: f32 = 0,
no_clip: bool = false,
hitbox: Hitbox = .{ .min = .{ .x = 0, .y = 0, .z = 0 }, .max = .{ .x = 1, .y = 1, .z = 1 } },

vehicle: ?*Entity = null,

data_tracker: DataTracker = .{},

width: f32 = 0.6,
height: f32 = 1.8,

ticks_existed: u64 = 0,

pub fn tick(self: *@This()) void {
    // TODO: This is not vanilla, it should incremet at the beginning
    self.ticks_existed += 1;
    self.prev_pos = self.pos;
    self.prev_rotation = self.rotation;
}

pub fn teleport(self: *@This(), new_pos: Vector3(f64), new_rotation: Rotation2(f32)) void {
    self.prev_pos = new_pos;
    self.pos = new_pos;
    self.prev_rotation = new_rotation;
    self.rotation = new_rotation;

    self.setPosition(self.pos);
    self.setRotation(self.rotation);
}

pub fn move(self: *@This(), velocity: Vector3(f64), game: *const Game.IngameState) !void {
    // TODO: handle noclip
    const start_pos = self.pos;
    _ = start_pos;
    // handle cobweb
    const initial_velocity = if (self.colliding.in_cobweb)
        velocity.scale(.{ .x = 0.25, .y = 0.05, .z = 0.25 })
    else
        velocity;
    if (self.colliding.in_cobweb) self.velocity = .{ .x = 0, .y = 0, .z = 0 };
    var actual_movement = initial_velocity;

    // TODO: handle sneak

    const initial_hitbox = self.hitbox;
    _ = initial_hitbox;
    // handle collisions
    const possible_collisions: []const Hitbox = try game.world.getCollisions(self.hitbox.grow(initial_velocity), game.gpa);
    defer game.gpa.free(possible_collisions);
    // move and collide on the y axis
    for (possible_collisions) |blocking_hitbox| {
        actual_movement.y = blocking_hitbox.blockYAxisMovingHitbox(self.hitbox, actual_movement.y);
    }
    self.hitbox = self.hitbox.move(.{ .x = 0, .y = actual_movement.y, .z = 0 });

    // move and collide on the x axis
    for (possible_collisions) |blocking_hitbox| {
        actual_movement.x = blocking_hitbox.blockXAxisMovingHitbox(self.hitbox, actual_movement.x);
    }
    self.hitbox = self.hitbox.move(.{ .x = actual_movement.x, .y = 0, .z = 0 });

    // move and collide on the z axis
    for (possible_collisions) |blocking_hitbox| {
        actual_movement.z = blocking_hitbox.blockZAxisMovingHitbox(self.hitbox, actual_movement.z);
    }
    self.hitbox = self.hitbox.move(.{ .x = 0, .y = 0, .z = actual_movement.z });

    // step up blocks
    // to step, we must have been on the ground in the previous tick, or on the ground in this new tick
    if (self.getStepHeight() > 0.0 and
        (self.colliding.on_ground or (initial_velocity.y != actual_movement.y and initial_velocity.y < 0)) and
        (initial_velocity.x != actual_movement.x or initial_velocity.z != actual_movement.z))
    {}

    // set position from hitbox
    self.pos = getPositionFromHitbox(self.hitbox);

    self.colliding.horizontal = initial_velocity.x != actual_movement.x or initial_velocity.z != actual_movement.z;
    self.colliding.vertical = initial_velocity.y != actual_movement.y;
    self.colliding.on_ground = self.colliding.vertical and initial_velocity.y < 0;

    // get block below, accounting for 1.5 tall blocks
    self.fall(self.colliding.on_ground, actual_movement.y);

    if (initial_velocity.x != actual_movement.x) self.velocity.x = 0;
    if (initial_velocity.z != actual_movement.z) self.velocity.z = 0;

    if (initial_velocity.y != actual_movement.y) self.velocity.y = 0; // block.applyFallReaction - slime block bounce code is here
}

// TODO: Implement
pub fn getStepHeight(self: *@This()) f32 {
    _ = self;
    return 0.6;
}

pub fn fall(self: *@This(), on_ground: bool, distance: f64) void {
    if (on_ground) {
        self.fall_distance = 0;
    } else {
        self.fall_distance -= @floatCast(distance);
    }
}

pub fn getPositionFromHitbox(hitbox: Hitbox) Vector3(f64) {
    return .{
        .x = (hitbox.min.x + hitbox.max.x) / 2,
        .y = hitbox.min.y,
        .z = (hitbox.min.z + hitbox.max.z) / 2,
    };
}

pub fn getBlockPos(self: *const @This()) Vector3(i32) {
    _ = self;
    // TODO
    return undefined;
}

/// Sets `self.pos` and adjusts `self.hitbox` to match
pub fn setPosition(self: *@This(), pos: Vector3(f64)) void {
    self.pos = pos;
    self.hitbox = .{
        .min = .{
            .x = pos.x - @as(f64, self.width / 2.0),
            .y = pos.y,
            .z = pos.z - @as(f64, self.width / 2.0),
        },
        .max = .{
            .x = pos.x + @as(f64, self.width / 2.0),
            .y = pos.y + @as(f64, self.height),
            .z = pos.z + @as(f64, self.width / 2.0),
        },
    };
}

/// Sets `self.rotation` to rotation modulo 360
pub fn setRotation(self: *@This(), rotation: Rotation2(f32)) void {
    self.rotation = Rotation2(f32){
        .pitch = @rem(rotation.pitch, 360.0),
        .yaw = @rem(rotation.yaw, 360.0),
    };
}

pub fn hasVehicle(self: @This()) bool {
    return self.vehicle != null;
}

// TODO: Unimplemented
pub fn isSneaking(self: @This()) bool {
    _ = self;
    return false;
}

/// TODO: Unimplemented
pub fn setSneaking(self: *@This(), sneaking_state: bool) void {
    _ = self;
    _ = sneaking_state;
}

pub fn isSprinting(self: @This()) !bool {
    return try self.getFlag(3);
}

pub fn setSprinting(self: *@This(), sprinting_state: bool) !void {
    try self.setFlag(3, sprinting_state);
}

pub fn getFlag(self: @This(), index: u3) !bool {
    const entry_zero = switch (self.data_tracker.entries[0] orelse return error.MissingEntry) {
        .i8 => |i| i,
        else => return error.WrongEntryType,
    };
    return (entry_zero & (@as(i8, 1) << index)) != 0;
}

pub fn setFlag(self: *@This(), index: u3, value: bool) !void {
    const entry_zero = switch (self.data_tracker.entries[0] orelse return error.MissingEntry) {
        .i8 => |i| i,
        else => return error.WrongEntryType,
    };

    if (value) {
        try self.data_tracker.update(0, .{ .i8 = entry_zero | (@as(i8, 1) << index) });
    } else {
        try self.data_tracker.update(0, .{ .i8 = entry_zero & ~(@as(i8, 1) << index) });
    }
}
