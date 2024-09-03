const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ItemStack = root.ItemStack;

menu_network_id: i32,
stacks: []const ?ItemStack,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const menu_network_id = try buffer.read(u8);
    const stack_count: usize = @intCast(try buffer.read(i16));
    const stacks = try allocator.alloc(?ItemStack, stack_count);
    for (stacks) |*stack| {
        stack.* = try buffer.readItemStackAllocating(allocator);
    }
    return .{
        .menu_network_id = menu_network_id,
        .stacks = stacks,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
