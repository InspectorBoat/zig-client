const std = @import("std");
const root = @import("root");
const Entity = root.Entity;
const PlayerInventory = @import("../../inventory/PlayerInventory.zig");
const ItemStack = root.ItemStack;
const Client = root.Client;
const Vector2xz = root.Vector2xz;
const Vector3 = root.Vector3;
const World = root.World;
const Rotation2 = root.Rotation2;
const HitResult = root.HitResult;

base: Entity.Base,
living: Entity.LivingBase = .{},
player: Entity.PlayerBase = .{},

abilities: PlayerAbilities = .{},

// TODO: This is not accurate; the vanilla client checks for pointer equality while we check for structural equality
item_in_use: ?ItemStack = null,
item_use_timer: i32 = 0,

air_speed: f32 = 0.02,

remaining_sprint_ticks: i32 = 0,

in_water: bool = false,
in_cobweb: bool = false,

server_movement_status: struct {
    rotation: Rotation2(f32) = .{ .pitch = 0, .yaw = 0 },
    pos: Vector3(f64) = .{ .x = 0, .y = 0, .z = 0 },
    sprinting: bool = false,
    sneaking: bool = false,
    ticks_since_sent_movement: i32 = 0,
} = .{},

crosshair: HitResult = .miss,

sneaking: bool = false,

hotbar_slot: u8 = 0,

pub fn update(self: *@This(), game: *Client.Game) !void {
    self.crosshair = HitResult.rayTraceWorld(game.world, self.getEyePos(), self.base.rotation, 30, .{});

    // tick spectator onground and noclip
    if (self.player.isSpectator(game)) {
        self.base.colliding.on_ground = false;
        self.base.no_clip = true;
    } else {
        self.base.no_clip = false;
    }
    // tick item use
    if (self.item_in_use) |item_in_use| {
        if (!ItemStack.deepEquals(item_in_use, self.getHeldStack(game))) {
            self.item_in_use = null;
        } else {
            self.item_use_timer -= 1;
        }
    }

    // clear vehicle
    if (self.base.vehicle) |vehicle| {
        // TODO: Implement code to access EntityBase fields of any entity without inline switching
        _ = vehicle;
    }

    self.base.tick();

    // tick water collision
    // TODO

    // multiply fall distance by 0.5 in lava
    // TODO

    // remove after 20 ticks dead
    // TODO

    // decrement status effects
    // TODO

    // stop sprinting if sprinting cooldown expired
    if (self.remaining_sprint_ticks > 0) {
        self.remaining_sprint_ticks -= 0;
        if (self.remaining_sprint_ticks == 0) {
            try self.setSprinting(false);
        }
    }

    // close screen if in portal

    // set steer from input
    const inputs = &game.active_inputs;
    var steer = inputs.movement.steer();
    self.sneaking = inputs.movement.sneak;
    // apply slowdown
    if (inputs.movement.sneak) {
        steer.x = @floatCast(@as(f64, steer.x) * 0.3);
        steer.z = @floatCast(@as(f64, steer.z) * 0.3);
    }
    if (self.item_in_use) |_| {
        if (!self.base.hasVehicle()) {
            steer.x *= 0.2;
            steer.z *= 0.2;
        }
    }

    // apply velocity from being in full block
    // self.pushAwayFromFullBlocks(game);

    // update sprinting
    try self.updateSprinting(inputs.*, steer);
    // TODO
    // update flying input
    // TODO

    // update horse jump
    // TODO

    // update peaceful hunger
    // TODO

    // tick interpolation
    // TODO

    // zero velocity if low
    if (@abs(self.base.velocity.x) < 0.005) self.base.velocity.x = 0;
    if (@abs(self.base.velocity.y) < 0.005) self.base.velocity.y = 0;
    if (@abs(self.base.velocity.z) < 0.005) self.base.velocity.z = 0;

    // if dead, stop movement inputs
    // otherwise, if camera, update movement inputs, multiplying steer by 0.98
    if (!self.hasControl()) {
        inputs.movement.back, inputs.movement.forward, inputs.movement.left, inputs.movement.left, inputs.movement.jump = .{ false, false, false, false, false };
        steer = .origin();
    } else {
        steer = steer.scaleUniform(0.98);
    }

    // attempt to jump or float
    if (inputs.movement.jump) {
        if (self.inWater() or self.inLava()) {
            self.base.velocity.y += 0.04;
        } else if (self.base.colliding.on_ground) {
            try self.jump();
        }
    }

    // if flying: weird stuff
    // otherwise: update velocity according to bearing and move
    if (self.abilities.is_flying) {
        const prev_y_velocity = self.base.velocity.y;
        const prev_air_speed = self.air_speed;
        self.air_speed = self.abilities.fly_speed;

        try self.moveWithSteer(steer, game);

        self.base.velocity.y = prev_y_velocity * 0.6;
        self.air_speed = prev_air_speed;
    } else {
        try self.moveWithSteer(steer, game);
    }

    // update air speed according to sprinting status
    self.air_speed = if (try self.base.isSprinting()) 0.025999999 else 0.02;
    // update move speed according to movement speed attribute

    // stop flying if on ground in creative mode and sync abilities
    if (self.abilities.is_flying and self.base.colliding.on_ground and !self.player.isSpectator(game)) {
        self.abilities.is_flying = false;
        self.syncAbilities(game);
    }

    // clamp position to +- 30 million
    const clamped_x = std.math.clamp(self.base.pos.x, -29_999_999, 29_999_999);
    const clamped_z = std.math.clamp(self.base.pos.z, -29_999_999, 29_999_999);
    if (clamped_x != self.base.pos.x or clamped_z != self.base.pos.z) {
        self.base.teleport(.{ .x = self.base.pos.x, .y = self.base.pos.y, .z = self.base.pos.z }, self.base.rotation);
    }
    // send movement packets
    try self.sendMovementPackets(game);
}

