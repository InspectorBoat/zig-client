network_id: i32,
entity_type: i32,
pos: ScaledVector(i32, 32.0),
velocity: ScaledVector(i32, 8000.0),
rotation: ScaledRotation2(i8, 256.0 / 360.0),
head_yaw: ScaledRotation1(i8, 256.0 / 360.0),
datatracker_entries: []const S2C.Play.EntityData.DataTrackerEntry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    const network_id = try buffer.readVarInt();
    const entity_type = try buffer.read(i8);
    const pos: ScaledVector(i32, 32.0) = .{ .raw = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    } };
    const rotation: ScaledRotation2(i8, 256.0 / 360.0) = .{
        .pitch = try buffer.read(i8),
        .yaw = try buffer.read(i8),
    };
    const head_yaw: ScaledRotation1(i8, 256.0 / 360.0) = .{
        .head_yaw = try buffer.read(i8),
    };
    const velocity: ScaledVector(i32, 8000) = .{ .raw = .{
        .x = try buffer.read(i16),
        .y = try buffer.read(i16),
        .z = try buffer.read(i16),
    } };
    const datatracker_entries = undefined;

    return .{
        .network_id = network_id,
        .entity_type = entity_type,
        .pos = pos,
        .rotation = rotation,
        .head_yaw = head_yaw,
        .velocity = velocity,
        .datatracker_entries = datatracker_entries,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    if (self.getEntity()) |entity| {
        _ = try game.world.addEntity(entity);
    }
}

pub fn getEntity(self: *@This()) ?Entity {
    switch (self.entity_type) {
        inline 1, 2, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 30, 40, 41, 42, 43, 44, 45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 120, 200 => |entity_type_int| {
            @setEvalBranchQuota(1000000);
            const entity_type: Entity.Type = @fromBackingInt(entity_type_int);
            const KnownEntity = @FieldType(Entity, @tagName(entity_type));
            if (!@hasField(KnownEntity, "living")) {
                std.debug.panic("Server tried to initialize non-living entity {} with AddMob!\n", .{KnownEntity});
            }
            var known_entity: KnownEntity = .initLiving(self.network_id, self.pos.normalize(), self.rotation.normalize());
            known_entity.base.server_tracked_pos = self.pos;
            return @unionInit(
                Entity,
                @tagName(entity_type),
                known_entity,
            );
        },
        else => std.debug.panic("Unknown entity type id {}", .{self.entity_type}),
    }
    unreachable;
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Entity = main.Entity;
const ScaledRotation1 = main.network.ScaledRotation1;
const ScaledRotation2 = main.network.ScaledRotation2;
const ScaledVector = main.network.ScaledVector;
const S2C = main.network.packet.S2C;
