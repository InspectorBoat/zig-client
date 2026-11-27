menu_network_id: i32,
data_id: i32,
value: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .menu_network_id = try buffer.read(u8),
        .data_id = try buffer.read(i16),
        .value = try buffer.read(i16),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = allocator;

    if (game.world.menu == .other and
        game.world.menu.other.network_id == self.menu_network_id and
        self.data_id >= 0 and self.data_id < game.world.menu.other.data.len)
    {
        game.world.menu.other.data[@intCast(self.data_id)] = self.value;
    }
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;
