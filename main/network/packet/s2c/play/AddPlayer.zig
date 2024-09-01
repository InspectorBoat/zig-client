const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;
const DataTracker = root.Entity.DataTracker;
const Uuid = @import("util").Uuid;

network_id: i32,
uuid: Uuid,
pos: ScaledVector(i32, 32.0),
rotation: ScaledRotation2(i8, 256.0 / 360.0),
held_item_id: i32,
datatracker_entries: []const S2C.Play.EntityData.DataTrackerEntry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .network_id = try buffer.readVarInt(),
        .uuid = try buffer.readUuid(),
        .pos = .{
            .x = try buffer.read(i32),
            .y = try buffer.read(i32),
            .z = try buffer.read(i32),
        },
        .rotation = .{
            .yaw = try buffer.read(i8),
            .pitch = try buffer.read(i8),
        },
        .held_item_id = try buffer.read(i16),
        .datatracker_entries = &.{}, // TODO
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    // const pos = self.pos.normalize();
    // const rotation = self.rotation.normalize();
    switch (game.*) {
        .Ingame => |*ingame| {
            _ = try ingame.world.addEntity(
                .{
                    .remote_player = .{
                        .base = .{
                            .network_id = self.network_id,
                            .pos = self.pos.normalize(),
                            .prev_pos = self.pos.normalize(),
                            .rotation = self.rotation.normalize(),
                            .prev_rotation = self.rotation.normalize(),
                        },
                    },
                },
            );
        },
        else => unreachable,
    }
    _ = allocator;
}
