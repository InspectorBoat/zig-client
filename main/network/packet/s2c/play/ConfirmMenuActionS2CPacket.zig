const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const ConfirmMenuActionC2SPacket = @import("../../../../network/packet/c2s/play/ConfirmMenuActionC2SPacket.zig");

menu_network_id: u8,
action_id: i16,
accepted: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .menu_network_id = try buffer.read(u8),
        .action_id = try buffer.read(i16),
        .accepted = try buffer.read(bool),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            // simply send the packet back for now, vanilla logic is more complicated
            @import("log").transaction(.{self});
            try ingame.connection_handle.sendPlayPacket(.{ .ConfirmMenuAction = .{
                .accepted = self.accepted,
                .action_id = self.action_id,
                .menu_network_id = @bitCast(self.menu_network_id),
            } });
        },
        else => unreachable,
    }
}
