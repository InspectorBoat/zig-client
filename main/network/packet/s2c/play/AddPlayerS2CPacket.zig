const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const ScaledVector = @import("../../../../network/type/scaled_vector.zig").ScaledVector;
const ScaledRotation = @import("../../../../network/type/scaled_rotation.zig").ScaledRotation;
const Uuid = @import("../../../../entity/Uuid.zig");
const DataTracker = @import("../../../../entity/datatracker/DataTracker.zig");
const EntityDataS2CPacket = @import("EntityDataS2CPacket.zig");

network_id: i32,
uuid: Uuid,
pos: ScaledVector(i32, 32.0),
rotation: ScaledRotation(i8, 256.0 / 360.0),
held_item_id: i32,
datatracker_entries: []const EntityDataS2CPacket.DataTrackerEntry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
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
            try ingame.world.addEntity(.{
                .RemotePlayer = .{
                    .base = .{
                        .network_id = self.network_id,
                        .pos = self.pos.normalize(),
                        .prev_pos = self.pos.normalize(),
                        .rotation = self.rotation.normalize(),
                        .prev_rotation = self.rotation.normalize(),
                    },
                },
            });
        },
        else => unreachable,
    }
    _ = allocator;
}
