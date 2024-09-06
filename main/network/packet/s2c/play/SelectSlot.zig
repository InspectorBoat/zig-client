const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

slot: i8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .slot = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (client.*) {
        .game => |*game| {
            if (self.slot >= 0 and self.slot <= 8) {
                game.world.player.inventory.hotbar_slot = @intCast(self.slot);
            }
        },
        else => unreachable,
    }
}
