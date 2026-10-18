const std = @import("std");

const main = @import("main");

const Game = main.Client.Game;
const Direction = main.Direction;
const LocalPlayer = main.Entity.LocalPlayer;
const Vector3 = main.Vector3;

pub fn attack(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.input_manager.hand.attack_cooldown > 0) return;
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
    switch (game.world.crosshair) {
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
    std.debug.assert(game.world.crosshair == .block);

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
        .block_pos = game.world.crosshair.block.block_pos,
        .face = game.world.crosshair.block.dir,
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
    try updateHotbarSlot(io, game, player);

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

    game.input_manager.hand.auto_use_cooldown = 4;

    const interaction_consumed = switch (game.world.crosshair) {
        .entity => try interactEntityAt(io, game, player) or try interactEntity(io, game, player),
        .block => try useBlock(io, game, player),
        .miss => false,
    };

    if (!interaction_consumed) {
        try useItem(io, game, player);
    }
}

pub fn useItem(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.world.game_mode == .Spectator) return;

    try updateHotbarSlot(io, game, player);

    const held_stack = player.getHeldStack(game) orelse return;

    try game.connection_handle.sendPlayPacket(io, .{ .player_use = .{
        .block_pos = .splat(-1),
        .face = null,
        .stack = held_stack,
        .offset = .splat(0.0),
    } });

    switch (held_stack.item) {
        .iron_sword, .wooden_sword, .stone_sword, .golden_sword, .diamond_sword, .bow => {
            player.item_in_use = held_stack;
            player.item_use_timer = 72000;
        },
        .apple, .bread, .porkchop, .cooked_porkchop, .cookie, .melon, .beef, .cooked_beef, .chicken, .cooked_chicken, .rotten_flesh, .spider_eye, .baked_potato, .poisonous_potato, .golden_carrot, .pumpkin_pie, .rabbit, .cooked_rabbit, .mutton, .cooked_mutton, .mushroom_stew, .rabbit_stew, .carrot, .potato, .golden_apple, .potion, .milk_bucket, .fish, .cooked_fish => {
            player.item_in_use = held_stack;
            player.item_use_timer = 32;
        },

        else => {},
    }
}

/// No entities have a client-side interact-at interaction in 1.8.9
pub fn interactEntityAt(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try updateHotbarSlot(io, game, player);

    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
        .action = .{ .interact_at = game.world.crosshair.entity.pos },
        .target_network_id = game.world.crosshair.entity.entity_network_id,
    } });
    return false;
}

/// TODO
pub fn interactEntity(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try updateHotbarSlot(io, game, player);

    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
        .action = .interact,
        .target_network_id = game.world.crosshair.entity.entity_network_id,
    } });
    return false;
}

/// Returns whether the interaction was consumed
/// Attempts to either interact with block or place block
pub fn useBlock(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try updateHotbarSlot(io, game, player);

    // TODO: World border

    const crosshair = game.world.crosshair.block;

    std.debug.assert(game.world.getBlock(crosshair.block_pos) != .air);

    const maybe_held_item_stack = player.getHeldStack(game);

    if (game.world.game_mode == .Spectator) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_use = .{
            .block_pos = crosshair.block_pos,
            .face = crosshair.dir,
            .stack = maybe_held_item_stack,
            .offset = .floatCast(crosshair.pos),
        } });
        return true;
    }

    const block_state = game.world.getBlockState(crosshair.block_pos);

    var consumed: bool = false;

    // if we are *not* sneaking, or our hand is empty, try to interact with the block itself
    if (!player.isSneaking() or maybe_held_item_stack == null) {
        consumed = block_state.use(&game.world, player, crosshair.block_pos, crosshair.dir, crosshair.pos);
    }

    // if we are holding a block item, try to place it directly
    if (!consumed) {
        if (maybe_held_item_stack) |held_item_stack| {
            if (held_item_stack.item.isBlock()) {
                if (held_item_stack.canPlace(&game.world, player, crosshair.block_pos, crosshair.dir)) {
                    return false;
                }
            }
        }
    }

    try game.connection_handle.sendPlayPacket(io, .{ .player_use = .{
        .block_pos = crosshair.block_pos,
        .face = crosshair.dir,
        .stack = maybe_held_item_stack,
        .offset = .floatCast(crosshair.pos),
    } });

    if (consumed) return true;

    if (maybe_held_item_stack) |held_item_stack| {
        return held_item_stack.useOn(&game.world, player, crosshair.block_pos, crosshair.dir, crosshair.pos);
    }
    return false;
}

pub fn stopUsingItem(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
        .action = .stop_using_item,
        .block_pos = .origin(),
        .face = .down,
    } });
    player.item_in_use = null;
    player.item_use_timer = 0;
}

pub fn pick(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    _ = io;
    _ = game;
    _ = player;
}

pub fn updateHotbarSlot(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (player.hotbar_slot != player.server_hotbar_slot) {
        try game.connection_handle.sendPlayPacket(io, .{ .select_slot = .{
            .slot = player.hotbar_slot,
        } });
        player.server_hotbar_slot = player.hotbar_slot;
    }
}
