base: Entity.Base,
in_ground: bool = false,
embedded_block: Block.PhysicalState = .air,
block_pos: ?Vector3(i32) = null,
in_block_ticks: u32 = 0,
in_air_ticks: u32 = 0,
in_water: bool = false,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    var self: @This() = .{ .base = .init(network_id, pos) };
    self.base.setSize(0.5, 0.5);
    self.base.setPosition(pos);
    return self;
}

pub fn tick(self: *@This(), game: *Client.Game) !void {
    self.base.tick();

    self.in_water = Entity.Generic(@This()).isInWater(self.base.hitbox, game);

    if (self.block_pos) |block_pos| {
        const block = game.world.resolveVirtualBlockState(block_pos);
        if (block.block.getMaterial() != .air) {
            var hitboxes_buf: [5]Box(f64) = undefined;
            var hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&hitboxes_buf);

            block.getCollisionHitboxes(&hitboxes);
            for (hitboxes.items) |hitbox| {
                if (hitbox.move(.cast(block_pos)).contains(self.base.pos)) {
                    self.in_ground = true;
                    break;
                }
            }
        }
    }

    if (self.in_ground) {
        if (self.block_pos) |block_pos| {
            const block_state = game.world.getBlockState(block_pos);
            if (@as(u16, @bitCast(block_state)) == @as(u16, @bitCast(self.embedded_block))) {
                self.in_block_ticks +|= 1;
                return;
            }
        }

        self.in_ground = false;
        // deterministic stand-in for vanilla's random.nextFloat() * 0.2 scale
        self.base.velocity = .mul(self.base.velocity, .splat(0.5 * 0.2));
        self.in_block_ticks = 0;
        self.in_air_ticks = 0;
        return;
    }

    self.in_air_ticks +|= 1;

    const hit_result = HitResult.rayTraceBlocks(.{
        .ignore_liquids = true,
        .ignore_blocks_without_collision = true,
    }, &game.world, self.base.pos, .add(self.base.pos, self.base.velocity));

    if (hit_result == .block) {
        const block_pos = hit_result.block.pos;
        self.block_pos = block_pos;
        self.embedded_block = game.world.getBlockState(block_pos);

        const face_pos: Vector3(f64) = .add(.cast(block_pos), hit_result.block.offset);
        self.base.velocity = .sub(face_pos, self.base.pos);

        const distance = self.base.velocity.magnitude();
        if (distance > 0) {
            self.base.setPosition(.sub(self.base.pos, .mul(self.base.velocity, .splat(0.05 / distance))));
        }

        self.in_ground = true;
    }

    const friction: f64 = if (self.in_water) 0.6 else 0.99;
    self.base.setPosition(.add(self.base.pos, self.base.velocity));
    self.base.velocity = .mul(self.base.velocity, .splat(friction));
    self.base.velocity.y -= 0.05;
}

const std = @import("std");

const main = @import("main");

const Block = main.Block;
const Box = main.Box;
const Client = main.Client;
const Entity = main.Entity;
const HitResult = main.HitResult;
const Vector3 = main.Vector3;
