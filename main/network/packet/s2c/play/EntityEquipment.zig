const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
const ItemStack = root.ItemStack;

network_id: i32,
equipment_slot: i32,
stack: ?ItemStack,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .network_id = try buffer.readVarInt(),
        .equipment_slot = try buffer.read(i16),
        .stack = try buffer.readItemStackAllocating(allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = client;
    _ = self;
}
