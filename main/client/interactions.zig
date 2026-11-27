pub fn attack(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.input_manager.cooldown.attack > 0) return;
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
    switch (game.world.crosshair) {
        .entity => |entity| try attackEntity(io, game, entity.entity_id),
        .block => |block| try startMiningBlock(io, game, player, block.pos, block.face),
        .miss => game.input_manager.cooldown.attack = 10,
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

pub fn startMiningBlock(io: std.Io, game: *Game, player: *LocalPlayer, block_pos: Vector3(i32), face: Direction) !void {
    // TODO: Check game mode, world border
    std.debug.assert(game.world.crosshair == .block);

    if (game.world.getBlock(block_pos) == .air) return;
    // TODO: adventure mode tag overrides
    if (game.world.game_mode.restrictsWorldModification()) return;

    // todo: world border

    // creative instabreak
    if (game.world.game_mode == .creative) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .start_breaking_block,
            .block_pos = block_pos,
            .face = face,
        } });
        try instaMineBlock(game, block_pos);
        game.input_manager.cooldown.mining = 5;
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
            .face = face,
        } });
    }

    try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
        .action = .start_breaking_block,
        .block_pos = block_pos,
        .face = face,
    } });

    const block = game.world.getBlock(block_pos);
    // stuff like eating cake on left click, note blocks, etc.

    if (block.getMiningProgress(player) >= 1.0) {
        try finishMiningBlock(game, block_pos);
    } else game.world.mining_state = .{
        .block_pos = game.world.crosshair.block.pos,
        .face = game.world.crosshair.block.face,
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
    try game.world.setBlockState(std.mem.Allocator.failing, block_pos, .air);
    game.world.mining_state = null;
}

pub fn updateBlockMining(io: std.Io, game: *Game, player: *LocalPlayer, block_pos: Vector3(i32), face: Direction) !void {
    try updateHotbarSlot(io, game, player);

    if (game.input_manager.cooldown.mining > 0) {
        game.input_manager.cooldown.mining -|= 1;
        return;
    }
    if (game.world.game_mode == .creative) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
            .action = .start_breaking_block,
            .block_pos = block_pos,
            .face = face,
        } });
        try instaMineBlock(game, block_pos);
        game.input_manager.cooldown.mining = 5;
        return;
    }
    const mining_state = &(game.world.mining_state orelse return try startMiningBlock(io, game, player, block_pos, face));
    if (!mining_state.block_pos.equals(block_pos)) return try startMiningBlock(io, game, player, block_pos, face);

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
            .face = face,
        } });
        try finishMiningBlock(game, block_pos);
        game.world.mining_state = null;
        game.input_manager.cooldown.mining = 5;
    }
}

pub fn swingHand(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .hand_swing = .{} });
}

pub fn dropSingleItem(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        io,
        .{ .player_hand_action = .{ .action = .drop_single_item, .block_pos = .origin, .face = .down } },
    );
}

pub fn dropEntireStack(io: std.Io, game: *Game) !void {
    try game.connection_handle.sendPlayPacket(
        io,
        .{ .player_hand_action = .{ .action = .drop_entire_stack, .block_pos = .origin, .face = .down } },
    );
}

pub fn use(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    if (game.world.mining_state != null) return;

    game.input_manager.cooldown.auto_use = 4;

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
    if (game.world.game_mode == .spectator) return;

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
        .action = .{ .interact_at = game.world.crosshair.entity.offset },
        .target_network_id = game.world.crosshair.entity.entity_id,
    } });
    return false;
}

/// TODO
pub fn interactEntity(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try updateHotbarSlot(io, game, player);

    try game.connection_handle.sendPlayPacket(io, .{ .player_interact_entity = .{
        .action = .interact,
        .target_network_id = game.world.crosshair.entity.entity_id,
    } });
    return false;
}

