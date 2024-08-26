pub const Vector2 = @import("math/vector.zig").Vector2;
pub const Vector3 = @import("math/vector.zig").Vector3;
pub const Chunk = @import("world/Chunk.zig");
pub const Direction = @import("math/direction.zig").Direction;
pub const Rotation2 = @import("math/rotation.zig").Rotation2;
pub const Rotation3 = @import("math/rotation.zig").Rotation3;
pub const Uuid = @import("entity/Uuid.zig");
pub const Game = @import("game.zig").Game;
pub const World = @import("world/World.zig");
pub const LocalPlayerEntity = @import("entity/impl/player/LocalPlayerEntity.zig");
pub const Box = @import("math/box.zig").Box;
pub const ConcreteBlockState = @import("block/block.zig").ConcreteBlockState;
pub const ConcreteBlock = @import("block/block.zig").ConcreteBlock;
pub const EnumBoolArray = @import("util").EnumBoolArray;

const std = @import("std");
const network = @import("network");
const render = @import("render");

pub const opengl_error_handling = .assert;

pub fn main() !void {
    std.debug.print("\n---------------------\n", .{});

    try EventHandler.dispatch(Events.Startup, .{});

    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();

    try network.init();
    defer network.deinit();

    var game: Game = .{ .Idle = .{ .gpa = gpa } };

    var c2s_packet_alloc_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const c2s_packet_alloc = c2s_packet_alloc_impl.allocator();

    try game.initConnection("127.0.0.1", 25565, gpa, c2s_packet_alloc);
    try game.initLoginSequence("baz");

    while (true) {
        if (game == .Ingame) try game.advanceTimer();

        if (game != .Idle) try game.handleIncomingPackets();
        if (game == .Ingame) try game.tickWorld();
        if (game == .Ingame or game == .Connecting) game.checkConnection();

        try EventHandler.dispatch(Events.Frame, .{ .game = &game });
        if (done) break;
    }

    if (game == .Ingame or game == .Connecting) {
        game.disconnect();
    }
    std.debug.print("leaks: {}\n", .{gpa_impl.detectLeaks()});
}

var done = false;
pub fn exit(_: Events.Exit) void {
    done = true;
}

pub const Events = struct {
    pub const Startup = struct {};
    pub const ChunkUpdate = struct { chunk_pos: Vector2(i32), chunk: *Chunk, world: *World };
    pub const UnloadChunk = struct { chunk_pos: Vector2(i32) };
    pub const Frame = struct { game: *Game };
    pub const Exit = struct {};
};

pub const EventHandler = struct {
    pub const listeners = .{exit} ++ @import("render").event_listeners;

    pub const dispatch = @import("util").events.getDispatcher(Events, listeners).dispatch;
};

test {
    _ = @import("world/ChunkMap.zig");
    _ = @import("block/metadata_conversion_table.zig");
}
