const std = @import("std");

const main = @import("main");
const Uuid = @import("util").Uuid;

const Client = main.Client;
const ScaledRotation2 = main.network.ScaledRotation2;
const ScaledVector = main.network.ScaledVector;
const S2C = main.network.packet.S2C;

network_id: i32,
uuid: Uuid,
pos: ScaledVector(i32, 32.0),
rotation: ScaledRotation2(i8, 256.0 / 360.0),
held_item_id: i32,
datatracker_entries: []const S2C.Play.EntityData.DataTrackerEntry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return @This(){
        .network_id = try buffer.readVarInt(),
        .uuid = try buffer.readUuid(),
        .pos = .{ .raw = .{
            .x = try buffer.read(i32),
            .y = try buffer.read(i32),
            .z = try buffer.read(i32),
        } },
        .rotation = .{
            .yaw = try buffer.read(i8),
            .pitch = try buffer.read(i8),
        },
        .held_item_id = try buffer.read(i16),
        .datatracker_entries = &.{}, // TODO
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = try game.world.addEntity(
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
    _ = allocator;
}
