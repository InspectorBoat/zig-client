const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const GameMode = @import("../../../../world/gamemode.zig").GameMode;
const GameProfile = @import("../../../../network/GameProfile.zig");

action: Action,
entries: []const Entry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    const action = try buffer.readEnum(Action) orelse return error.InvalidPlayerInfo;
    const entry_count = try buffer.readVarInt();
    var entries = std.ArrayList(Entry).init(allocator);
    for (0..@intCast(entry_count)) |_| {
        const entry = switch (action) {
            .AddPlayer => Entry{
                .game_profile = GameProfile{
                    .uuid = try buffer.readUuid(),
                    .name = try buffer.readStringAllocating(16, allocator),
                    .properties = get_properties: {
                        var properties = std.StringHashMapUnmanaged(GameProfile.Property){};

                        const property_count = try buffer.readVarInt();
                        for (0..@intCast(property_count)) |_| {
                            const name = try buffer.readStringAllocating(32767, allocator);

                            try properties.put(allocator, name, GameProfile.Property{
                                .name = name,
                                .value = try buffer.readStringAllocating(32767, allocator),
                                .signature = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
                            });
                        }

                        break :get_properties properties;
                    },
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
                .ping = try buffer.readVarInt(),
                .display_name = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
            },
            .UpdateGameMode => Entry{
                .game_profile = GameProfile{
                    .uuid = try buffer.readUuid(),
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
            },
            .UpdatePing => Entry{
                .game_profile = GameProfile{
                    .uuid = try buffer.readUuid(),
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
            },
            .UpdateDisplayName => Entry{
                .game_profile = GameProfile{
                    .uuid = try buffer.readUuid(),
                },
                .display_name = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
            },
            .RemovePlayer => Entry{
                .game_profile = GameProfile{
                    .uuid = try buffer.readUuid(),
                },
            },
        };
        try entries.append(entry);
    }
    return @This(){
        .action = action,
        .entries = try entries.toOwnedSlice(),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(i32) {
    AddPlayer,
    UpdateGameMode,
    UpdatePing,
    UpdateDisplayName,
    RemovePlayer,
};

pub const Entry = struct {
    ping: ?i32 = null,
    game_mode: ?GameMode = null,
    game_profile: ?GameProfile = null,
    display_name: ?[]const u8 = null,
};
