const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
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

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (client.*) {
        .game => |*game| {
            const pos = self.pos.normalize();
            _ = pos;

            if (self.getEntity(game)) |entity| {
                _ = try game.world.addEntity(entity);
            }
        },
        else => unreachable,
    }
}

pub fn getEntity(self: *@This(), game: *Client.Game) ?Entity {
    const world = &game.world;
    switch (self.entity_type) {
        10 => return .{ .minecart = .init(self.network_id, self.pos.normalize()) },
        90 => if (world.getEntityByNetworkId(self.data)) |referenced_entity| {
            if (referenced_entity.* == .local_player or referenced_entity.* == .remote_player) {
                return .{ .fishing_bobber = .init(self.network_id, self.pos.normalize()) };
            }
        },
        60 => return .{ .arrow = .init(self.network_id, self.pos.normalize()) },
        61 => return .{ .snowball = .init(self.network_id, self.pos.normalize()) },
        71 => {
            self.data = 0;
            return .{ .item_frame = .init(self.network_id, self.pos.normalize()) };
        },
        77 => {
            self.data = 0;
            return .{ .lead_knot = .init(self.network_id, self.pos.normalize()) };
        },
        65 => return .{ .ender_pearl = .init(self.network_id, self.pos.normalize()) },
        72 => return .{ .ender_eye = .init(self.network_id, self.pos.normalize()) },
        76 => return .{ .fireworks = .init(self.network_id, self.pos.normalize()) },
        63 => {
            self.data = 0;
            return .{ .fireball = .init(self.network_id, self.pos.normalize()) };
        },
        64 => {
            self.data = 0;
            return .{ .small_fireball = .init(self.network_id, self.pos.normalize()) };
        },
        66 => {
            self.data = 0;
            return .{ .wither_skull = .init(self.network_id, self.pos.normalize()) };
        },
        62 => return .{ .egg = .init(self.network_id, self.pos.normalize()) },
        73 => {
            self.data = 0;
            return .{ .potion = .init(self.network_id, self.pos.normalize()) };
        },
        75 => {
            self.data = 0;
            return .{ .experience_bottle = .init(self.network_id, self.pos.normalize()) };
        },
        1 => return .{ .boat = .init(self.network_id, self.pos.normalize()) },
        50 => return .{ .primed_tnt = .init(self.network_id, self.pos.normalize()) },
        78 => return .{ .armor_stand = .init(self.network_id, self.pos.normalize()) },
        51 => return .{ .ender_crystal = .init(self.network_id, self.pos.normalize()) },
        2 => return .{ .item = .init(self.network_id, self.pos.normalize()) },
        70 => {
            self.data = 0;
            return .{ .falling_block = .init(self.network_id, self.pos.normalize()) };
        },
        else => return null,
    }
    return null;
}
