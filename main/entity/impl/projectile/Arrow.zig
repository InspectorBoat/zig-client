base: Entity.Base,
block_pos: Vector3(i32) = .splat(-1),

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    var self: @This() = .{ .base = .init(network_id, pos) };
    self.base.setSize(0.5, 0.5);
    return self;
}

pub fn tick(self: *@This(), game: *Client.Game) !void {
    self.base.tick();
    const block = game.world.resolveVirtualBlockState(self.block_pos);
    {
        var hitboxes_buf: [5]Box(f64) = undefined;
        var hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&hitboxes_buf);

        block.getCollisionHitboxes(&hitboxes);
        if (hitboxes.items.len > 0) {
            if (Box(f64).intersects(.move(hitboxes.items[0], .cast(self.block_pos)), self.base.hitbox)) {
                self.base.colliding.on_ground = true;
            }
        }
    }
    const friction: f32 = 0.99;
    const gravity: f32 = 0.05;
    self.base.pos = .add(self.base.pos, self.base.velocity);
    self.base.velocity = .mul(self.base.velocity, .splat(friction));
    self.base.velocity.y -= gravity;
}

const std = @import("std");

const main = @import("main");

const Box = main.Box;
const Client = main.Client;
const Entity = main.Entity;
const Vector3 = main.Vector3;
