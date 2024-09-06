const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const C2S = root.network.packet.C2S;
const Client = root.Client;

menu_network_id: u8,
action_id: i16,
accepted: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .menu_network_id = try buffer.read(u8),
        .action_id = try buffer.read(i16),
        .accepted = try buffer.read(bool),
    };
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (client.*) {
        .game => |*game| {
            // simply send the packet back for now, vanilla logic is more complicated
            @import("log").transaction(.{self});
            try game.connection_handle.sendPlayPacket(.{ .confirm_menu_action = .{
                .accepted = self.accepted,
                .action_id = self.action_id,
                .menu_network_id = @bitCast(self.menu_network_id),
            } });
        },
        else => unreachable,
    }
}
