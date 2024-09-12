const root = @import("root");
const std = @import("std");

const Game = root.Client.Game;
const ActiveInputs = Game.ActiveInputs;
const LocalPlayer = root.Entity.LocalPlayer;

// Caller is responsible for making sure we are not already mining a block
pub fn startMiningBlock(game: *Game, player: *LocalPlayer) !void {
    // TODO: Check game mode, world border

    std.debug.assert(player.crosshair == .block);
    std.debug.assert(game.world.mining_state == null);

    if (game.world.getBlock(player.crosshair.block.block_pos) == .air) return;

    try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
    try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
        .action = .start_breaking_block,
        .block_pos = player.crosshair.block.block_pos,
        .face = player.crosshair.block.dir,
    } });
    if (false) { // TODO: This should check for instabreaking
        @panic("TODO");
    }
    game.world.mining_state = .{
        .target_block_pos = player.crosshair.block.block_pos,
        .face = player.crosshair.block.dir,
    };
}

// Caller is responsible for making sure we are mining a block
pub fn stopMiningBlock(game: *Game) !void {
    std.debug.assert(game.world.mining_state != null);
    try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
        .action = .cancel_breaking_block,
        .block_pos = game.world.mining_state.?.target_block_pos,
        .face = game.world.mining_state.?.face,
    } });
    game.world.mining_state = null;
}

pub fn finishMiningBlock(game: *Game) void {
    std.debug.assert(game.world.mining_state != null);
    const mining_state = &game.world.mining_state.?;
    try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
        .action = .finish_breaking_block,
        .block_pos = mining_state.target_block_pos,
        .face = mining_state.face,
    } });
    mining_state.* = null;
}

pub fn updateBlockMining(game: *Game, player: *LocalPlayer) !void {
    // TODO: World border, check game mode
    if (game.world.mining_state) |*mining_state| {
        switch (player.crosshair) {
            .miss, .entity => try stopMiningBlock(game),
            .block => |block| {
                if (block.block_pos.equals(mining_state.target_block_pos)) {
                    mining_state.ticks += 1;
                    if (mining_state.ticks >= 10) { // TODO: Calculate block breaking time
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

pub fn swingHand(game: *Game) !void {
    try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
}

pub fn dropSingleItem(game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        .{ .player_hand_action = .{ .action = .drop_single_item, .block_pos = .origin(), .face = .Down } },
    );
}

pub fn dropEntireStack(game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        .{ .player_hand_action = .{ .action = .drop_entire_stack, .block_pos = .origin(), .face = .Down } },
    );
}

pub fn use(game: *Game, player: *LocalPlayer) !void {
    const interaction_consumed = switch (player.crosshair) {
        .entity => try interactEntityAt(game, player) or try interactEntity(game, player),
        .block => try useBlock(game, player),
        .miss => false,
    };
    if (!interaction_consumed) {
        try useItem(game, player);
    }
}

pub fn useItem(game: *Game, player: *LocalPlayer) !void {
    const held_stack = player.getHeldStack(game) orelse return;
    switch (held_stack.item) {
        .diamond_sword => {
            player.item_in_use = held_stack;
            player.item_use_timer = 72000;
        },
        else => {},
    }
}

/// TODO
pub fn interactEntityAt(game: *Game, player: *LocalPlayer) !bool {
    try game.connection_handle.sendPlayPacket(.{ .player_interact_entity = .{
        .action = .{ .interact_at = player.crosshair.entity.pos },
        .target_network_id = player.crosshair.entity.entity_network_id,
    } });
    return false;
}

/// TODO
pub fn interactEntity(game: *Game, player: *LocalPlayer) !bool {
    try game.connection_handle.sendPlayPacket(.{ .player_interact_entity = .{
        .action = .interact,
        .target_network_id = player.crosshair.entity.entity_network_id,
    } });
    return false;
}

/// Returns whether the interaction was consumed
/// Attempts to either interact with block or place block
pub fn useBlock(game: *Game, player: *LocalPlayer) !bool {
    // TODO: World border, check gamemode
    std.debug.assert(player.crosshair == .block);
    std.debug.assert(game.world.getBlock(player.crosshair.block.block_pos) != .air);

    return false;
}

pub fn stopUsingItem(game: *Game, player: *LocalPlayer) !void {
    try game.connection_handle.sendPlayPacket(
        .{ .player_hand_action = .{ .action = .stop_using_item, .block_pos = .origin(), .face = .Down } },
    );
    player.item_in_use = null;
    player.item_use_timer = 0;
}
