const std = @import("std");

const main = @import("main");

const Client = main.Client;
const ScaledVector = main.network.ScaledVector;
const S2C = main.network.packet.S2C;

network_id: i32,
velocity: ScaledVector(i32, 8000.0),

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
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

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = allocator;

    if (self.network_id == game.world.player.base.network_id) {
        game.world.player.base.velocity = self.velocity.normalize();
        return;
    }

    const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
    entity.setVelocityFromPacket(self.velocity.normalize());
}
