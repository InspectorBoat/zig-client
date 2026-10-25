network_id: i32,
entries: []const Entry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const network_id = try buffer.readVarInt();
    const entry_count = try buffer.read(i32);

    const entries = try allocator.alloc(Entry, @intCast(entry_count));
    for (entries) |*entry| {
        const id = try buffer.readStringAllocating(allocator, 64);
        const base_value = try buffer.read(f64);

        const modifier_count: usize = @intCast(try buffer.readVarInt());

        const modifiers = try allocator.alloc(Modifier, modifier_count);
        for (modifiers) |*modifier| {
            const uuid = try buffer.readUuid();
            const value = try buffer.read(f64);
            const operation = try buffer.read(i8);
            modifier.* = .{ .uuid = uuid, .value = value, .operation = operation };
        }

        entry.* = .{
            .id = id,
            .base_value = base_value,
            .modifiers = modifiers,
        };
    }

    return .{
        .network_id = network_id,
        .entries = entries,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Entry = struct {
    id: []const u8,
    base_value: f64,
    modifiers: []const Modifier,
};

pub const Modifier = struct {
    uuid: Uuid,
    value: f64,
    operation: i8,
};

const std = @import("std");

const main = @import("main");
const Uuid = @import("util").Uuid;

const Client = main.Client;
const S2C = main.network.packet.S2C;
