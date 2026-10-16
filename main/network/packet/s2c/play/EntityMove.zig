const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

const ScaledVector = main.network.ScaledVector;
const ScaledRotation2 = main.network.ScaledRotation2;

network_id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .network_id = try buffer.readVarInt(),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Position = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    on_ground: bool,

    comptime handle_on_network_thread: bool = false,
    comptime required_client_state: Client.State = .game,

    pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
        _ = allocator;

        return .{
            .network_id = try buffer.readVarInt(),
            .delta_pos = .{ .raw = .{
                .x = try buffer.read(i8),
                .y = try buffer.read(i8),
                .z = try buffer.read(i8),
            } },
            .on_ground = try buffer.read(bool),
        };
    }

    pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
        _ = io;

        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        switch (entity.*) {
            .removed => {},
            inline else => |*specific_entity| {
                specific_entity.base.server_tracked_pos = .{
                    .raw = .add(
                        specific_entity.base.server_tracked_pos.raw,
                        .cast(self.delta_pos.raw),
                    ),
                };
                try entity.interpolateOrSnap(allocator, specific_entity.base.server_tracked_pos.normalize(), specific_entity.base.rotation, 3, &game.world);
            },
        }
    }
};

pub const Angles = struct {
    network_id: i32,
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

    comptime handle_on_network_thread: bool = false,
    comptime required_client_state: Client.State = .game,

    pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
        _ = allocator;

        return .{
            .network_id = try buffer.readVarInt(),
            .rotation = .{
                .yaw = try buffer.read(i8),
                .pitch = try buffer.read(i8),
            },
            .on_ground = try buffer.read(bool),
        };
    }

    pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
        _ = io;

        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        switch (entity.*) {
            .removed => {},
            inline else => |*specific_entity| {
                try entity.interpolateOrSnap(allocator, specific_entity.base.server_tracked_pos.normalize(), specific_entity.base.rotation, 3, &game.world);
            },
        }
    }
};

pub const PositionAndAngles = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

    comptime handle_on_network_thread: bool = false,
    comptime required_client_state: Client.State = .game,

    pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
        _ = allocator;

        return .{
            .network_id = try buffer.readVarInt(),
            .delta_pos = .{ .raw = .{
                .x = try buffer.read(i8),
                .y = try buffer.read(i8),
                .z = try buffer.read(i8),
            } },
            .rotation = .{
                .yaw = try buffer.read(i8),
                .pitch = try buffer.read(i8),
            },
            .on_ground = try buffer.read(bool),
        };
    }

    pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
        _ = io;

        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        switch (entity.*) {
            .removed => {},
            inline else => |*specific_entity| {
                specific_entity.base.server_tracked_pos = .{
                    .raw = .add(
                        specific_entity.base.server_tracked_pos.raw,
                        .cast(self.delta_pos.raw),
                    ),
                };
                try entity.interpolateOrSnap(allocator, specific_entity.base.server_tracked_pos.normalize(), self.rotation.normalize(), 3, &game.world);
            },
        }
    }
};
