const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

network_ids: []const i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const network_ids = try allocator.alloc(i32, @intCast(try buffer.readVarInt()));
    for (network_ids) |*network_id| {
        network_id.* = try buffer.readVarInt();
    }
    return .{
        .network_ids = network_ids,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    for (self.network_ids) |network_id| {
        try game.world.queueEntityRemoval(network_id);
    }
    _ = allocator;
}
