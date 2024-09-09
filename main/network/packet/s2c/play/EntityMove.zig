const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;

network_id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .network_id = try buffer.readVarInt(),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
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

    pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        return .{
            .network_id = try buffer.readVarInt(),
            .delta_pos = .{
                .x = try buffer.read(i8),
                .y = try buffer.read(i8),
                .z = try buffer.read(i8),
            },
            .on_ground = try buffer.read(bool),
        };
    }

    pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        entity.move(self.delta_pos.normalize());
        _ = allocator;
    }
};

pub const Angles = struct {
    network_id: i32,
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

    comptime handle_on_network_thread: bool = false,
    comptime required_client_state: Client.State = .game,

    pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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

    pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        entity.rotateTo(self.rotation.normalize());
        _ = allocator;
    }
};

pub const PositionAndAngles = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

    comptime handle_on_network_thread: bool = false,
    comptime required_client_state: Client.State = .game,

    pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        return .{
            .network_id = try buffer.readVarInt(),
            .delta_pos = .{
                .x = try buffer.read(i8),
                .y = try buffer.read(i8),
                .z = try buffer.read(i8),
            },
            .rotation = .{
                .yaw = try buffer.read(i8),
                .pitch = try buffer.read(i8),
            },
            .on_ground = try buffer.read(bool),
        };
    }

    pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
        const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
        entity.move(self.delta_pos.normalize());
        entity.rotateTo(self.rotation.normalize());
        _ = allocator;
    }
};
