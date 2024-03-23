pub const Vector2 = @import("./math/vector.zig").Vector2;
pub const Vector3 = @import("./math/vector.zig").Vector3;
pub const Chunk = @import("./world/Chunk.zig");
pub const Direction = @import("./math/direction.zig").Direction;
pub const Rotation2 = @import("./math/rotation.zig").Rotation2;
pub const Rotation3 = @import("./math/rotation.zig").Rotation3;
pub const Uuid = @import("./entity/Uuid.zig");
pub const Game = @import("./game.zig").Game;
pub const LocalPlayerEntity = @import("./entity/impl/player/LocalPlayerEntity.zig");
pub const Box = @import("./math/box.zig").Box;

const std = @import("std");
const network = @import("network");
const render = @import("render");

pub const opengl_error_handling = .log;

pub fn main() !void {
    std.debug.print("\n---------------------\n", .{});
    try render.onStartup();

    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();

    try network.init();
    defer network.deinit();

    var game: Game = .{ .Idle = .{ .gpa = gpa } };

    var c2s_packet_alloc_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const c2s_packet_alloc = c2s_packet_alloc_impl.allocator();

    try game.initConnection("127.0.0.1", 25565, gpa, c2s_packet_alloc);
    try game.initLoginSequence("foobarqux");

    while (true) {
        if (game == .Ingame) try game.advanceTimer();

        if (game != .Idle) try game.handleIncomingPackets();
        if (game == .Ingame) try game.tickWorld();
        if (game == .Ingame or game == .Connecting) game.checkConnection();

        const should_close = try render.onFrame(&game);
        if (should_close) break;
    }
    if (game == .Ingame or game == .Connecting) {
        game.disconnect();
    }
    std.debug.print("leaks: {}\n", .{gpa_impl.detectLeaks()});
}
