base: Entity.Base,

pub fn init(network_id: i32, server_pos: ScaledVector3(i32, 32.0), server_velocity: ScaledVector3(i32, 8000.0)) @This() {
    return .{
        .base = .{
            .network_id = network_id,
            .pos = server_pos.normalize(),
            .server_tracked_pos = server_pos,
            .velocity = server_velocity.normalize(),
            .width = 0.25,
            .height = 0.25,
            .hitbox = .feetAt(server_pos.normalize(), 0.25, 0.25),
        },
    };
}

pub fn tick(self: *@This(), game: *const Client.Game) !void {
    // TODO: Remove if item null
    self.base.tick();
    self.base.velocity.y -= @as(f32, 0.04);
    // TODO: pushAwayFrom
    try self.base.move(game, self.base.velocity, false);
    const pos: Vector3(i32) = .{
        .x = @intFromFloat(@floor(self.base.pos.x)),
        .y = @intFromFloat(@floor(self.base.pos.y - 1)),
        .z = @intFromFloat(@floor(self.base.pos.z)),
    };
    const friction = if (self.base.colliding.on_ground)
        game.world.getBlock(pos).getFriction() * 0.98
    else
        0.98;
    self.base.velocity = .mul(self.base.velocity, .{ .x = friction, .y = 0.98, .z = friction });
    if (self.base.colliding.on_ground) self.base.velocity.y *= -0.5;
    // TODO: check water
}

pub fn getItem(self: *@This()) ?Item.Stack {
    return (self.base.data_tracker.entries[10] orelse return null).Item.Stack;
}

const main = @import("main");

const Client = main.Client;
const Entity = main.Entity;
const Item = main.Item;
const Vector3 = main.Vector3;
const ScaledVector3 = main.network.ScaledVector;
