id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .id = try buffer.read(u8),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = self;
    // Vanilla's LocalClientPlayerEntity.doCloseMenu clears the cursor before
    // closing; the server drops its own copy when the menu closes.
    Item.Stack.deinit(allocator, &game.world.maybe_cursor_stack);
    game.world.maybe_cursor_stack = null;
    game.world.closeMenu(allocator);
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Item = main.Item;
const S2C = main.network.packet.S2C;
