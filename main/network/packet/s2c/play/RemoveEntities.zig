const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

network_ids: []const i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const network_ids = try allocator.alloc(i32, @intCast(try buffer.readVarInt()));
    for (network_ids) |*network_id| {
        network_id.* = try buffer.readVarInt();
    }
    return .{
        .network_ids = network_ids,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    for (self.network_ids) |network_id| {
        try game.world.queueEntityRemoval(network_id);
    }
    _ = allocator;
}
