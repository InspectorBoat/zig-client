const root = @import("root");
const std = @import("std");

const Game = root.Client.Game;
const Vector3 = root.Vector3;
const Direction = root.Direction;
const ActiveInputs = Game.ActiveInputs;
const LocalPlayer = root.Entity.LocalPlayer;

pub fn updateHotbarSlot(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    _ = io;
    _ = game;
    _ = player;
}

pub fn attack(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.input_manager.hand.attack_cooldown > 0) return;
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
    switch (player.crosshair) {
        .entity => |entity| try attackEntity(io, game, entity.entity_network_id),
        .block => |block| try startMiningBlock(io, game, player, block.block_pos, block.dir),
        .miss => game.input_manager.hand.attack_cooldown = 10,
    }
}

pub fn attackEntity(io: std.Io, game: *Game, entity_network_id: i32) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
        .action = .attack,
        .target_network_id = entity_network_id,
    } });
    // TODO: other clientside effects, like velocity multiply, stop sprinting, etc.
}

pub fn startMiningBlock(io: std.Io, game: *Game, player: *LocalPlayer, block_pos: Vector3(i32), dir: Direction) !void {
    // TODO: Check game mode, world border
    std.debug.assert(player.crosshair == .block);

    if (game.world.getBlock(block_pos) == .air) return;
    // TODO: adventure mode tag overrides
    if (game.world.game_mode.restrictsWorldModification()) return;

    // todo: world border

    // creative instabreak
    if (game.world.game_mode == .Creative) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .start_breaking_block,
            .block_pos = block_pos,
            .face = dir,
        } });
        try instaMineBlock(game, block_pos);
        game.input_manager.hand.mining_cooldown = 5;
        return;
    }

    const already_mining_block = game.world.mining_state != null;
    const mining_same_block = if (game.world.mining_state) |mining_state| mining_state.block_pos.equals(block_pos) else false;

    if (already_mining_block and mining_same_block) return;

    // abort current block
    if (already_mining_block) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .cancel_breaking_block,
            .block_pos = block_pos,
            .face = dir,
        } });
    }

    try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
        .action = .start_breaking_block,
        .block_pos = block_pos,
        .face = dir,
    } });

    const block = game.world.getBlock(block_pos);
    // stuff like eating cake on left click, note blocks, etc.

    if (block.getMiningProgress(player) >= 1.0) {
        try finishMiningBlock(game, block_pos);
    } else game.world.mining_state = .{
        .block_pos = player.crosshair.block.block_pos,
        .face = player.crosshair.block.dir,
    };
}

// TODO: extinguish fire
pub fn instaMineBlock(game: *Game, block_pos: Vector3(i32)) !void {
    try finishMiningBlock(game, block_pos);
}

pub fn stopMiningBlock(io: std.Io, game: *Game) !void {
    if (game.world.mining_state == null) return;
    try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
        .action = .cancel_breaking_block,
        .block_pos = game.world.mining_state.?.block_pos,
        .face = game.world.mining_state.?.face,
    } });
    game.world.mining_state = null;
}

pub fn finishMiningBlock(game: *Game, block_pos: Vector3(i32)) !void {
    if (game.world.game_mode.restrictsWorldModification()) {
        // todo: check for adventure mode block overrides
        return;
    }

    // todo: don't mine blocks in creative with sword

    // optimistic removal
    try game.world.setBlockState(std.mem.Allocator.failing, block_pos, .air_blockstate);
    game.world.mining_state = null;
}

pub fn updateBlockMining(io: std.Io, game: *Game, player: *LocalPlayer, block_pos: Vector3(i32), dir: Direction) !void {
    if (game.input_manager.hand.mining_cooldown > 0) {
        game.input_manager.hand.mining_cooldown -|= 1;
        return;
    }
    if (game.world.game_mode == .Creative) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .start_breaking_block,
            .block_pos = block_pos,
            .face = dir,
        } });
        try instaMineBlock(game, block_pos);
        game.input_manager.hand.mining_cooldown = 5;
        return;
    }
    const mining_state = &(game.world.mining_state orelse return try startMiningBlock(io, game, player, block_pos, dir));
    if (!mining_state.block_pos.equals(block_pos)) return try startMiningBlock(io, game, player, block_pos, dir);

    const block = game.world.getBlock(mining_state.block_pos);
    if (block == .air) {
        game.world.mining_state = null;
        return;
    }
    // update mining progress
    mining_state.progress += block.getMiningProgress(player);
    if (mining_state.progress >= 1) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .finish_breaking_block,
            .block_pos = block_pos,
            .face = dir,
        } });
        try finishMiningBlock(game, block_pos);
        game.world.mining_state = null;
        game.input_manager.hand.mining_cooldown = 5;
    }
}

pub fn swingHand(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
}

pub fn dropSingleItem(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        io,
        .{ .player_hand_action = .{ .action = .drop_single_item, .block_pos = .origin(), .face = .down } },
    );
}

pub fn dropEntireStack(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        io,
        .{ .player_hand_action = .{ .action = .drop_entire_stack, .block_pos = .origin(), .face = .down } },
    );
}

pub fn use(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.world.mining_state != null) return;

    const interaction_consumed = switch (player.crosshair) {
        .entity => try interactEntityAt(io, game, player) or try interactEntity(io, game, player),
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
pub fn interactEntityAt(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
        .action = .{ .interact_at = player.crosshair.entity.pos },
        .target_network_id = player.crosshair.entity.entity_network_id,
    } });
    return false;
}

/// TODO
pub fn interactEntity(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
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

pub fn stopUsingItem(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    try game.connection_handle.sendPlayPacket(
        io,
        .{ .player_hand_action = .{ .action = .stop_using_item, .block_pos = .origin(), .face = .down } },
    );
    player.item_in_use = null;
    player.item_use_timer = 0;
}

pub fn pick(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    _ = io;
    _ = game;
    _ = player;
}