/// Returns whether the interaction was consumed
/// Attempts to either interact with block or place block
pub fn useBlock(io: std.Io, game: *Game, player: *LocalPlayer) !bool {
    try updateHotbarSlot(io, game, player);

    // TODO: World border

    const crosshair = game.world.crosshair;

    std.debug.assert(game.world.getBlock(crosshair.block.pos) != .air);

    const maybe_held_item_stack = player.getHeldStack(game);

    if (game.world.game_mode == .spectator) {
        try game.connection_handle.sendPlayPacket(io, .{ .player_use = .{
            .block_pos = crosshair.block.pos,
            .face = crosshair.block.face,
            .stack = maybe_held_item_stack,
            .offset = .floatCast(crosshair.block.offset),
        } });
        return true;
    }

    const block_state = game.world.getBlockState(crosshair.block.pos);

    var consumed: bool = false;

    // if we are *not* sneaking, or our hand is empty, try to interact with the block itself
    if (!player.isSneaking() or maybe_held_item_stack == null) {
        consumed = try block_state.use(&game.world, player, crosshair.block.pos);
    }

    // if we are holding a block item, make sure we can actually place it
    // if not, we return without even sending a packet
    if (!consumed) {
        if (maybe_held_item_stack) |held_item_stack| {
            if (held_item_stack.item.getBlock()) |block| {
                const crosshair_target = game.world.resolveVirtualBlockState(crosshair.block.pos);

                var dir = crosshair.block.face;
                var block_pos = crosshair.block.pos;
                if (crosshair_target.block == .snow_layer) {
                    dir = .up;
                } else if (!crosshair_target.canBeReplaced()) {
                    block_pos = block_pos.dir(dir);
                }
                if (!block.canBePlacedAsCombinedSlab(held_item_stack.metadata, &game.world, crosshair.block.pos, crosshair.block.face) and !block.canBePlaced(&game.world, block_pos, dir)) return false;
            }
        }
    }

    try game.connection_handle.sendPlayPacket(io, .{ .player_use = .{
        .block_pos = crosshair.block.pos,
        .face = crosshair.block.face,
        .stack = maybe_held_item_stack,
        .offset = .floatCast(crosshair.block.offset),
    } });

    if (consumed) return true;

    if (maybe_held_item_stack) |held_item_stack| {
        return held_item_stack.useOn(&game.world, player, crosshair.block.pos, crosshair.block.face, crosshair.block.offset);
    }
    return false;
}

pub fn stopUsingItem(io: std.Io, game: *Game, player: *LocalPlayer) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .player_hand_action = .{
        .action = .stop_using_item,
        .block_pos = .origin,
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

pub fn click(io: std.Io, allocator: std.mem.Allocator, game: *Game, menu: *Menu, action: Menu.Action) !void {
    if (menu.type == .creative_inventory) return clickCreative(io, allocator, game, menu, action);

    const wire_format: Menu.Action.WireFormat = .convert(action, menu);
    const stack = try action.performOn(allocator, &game.world, menu);
    try game.connection_handle.sendPlayPacket(io, .{
        .menu_click_slot = .{
            .menu_network_id = @intCast(menu.network_id),
            .slot_id = wire_format.slot_id,
            .action = wire_format.action,
            .transaction_id = menu.nextTransactionId(),
            .click_data = wire_format.click_data,
            .item_stack = stack,
        },
    });
}

/// Creative inventory tabs are client-only; acquiring an item gives an infinite
/// stack to the cursor, and only changes to the real player inventory are sent
/// as creative-menu slot packets.
fn clickCreative(io: std.Io, allocator: std.mem.Allocator, game: *Game, menu: *Menu, action: Menu.Action) !void {
    switch (action) {
        .click => |click_action| {
            const index: usize = if (click_action.maybe_slot_index) |slot| @backingInt(slot) else return;
            if (index < 45) {
                if (game.world.maybe_cursor_stack != null) return;
                const source = menu.getSlot(@fromBackingInt(@intCast(index))) orelse return;
                game.world.maybe_cursor_stack = try Item.Stack.dupe(allocator, source);
            } else {
                _ = try action.performOn(allocator, &game.world, menu);
                try setCreativeSlot(io, game, @intCast(36 + index - 45), menu.getSlot(@fromBackingInt(@intCast(index))));
            }
        },
        .quick_move => |move| {
            const index: usize = @backingInt(move.slot_index);
            if (index < 45) {
                const source = menu.getSlot(@fromBackingInt(@intCast(index))) orelse return;
                var copy = (try Item.Stack.dupe(allocator, source)).?;
                copy.size = copy.item.maxStackSize();
                game.world.maybe_cursor_stack = copy;
            } else {
                // CreativePlayerMenu.quickMoveItem clears the hotbar slot.
                menu.clearSlot(allocator, @fromBackingInt(@intCast(index)));
                try setCreativeSlot(io, game, @intCast(36 + index - 45), null);
            }
        },
        .throw => |throw| {
            const index: usize = @backingInt(throw.slot_index);
            if (index < 45) {
                const stack = menu.getSlot(@fromBackingInt(@intCast(index))) orelse return;
                var copy = (try Item.Stack.dupe(allocator, stack)).?;
                copy.size = if (throw.count == .all) copy.size else 1;
                try setCreativeSlot(io, game, -1, copy);
            } else {
                _ = try action.performOn(allocator, &game.world, menu);
                try setCreativeSlot(io, game, @intCast(36 + index - 45), menu.getSlot(@fromBackingInt(@intCast(index))));
            }
        },
        .clone => |clone| {
            const index: usize = @backingInt(clone.slot_index);
            const stack = menu.getSlot(@fromBackingInt(@intCast(index))) orelse return;
            var copy = (try Item.Stack.dupe(allocator, stack)).?;
            copy.size = copy.item.maxStackSize();
            game.world.maybe_cursor_stack = copy;
        },
        .drag => |drag| {
            _ = try action.performOn(allocator, &game.world, menu);
            if (drag == .finish) {
                // Vanilla re-syncs all nine hotbar slots after a creative drag.
                for (0..9) |i| {
                    try setCreativeSlot(io, game, @intCast(36 + i), menu.getSlot(@fromBackingInt(@intCast(45 + i))));
                }
            }
        },
        else => _ = try action.performOn(allocator, &game.world, menu),
    }
}

pub fn clickMenuButton(io: std.Io, game: *Game, menu_id: i32, button_id: i8) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .menu_click_button = .{
        .menu_network_id = @intCast(menu_id),
        .button_id = button_id,
    } });
}

