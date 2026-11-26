action: Action,
entries: []const Entry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const action = try buffer.readEnum(Action) orelse return error.InvalidPlayerInfo;
    const entry_count: usize = @intCast(try buffer.readVarInt());
    const entries = try allocator.alloc(Entry, entry_count);
    for (entries) |*entry| {
        entry.* = switch (action) {
            .add_player => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                    .name = try buffer.allocString(allocator, 16),
                    .properties = get_properties: {
                        var properties: std.StringHashMapUnmanaged(GameProfile.Property) = .empty;

                        const property_count: usize = @intCast(try buffer.readVarInt());
                        for (0..property_count) |_| {
                            const name = try buffer.allocString(allocator, 32767);

                            try properties.put(allocator, name, .{
                                .name = name,
                                .value = try buffer.allocString(allocator, 32767),
                                .signature = if (try buffer.read(bool)) try buffer.allocString(allocator, 32767) else null,
                            });
                        }

                        break :get_properties properties;
                    },
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .survival,
                .ping = try buffer.readVarInt(),
                .display_name = if (try buffer.read(bool)) try buffer.allocString(allocator, 32767) else null,
            },
            .update_game_mode => .{
                .game_profile = .{ .uuid = try buffer.readUuid() },
                .game_mode = try buffer.readEnum(GameMode) orelse .survival,
            },
            .update_ping => .{
                .game_profile = .{ .uuid = try buffer.readUuid() },
                .game_mode = try buffer.readEnum(GameMode) orelse .survival,
            },
            .update_display_name => .{
                .game_profile = .{ .uuid = try buffer.readUuid() },
                .display_name = if (try buffer.read(bool)) try buffer.allocString(allocator, 32767) else null,
            },
            .remove_player => .{
                .game_profile = .{ .uuid = try buffer.readUuid() },
            },
        };
    }
    return .{
        .action = action,
        .entries = entries,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(i32) {
    add_player,
    update_game_mode,
    update_ping,
    update_display_name,
    remove_player,
};

pub const Entry = struct {
    ping: ?i32 = null,
    game_mode: ?GameMode = null,
    game_profile: ?GameProfile = null,
    display_name: ?[]const u8 = null,
};

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const GameMode = main.World.GameMode;
const GameProfile = main.network.GameProfile;
const S2C = main.network.packet.S2C;
