const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

menu_network_id: u8,
action_id: i16,
accepted: bool,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .menu_network_id = try buffer.read(u8),
        .action_id = try buffer.read(i16),
        .accepted = try buffer.read(bool),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = allocator;
    // simply send the packet back for now, vanilla logic is more complicated
    std.log.scoped(.transaction).debug("transaction - {any}", .{self});
    try game.connection_handle.sendPlayPacket(io, .{ .confirm_menu_action = .{
        .accepted = self.accepted,
        .action_id = self.action_id,
        .menu_network_id = @bitCast(self.menu_network_id),
    } });
}