pub fn sendCustomPayload(io: std.Io, game: *Game, channel: []const u8, data: []const u8) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .custom_payload = .{
        .channel = channel,
        .data = data,
    } });
}

pub fn sendAnvilName(io: std.Io, allocator: std.mem.Allocator, game: *Game, name: []const u8) !void {
    var list: std.ArrayList(u8) = try .initCapacity(allocator, name.len + 5);
    defer list.deinit(allocator);
    var buffer: main.network.packet.C2S.WriteBuffer = .{ .backer = list };
    try buffer.writeString(name);
    try sendCustomPayload(io, game, "MC|ItemName", buffer.backer.items);
}

pub fn setCreativeSlot(io: std.Io, game: *Game, slot_id: i16, stack: ?Item.Stack) !void {
    try game.connection_handle.sendPlayPacket(io, .{ .creative_menu_slot = .{
        .slot_id = slot_id,
        .item_stack = stack,
    } });
}

pub fn closeScreen(io: std.Io, allocator: std.mem.Allocator, game: *Game) !void {
    if (game.world.sign_editor) |editor| {
        try game.connection_handle.sendPlayPacket(io, .{ .sign_update = .{
            .block_pos = editor.pos,
            .lines = editor.lines,
            .lens = editor.lens,
        } });
        game.world.sign_editor = null;
        game.world.menu_screen_open = false;
        return;
    }
    if (game.world.menu_screen_open) {
        try game.connection_handle.sendPlayPacket(io, .{ .close_menu = .{
            .menu_network_id = @intCast(game.world.getMenu().network_id),
        } });
        Item.Stack.deinit(allocator, &game.world.maybe_cursor_stack);
        game.world.maybe_cursor_stack = null;
        game.world.closeMenu(allocator);
    }
}

pub fn openScreen(io: std.Io, allocator: std.mem.Allocator, game: *Game) !void {
    if (game.world.menu_screen_open or game.world.sign_editor != null) return;
    try game.connection_handle.sendPlayPacket(io, .{ .client_status = .{
        .status = .open_inventory_achievement,
    } });
    if (game.world.player.abilities.creative_mode) {
        game.world.openMenu(allocator, .{ .other = try Menu.initCreativeMenu(allocator, game.world.main_inventory) });
    } else {
        game.world.openMenu(allocator, .player_menu);
    }
}

const std = @import("std");

const main = @import("main");

const Game = main.Client.Game;
const Direction = main.Direction;
const LocalPlayer = main.Entity.LocalPlayer;
const Item = main.Item;
const Menu = main.Menu;
const Vector3 = main.Vector3;
