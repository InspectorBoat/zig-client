const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;

slot: i8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .slot = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            if (self.slot >= 0 and self.slot <= 8) {
                ingame.world.player.inventory.hotbar_slot = @intCast(self.slot);
            }
        },
        else => unreachable,
    }
}