pub fn getHeldStack(self: *@This(), game: *Client.Game) ?ItemStack {
    return game.world.player_inventory_menu.stacks[self.hotbar_slot];
}

// TODO: Implement
pub fn inWater(self: *@This()) bool {
    _ = self;
    return false;
}

// TODO: Implement
pub fn inLava(self: *@This()) bool {
    _ = self;
    return false;
}

// TODO: Implement
pub fn hasControl(self: *@This()) bool {
    _ = self;
    return true;
}

pub fn updateSprinting(self: *@This(), inputs: Client.Game.ActiveInputs, steer: Vector2xz(f32)) !void {
    // TODO: Double tap sprint code

    const sufficient_forward_input = steer.z >= @as(f32, @floatCast(0.8));
    const sufficient_food = self.player.hunger.food_level > 6 or self.abilities.allow_flying;
    const not_using_item = self.item_in_use == null;
    const not_blinded = !self.living.hasStatusEffect(.Blindness);
    const sprint_input = inputs.movement.sprint;
    if (sprint_input and
        !try self.base.isSprinting() and
        (sufficient_forward_input) and
        (sufficient_food) and
        (not_using_item) and
        (not_blinded))
    {
        try self.setSprinting(true);
    }

    if (try self.base.isSprinting() and (!sufficient_forward_input or self.base.colliding.horizontal or !sufficient_food)) {
        try self.setSprinting(false);
    }
}

