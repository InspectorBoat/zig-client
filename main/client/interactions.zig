const root = @import("root");
const std = @import("std");

const Game = root.Client.Game;
const ActiveInputs = Game.ActiveInputs;
const LocalPlayer = root.Entity.LocalPlayer;

pub fn startMiningBlock(game: *Game, player: *LocalPlayer) !void {
    std.debug.assert(player.crosshair == .block);
    try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
    try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
        .action = .start_breaking_block,
        .block_pos = player.crosshair.block.block_pos,
        .face = player.crosshair.block.dir,
    } });
    game.world.mining_state = .{
        .target_block_pos = player.crosshair.block.block_pos,
        .face = player.crosshair.block.dir,
    };
}

pub fn stopMiningBlock(game: *Game) !void {
    std.debug.assert(game.world.mining_state != null);
    try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
        .action = .cancel_breaking_block,
        .block_pos = game.world.mining_state.?.target_block_pos,
        .face = game.world.mining_state.?.face,
    } });
    game.world.mining_state = null;
}

pub fn updateMiningBlock(game: *Game, player: *LocalPlayer) !void {
    // TODO: World border, creative/adventure mode
    if (game.world.mining_state) |*mining_state| {
        switch (player.crosshair) {
            .miss, .entity => try stopMiningBlock(game),
            .block => |block| {
                if (block.block_pos.equals(mining_state.target_block_pos)) {
                    mining_state.ticks += 1;
                    if (mining_state.ticks >= 10) { // TODO: Calculate this
                        try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
                            .action = .finish_breaking_block,
                            .block_pos = mining_state.target_block_pos,
                            .face = mining_state.face,
                        } });
                        game.world.mining_state = null;
                    }
                } else {
                    try stopMiningBlock(game);
                    try startMiningBlock(game, player);
                }
            },
        }
    } else {
        switch (player.crosshair) {
            .miss, .entity => {},
            .block => try startMiningBlock(game, player),
        }
    }
}

pub fn attackEntity(game: *Game, entity_network_id: i32) !void {
    try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
    try game.connection_handle.sendPlayPacket(.{ .player_interact_entity = .{
        .action = .attack,
        .target_network_id = entity_network_id,
    } });
}

pub fn punchAir(game: *Game) !void {
    try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
}
