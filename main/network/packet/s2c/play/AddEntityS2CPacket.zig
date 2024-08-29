const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const ScaledVector = @import("../../../../network/type/scaled_vector.zig").ScaledVector;
const ScaledRotation = @import("../../../../network/type/scaled_rotation.zig").ScaledRotation;

network_id: i32,
pos: ScaledVector(i32, 32.0),
velocity: ?ScaledVector(i32, 8000.0),
rotation: ScaledRotation(i32, 256.0 / 360.0),
entity_type: i32,
data: i32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const entity_type = try buffer.read(i8);
    const pos: ScaledVector(i32, 32.0) = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    };
    const rotation: ScaledRotation(i32, 256.0 / 360.0) = .{
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
            const Entity = @import("../../../../entity/entity.zig").Entity;

            const pos = self.pos.normalize();

            const entity: Entity = switch (self.entity_type) {
                10 => .{ .Minecart = .{} },
                1 => .{ .Boat = @import("../../../../entity/impl/vehicle/BoatEntity.zig").init(pos) },
                else => return,
            };
            try ingame.world.addEntity(entity);
        },
        else => unreachable,
    }
}