pub fn sendMovementPackets(self: *@This(), game: *Client.Game) !void {
    if (try self.base.isSprinting() != self.server_movement_status.sprinting) {
        try game.connection_handle.sendPlayPacket(.{ .player_movement_action = .{
            .network_id = self.base.network_id,
            .data = 0,
            .action = if (try self.base.isSprinting()) .StartSprinting else .StopSprinting,
        } });
        self.server_movement_status.sprinting = try self.base.isSprinting();
    }
    if (self.isSneaking() != self.server_movement_status.sprinting) {
        try game.connection_handle.sendPlayPacket(.{ .player_movement_action = .{
            .network_id = self.base.network_id,
            .data = 0,
            .action = if (try self.base.isSprinting()) .StartSprinting else .StopSprinting,
        } });
        self.server_movement_status.sneaking = self.isSneaking();
    }

    // if (!self.isCamera()) return;
    const send_movement = self.server_movement_status.ticks_since_sent_movement >= 20 or
        self.server_movement_status.pos.distance_squared(self.base.pos) > 0.0009;
    const send_rotation = self.base.rotation.pitch != self.server_movement_status.rotation.pitch or
        self.base.rotation.yaw != self.server_movement_status.rotation.yaw;

    if (send_movement and send_rotation) {
        try game.connection_handle.sendPlayPacket(.{ .player_move_position_and_angles = .{
            .on_ground = self.base.colliding.on_ground,
            .pos = self.base.pos,
            .rotation = self.base.rotation,
        } });
    } else if (send_movement) {
        try game.connection_handle.sendPlayPacket(.{ .player_move_position = .{
            .on_ground = self.base.colliding.on_ground,
            .pos = self.base.pos,
        } });
    } else if (send_rotation) {
        try game.connection_handle.sendPlayPacket(.{ .player_move_angles = .{
            .on_ground = self.base.colliding.on_ground,
            .rotation = self.base.rotation,
        } });
    } else {
        try game.connection_handle.sendPlayPacket(.{ .player_move = .{
            .on_ground = self.base.colliding.on_ground,
        } });
    }

    if (send_movement) {
        self.server_movement_status.pos = self.base.pos;
        self.server_movement_status.ticks_since_sent_movement = 0;
    } else {
        self.server_movement_status.ticks_since_sent_movement += 1;
    }
    if (send_rotation) {
        self.server_movement_status.rotation = self.base.rotation;
    }
}

pub fn moveWithSteer(self: *@This(), steer: Vector2xz(f32), game: *const Client.Game) !void {
    if (self.inWater() and !self.abilities.is_flying) {
        self.moveWithSteerInWater(steer, game);
    } else if (self.inLava() and !self.abilities.is_flying) {
        self.moveWithSteerInLava(steer, game);
    } else {
        try self.moveWithSteerNonLiquid(steer, game);
    }
}

pub fn moveWithSteerInWater(self: *@This(), steer: Vector2xz(f32), game: *const Client.Game) void {
    _ = self;
    _ = steer;
    _ = game;
}
pub fn moveWithSteerInLava(self: *@This(), steer: Vector2xz(f32), game: *const Client.Game) void {
    _ = self;
    _ = steer;
    _ = game;
}
pub fn moveWithSteerNonLiquid(self: *@This(), steer: Vector2xz(f32), game: *const Client.Game) !void {
    const friction = self.getFrictionNonLiquid(game);
    const traction = try self.getTractionNonLiquid(friction);
    const acceleration = getAccelerationFromSteer(steer, traction, self.base.rotation.yaw);
    self.base.velocity = self.base.velocity.add(.{
        .x = @floatCast(acceleration.x),
        .y = 0,
        .z = @floatCast(acceleration.z),
    });
    // Vanilla redundantly recalculates friction here
    if (self.isClimbing(game)) {
        self.base.velocity.x = std.math.clamp(self.base.velocity.x, -0.15, 0.15);
        self.base.velocity.z = std.math.clamp(self.base.velocity.z, -0.15, 0.15);

        self.base.velocity.y = @max(self.base.velocity.y, if (self.isSneaking()) @as(f64, 0) else @as(f64, -0.15));
    }

    const should_safe_walk = self.base.colliding.on_ground and self.isSneaking();
    try self.base.move(self.base.velocity, should_safe_walk, game);

    if (self.base.colliding.horizontal and self.isClimbing(game)) {
        self.base.velocity.y = 0.2;
    }
    // TODO: Verify correctness
    if (game.world.isChunkLoadedAtBlockPos(.{
        .x = @intFromFloat(self.base.pos.x),
        .y = 0,
        .z = @intFromFloat(self.base.pos.z),
    })) {
        self.base.velocity.y = getGravityNonLiquid(self.base.velocity.y);
    } else {
        self.base.velocity.y = if (self.base.pos.y > 0) -0.098 else 0;
    }

    self.base.velocity.x *= friction;
    self.base.velocity.z *= friction;
}

