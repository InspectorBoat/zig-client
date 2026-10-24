slot: i8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .slot = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = allocator;

    if (self.slot >= 0 and self.slot <= 8) {
        game.world.player.hotbar_slot = @intCast(self.slot);
        std.log.scoped(.hotbar).debug("switched hotbar slot to {}", .{self.slot});
    }
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;
