const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;
const Entity = root.Entity;

network_id: i32,
pos: ScaledVector(i32, 32.0),
velocity: ?ScaledVector(i32, 8000.0),
rotation: ScaledRotation2(i32, 256.0 / 360.0),
entity_type: i32,
data: i32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const entity_type = try buffer.read(i8);
    const pos: ScaledVector(i32, 32.0) = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    };
    const rotation: ScaledRotation2(i32, 256.0 / 360.0) = .{
        .pitch = try buffer.read(i8),
        .yaw = try buffer.read(i8),
    };
    const data = try buffer.read(i32);
    const velocity: ?ScaledVector(i32, 8000) = if (data > 0) .{
        .x = try buffer.read(i16),
        .y = try buffer.read(i16),
        .z = try buffer.read(i16),
    } else null;

    return .{
        .network_id = network_id,
        .pos = pos,
        .velocity = velocity,
        .rotation = rotation,
        .entity_type = entity_type,
        .data = data,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            const pos = self.pos.normalize();
            _ = pos;

            if (self.getEntity(ingame)) |entity| {
                try ingame.world.addEntity(entity, self.network_id);
            }
        },
        else => unreachable,
    }
}

pub fn getEntity(self: *@This(), ingame: *Game.IngameGame) ?Entity {
    const world = &ingame.world;
    switch (self.entity_type) {
        10 => return .{ .minecart = .{} },
        90 => if (world.getEntityByNetworkId(self.data)) |referenced_entity| {
            if (referenced_entity.* == .local_player or referenced_entity.* == .remote_player) {
                return .{ .fishing_bobber = .{} };
            }
        },
        60 => return .{ .arrow = .{} },
        61 => return .{ .snowball = .{} },
        71 => {
            self.data = 0;
            return .{ .item_frame = .{} };
        },
        77 => {
            self.data = 0;
            return .{ .lead_knot = .{} };
        },
        65 => return .{ .ender_pearl = .{} },
        72 => return .{ .ender_eye = .{} },
        76 => return .{ .fireworks = .{} },
        63 => {
            self.data = 0;
            return .{ .fireball = .{} };
        },
        64 => {
            self.data = 0;
            return .{ .small_fireball = .{} };
        },
        66 => {
            self.data = 0;
            return .{ .wither_skull = .{} };
        },
        62 => return .{ .egg = .{} },
        73 => {
            self.data = 0;
            return .{ .potion = .{} };
        },
        75 => {
            self.data = 0;
            return .{ .experience_bottle = .{} };
        },
        1 => return .{ .boat = Entity.Boat.init(self.pos.normalize()) },
        50 => return .{ .primed_tnt = .{} },
        78 => return .{ .armor_stand = .{} },
        51 => return .{ .ender_crystal = .{} },
        2 => return .{ .item = .{} },
        70 => {
            self.data = 0;
            return .{ .falling_block = .{} };
        },
        else => return null,
    }
    unreachable;
}