pub fn getGravityNonLiquid(y_velocity: f64) f64 {
    return (y_velocity - 0.08) * @as(f64, @floatCast(@as(f32, @floatCast(0.98))));
}
pub fn getFrictionNonLiquid(self: *const @This(), game: *const Client.Game) f32 {
    if (self.base.colliding.on_ground) {
        const pos = Vector3(i32){
            .x = @intFromFloat(@floor(self.base.pos.x)),
            .y = @intFromFloat(@floor(self.base.pos.y)),
            .z = @intFromFloat(@floor(self.base.pos.z)),
        };
        const block = game.world.getBlock(pos.down());
        return block.getFriction() * @as(f32, 0.91);
    } else {
        return 0.91;
    }
}
pub fn getTractionNonLiquid(self: *const @This(), friction: f32) !f32 {
    if (self.base.colliding.on_ground) {
        return try self.getGroundWaterSpeed() * (0.16277136 / (friction * friction * friction));
    } else {
        return self.air_speed;
    }
}

pub fn getAccelerationFromSteer(steer: Vector2xz(f32), traction: f32, yaw: f32) Vector2xz(f32) {
    if (steer.magnitude_squared() < 0.0001) return .{ .x = 0, .z = 0 };

    const yaw_radians = yaw * (@as(f32, @floatCast(std.math.pi)) / 180.0);

    const sin = @sin(yaw_radians);
    const cos = @cos(yaw_radians);

    const scaled_steer = steer.scaleUniform(traction / @max(steer.magnitude(), 1.0));

    return .{
        .x = scaled_steer.x * cos - scaled_steer.z * sin,
        .z = scaled_steer.z * cos + scaled_steer.x * sin,
    };
}

pub fn getGroundWaterSpeed(self: *const @This()) !f32 {
    return 0.1 * (if (try self.base.isSprinting()) @as(f32, 1.3) else @as(f32, 1.0));
}

// TODO: Implement
pub fn isClimbing(self: *const @This(), game: *const Client.Game) bool {
    _ = self;
    _ = game;
    return false;
}

pub fn setSprinting(self: *@This(), sprint_state: bool) !void {
    if (sprint_state) @import("log").player_start_sprint(.{}) else @import("log").player_stop_sprint(.{});
    self.remaining_sprint_ticks = if (sprint_state) 600 else 0;
    try self.base.setSprinting(sprint_state);
}

pub fn isSneaking(self: @This()) bool {
    return self.sneaking and !self.player.sleeping;
}

pub fn syncAbilities(self: *@This(), game: *const Client.Game) void {
    _ = self;
    _ = game;
}

pub fn jump(self: *@This()) !void {
    self.base.velocity.y = @as(f32, @floatCast(0.42));
    // TODO: Implement jump boost
    // self.base.velocity.y += @as(f32, @floatFromInt((self.living.getEffectLevel(.JumpBoost) orelse -1) + 1)) * 0.1;

    if (try self.base.isSprinting()) {
        const yaw_radians = self.base.rotation.yaw * @as(f32, @floatCast(@as(f64, std.math.pi) / 180));
        // TODO: Replace this with lookup table version
        self.base.velocity.x -= @sin(yaw_radians) * 0.2;
        self.base.velocity.z += @cos(yaw_radians) * 0.2;
    }
}

pub fn getEyePos(self: @This()) Vector3(f64) {
    return self.base.pos.add(.{ .x = 0, .y = if (self.isSneaking()) 1.54 else 1.62, .z = 0 });
}

pub fn getInterpolatedEyePos(self: @This(), partial_tick: f64, interpolationFn: fn (f64, f64, f64) f64) Vector3(f64) {
    return .{
        .x = interpolationFn(self.base.prev_pos.x, self.base.pos.x, partial_tick),
        .y = interpolationFn(self.base.prev_pos.y, self.base.pos.y, partial_tick) + if (self.isSneaking()) @as(f64, 1.54) else @as(f64, 1.62),
        .z = interpolationFn(self.base.prev_pos.z, self.base.pos.z, partial_tick),
    };
}

pub const PlayerAbilities = struct {
    is_invulnerable: bool = false,
    is_flying: bool = false,
    allow_flying: bool = false,
    creative_mode: bool = false,
    fly_speed: f32 = 0.0,
    walk_speed: f32 = 0.0,
};
