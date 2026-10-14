const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const ScaledVector = root.network.ScaledVector;

network_id: i32,
velocity: ScaledVector(i32, 8000.0),

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const velocity: ScaledVector(i32, 8000.0) = .{ .raw = .{
        .x = try buffer.read(i16),
        .y = try buffer.read(i16),
        .z = try buffer.read(i16),
    } };

    return .{
        .network_id = network_id,
        .velocity = velocity,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
    entity.setVelocityFromPacket(self.velocity.normalize());
    _ = allocator;
}
