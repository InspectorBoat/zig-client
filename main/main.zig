const std = @import("std");
const network = @import("network");
const Game = @import("common").Game;
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
