var done = false;
pub fn debug(world: *const World) void {
    defer done = true;
    if (done) return;
    for (world.player_inventory_menu.slots, 0..) |slot, i| {
        std.log.debug("{} {} {}", .{ i, slot.index_into_backer, slot.backer.type });
    }
}

pub fn bufferInventory(
    self: *Renderer,
    world: *const World,
    item_models_lookup: std.AutoHashMapUnmanaged(u16, resource_pack.BakedItemModel),
    cursor_pos: Vector2xy(f32),
) !void {
    const size: f32 = 0.11;

    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);

    const aspect_ratio = window_width / window_height;

    if (world.maybe_cursor_stack) |cursor_stack| blk: {
        const model = item_models_lookup.get(@backingInt(cursor_stack.item) << 4) orelse break :blk;

        const translate: za.Mat4 = .fromTranslate(.new(cursor_pos.x, cursor_pos.y, 0));

        const scale: za.Mat4 = .fromScale(.new(
            size / if (aspect_ratio > 1) aspect_ratio else 1,
            size * if (aspect_ratio < 1) aspect_ratio else 1,
            1,
        ));
        const center: za.Mat4 = .fromTranslate(.new(-0.5, -0.5, -0.5));
        const transform: za.Mat4 = .mul(.mul(translate, scale), center);
        for (model.model.faces) |face| {
            var positions = face.pos;
            for (&positions) |*pos| {
                const za_pos = transform.mulByVec3(
                    .new(pos.x, pos.y, pos.z),
                );
                pos.* = .{ .x = za_pos.x(), .y = za_pos.y(), .z = za_pos.z() };
            }

            try self.@"2d_debug_staging_buffer".write3dDebugQuad(positions, face.uv, face.texture);
        }
    }

    const menu = world.getMenu();

    for (menu.slots, 0..) |_, i| {
        const slot_stack = menu.getSlot(@fromBackingInt(@intCast(i))) orelse continue;

        const model = item_models_lookup.get(@backingInt(slot_stack.item) << 4) orelse continue;

        const slot_pos = getSlotPosForMenu(menu, @fromBackingInt(@intCast(i)));

        const translate: za.Mat4 = .fromTranslate(.new(
            (slot_pos.x) / if (aspect_ratio > 1) aspect_ratio else 1,
            (slot_pos.y) * if (aspect_ratio < 1) aspect_ratio else 1,
            0,
        ));
        const scale: za.Mat4 = .fromScale(.new(
            size / if (aspect_ratio > 1) aspect_ratio else 1,
            size * if (aspect_ratio < 1) aspect_ratio else 1,
            size,
        ));
        const center: za.Mat4 = .fromTranslate(.new(-0.5, -0.5, -0.5));

        const transform: za.Mat4 = .mul(.mul(.mul(translate, scale), model.transform(.gui)), center);

        for (model.model.faces) |face| {
            var positions = face.pos;
            for (&positions) |*pos| {
                const za_pos = transform.mulByVec3(.new(pos.x, pos.y, pos.z));
                pos.* = .{ .x = za_pos.x(), .y = za_pos.y(), .z = -za_pos.z() };
            }

            try self.@"2d_debug_staging_buffer".write3dDebugQuad(positions, face.uv, face.texture);
        }
    }
}

/// Approximate GUI background used to distinguish a no-op click inside the GUI
/// from a click outside it (vanilla uses slot -1 vs -999).
pub fn isInsideBackground(cursor_pos: Vector2xy(f32)) bool {
    return @abs(cursor_pos.x) <= 0.62 and @abs(cursor_pos.y) <= 0.5;
}

/// Returns null for a click on empty GUI background, which vanilla ignores.
pub fn onClick(world: *const World, cursor_pos: Vector2xy(f32), button: glfw.MouseButton, shift: bool) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    const menu = world.getMenu();

    // With a stack already held, a press only arms a click-drag; the actual
    // packets are emitted on release (vanilla InventoryMenuScreen.mouseClicked).
    if (world.maybe_cursor_stack != null) {
        return .{ .drag = .{ .begin = switch (button) {
            .left => .split,
            .right => .single,
            else => .duplicate,
        } } };
    }

    for (menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            if (button == .middle) return .{ .clone = .{ .slot_index = @fromBackingInt(@intCast(i)) } };
            return if (shift) .{
                .quick_move = .{
                    .slot_index = @fromBackingInt(@intCast(i)),
                },
            } else .{ .click = .{
                .maybe_slot_index = @fromBackingInt(@intCast(i)),
                .count = switch (button) {
                    .left => .all,
                    .right => .one_or_half,
                    else => .all,
                },
            } };
        }
    }
    if (isInsideBackground(cursor_pos)) return null;
    return .{ .click = .{
        .maybe_slot_index = null,
        .count = switch (button) {
            .left => .all,
            .right => .one_or_half,
            else => .all,
        },
    } };
}

pub fn onHotbarKey(world: *const World, cursor_pos: Vector2xy(f32), key: u4) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    const menu = world.getMenu();
    // Vanilla only swaps with an empty cursor (InventoryMenuScreen.java:533).
    if (world.maybe_cursor_stack != null) return null;

    for (menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            return .{ .hotbar_swap = .{
                .slot_index = @fromBackingInt(@intCast(i)),
                .hotbar_slot = key,
            } };
        }
    }
    return null;
}

pub fn onDropKey(world: *const World, cursor_pos: Vector2xy(f32), all: bool) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    const menu = world.getMenu();

    for (menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            return .{ .throw = .{
                .slot_index = @fromBackingInt(@intCast(i)),
                .count = if (all) .all else .one,
            } };
        }
    }
    return null;
}

/// Given a menu and a slot inside it, returns where it should be positioned
pub fn getSlotPosForMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    switch (menu.type) {
        .player => return getSlotPosForPlayerMenu(menu, slot_index),
        .chest => return getSlotPosForChestMenu(menu, slot_index),
        .hopper => return getSlotPosForHopperMenu(menu, slot_index),
        .dispenser, .dropper => return getSlotPosForDispenserMenu(menu, slot_index),
        .crafting_table, .furnace, .anvil, .enchanting_table, .brewing_stand, .beacon, .horse, .villager, .creative_inventory => return getSlotPosForOtherMenu(menu, slot_index),
    }
}

fn playerSlotPos(slot: Menu.Slot) Vector2xy(f32) {
    const inventory_index = slot.index_into_backer;
    const hotbar = inventory_index < 9;
    const row: f32 = if (hotbar) 0 else @floatFromInt(4 - inventory_index / 9);
    const col: f32 = @floatFromInt(inventory_index % 9);
    return .{
        .x = (col - 4.5) * 0.125,
        .y = (row - 2) * 0.125 - 0.2 - @as(f32, if (hotbar) 0.05 else 0),
    };
}

/// Slot positions for the menus added after the original chest/hopper/dispenser set.
/// Positions are deliberately expressed in the same compact clip-space grid as the
/// existing layouts; what matters for the server is that rendering and hit-testing
/// agree on which slot index is under the cursor.
fn getSlotPosForOtherMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    const i: usize = @backingInt(slot_index);
    const slot = menu.slots[i];
    if (slot.backer.type == .player) return playerSlotPos(slot);

    const local: usize = slot.index_into_backer;
    return switch (menu.type) {
        .crafting_table => if (i == 0) toPos(2, 0) else toPos((local % 3), local / 3),
        .furnace => switch (local) {
            0 => toPos(1, 0), // input
            1 => toPos(1, 1), // fuel
            else => toPos(2, 0), // result
        },
        .anvil => switch (local) {
            0 => toPos(1, 0),
            1 => toPos(1, 1),
            else => toPos(2, 0),
        },
        .enchanting_table => if (local == 0) toPos(1, 0) else toPos(1, 1),
        .brewing_stand => if (local == 3) toPos(2, 1) else toPos(1, local),
        .beacon => toPos(2, 0),
        .horse => if (local == 0) toPos(0, 0) else if (local == 1) toPos(0, 1) else toPos(2 + (local - 2) % 5, (local - 2) / 5),
        .villager => switch (local) {
            0 => toPos(1, 0),
            1 => toPos(1, 1),
            else => toPos(2, 0),
        },
        .creative_inventory => toPos(local % 9, local / 9),
        else => unreachable,
    };
}

fn toPos(col: usize, row: usize) Vector2xy(f32) {
    return .{ .x = (@as(f32, @floatFromInt(col)) - 4.5) * 0.125, .y = (@as(f32, @floatFromInt(row)) - 2) * 0.125 - 0.2 };
}

pub fn getSlotPosForPlayerMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .player);
    const slot = menu.slots[@backingInt(slot_index)];
    switch (slot.backer.type) {
        .player => {
            switch (slot.type) {
                .armor => |armor| {
                    const row: usize = 12 - @backingInt(armor); // boots(8) -> 4, helmet(5) -> 7
                    return .add(toPos(0, row), .{ .x = 0, .y = 0.05 });
                },
                else => {},
            }

            const inventory_index = slot.index_into_backer;

            const hotbar = inventory_index < 9;
            const col = inventory_index % 9;
            const row = if (hotbar) 0 else 4 - inventory_index / 9;

            return .add(toPos(col, row), .{ .x = 0, .y = if (hotbar) -0.05 else 0 });
        },
        .player_crafting => return .add(toPos(1 + (slot.index_into_backer & 1), 5 - ((slot.index_into_backer & 2) >> 1)), .{ .x = 0, .y = 0.05 }),
        .crafting_result => return toPos(3, 4),
        else => unreachable,
    }
}

pub fn getSlotPosForChestMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .chest);
    const slot = menu.slots[@backingInt(slot_index)];
    switch (slot.backer.type) {
        .player => {
            const inventory_index = slot.index_into_backer;

            const hotbar = inventory_index < 9;
            const row: f32 = if (hotbar) 0 else @floatFromInt(4 - inventory_index / 9);
            const col: f32 = @floatFromInt(inventory_index % 9);

            return .{
                .x = (col - 4.5) * 0.125,
                .y = (row - 2) * 0.125 - 0.2 - @as(f32, if (hotbar) 0.05 else 0),
            };
        },
        .chest => {
            const inventory_index = slot.index_into_backer;

            const rows: f32 = @floatFromInt(slot.backer.stacks.len / 9);

            const row: f32 = (inventory_index / 9);
            const col: f32 = @floatFromInt(inventory_index % 9);

            return .{
                .x = (col - 4.5) * 0.125,
                .y = (rows - row) * 0.125,
            };
        },
        else => unreachable,
    }
}

pub fn getSlotPosForHopperMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .hopper);
    const slot = menu.slots[@backingInt(slot_index)];
    switch (slot.backer.type) {
        .player => {
            const inventory_index = slot.index_into_backer;

            const hotbar = inventory_index < 9;
            const row: f32 = if (hotbar) 0 else @floatFromInt(4 - inventory_index / 9);
            const col: f32 = @floatFromInt(inventory_index % 9);

            return .{
                .x = (col - 4.5) * 0.125,
                .y = (row - 2) * 0.125 - 0.2 - @as(f32, if (hotbar) 0.05 else 0),
            };
        },
        .hopper => {
            const inventory_index = slot.index_into_backer;

            const col: f32 = @floatFromInt(inventory_index);

            return .{
                .x = (col - 2.5) * 0.125,
                .y = 0.125,
            };
        },
        else => unreachable,
    }
}

pub fn getSlotPosForDispenserMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .dispenser);
    const slot = menu.slots[@backingInt(slot_index)];
    switch (slot.backer.type) {
        .player => {
            const inventory_index = slot.index_into_backer;

            const hotbar = inventory_index < 9;
            const row: f32 = if (hotbar) 0 else @floatFromInt(4 - inventory_index / 9);
            const col: f32 = @floatFromInt(inventory_index % 9);

            return .{
                .x = (col - 4.5) * 0.125,
                .y = (row - 2) * 0.125 - 0.2 - @as(f32, if (hotbar) 0.05 else 0),
            };
        },
        .dispenser => {
            const inventory_index = slot.index_into_backer;

            const row: f32 = @floatFromInt(inventory_index / 3);
            const col: f32 = @floatFromInt(inventory_index % 3);

            return .{
                .x = (col - 1.5) * 0.125,
                .y = (3 - row) * 0.125,
            };
        },
        else => unreachable,
    }
}

/// The three enchanting buttons sit to the right of the enchanting grid.
pub fn enchantButtonAt(cursor_pos: Vector2xy(f32)) ?i8 {
    for (0..3) |i| {
        const center_x: f32 = 0.36;
        const center_y: f32 = -0.24 + @as(f32, @floatFromInt(i)) * 0.1;
        if (@abs(cursor_pos.x - center_x) <= 0.06 and @abs(cursor_pos.y - center_y) <= 0.04)
            return @intCast(i);
    }
    return null;
}

/// Returns the slot under the cursor using the same transform as rendering.
pub fn hoveredSlot(world: *const World, cursor_pos: Vector2xy(f32)) ?Menu.SlotIndex {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;
    const menu = world.getMenu();

    for (menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y)
            return @fromBackingInt(@intCast(i));
    }
    return null;
}

/// Mouse release emits the second half of a click, a three-stage drag, or a
/// double-click pickup-all (vanilla InventoryMenuScreen.mouseReleased).
pub fn onRelease(
    world: *const World,
    cursor_pos: Vector2xy(f32),
    button: glfw.MouseButton,
    shift: bool,
    drag_mode: ?Menu.Action.Drag.Mode,
    double_click: bool,
    actions: *std.ArrayList(Menu.Action),
    allocator: std.mem.Allocator,
) !void {
    const hovered = hoveredSlot(world, cursor_pos);

    if (drag_mode) |_| {
        if (hovered) |slot_index| {
            try actions.append(allocator, .{ .drag = .{ .add_slot = slot_index } });
        } else if (!isInsideBackground(cursor_pos)) {
            // Dropping a held stack outside the GUI throws it (slot -999).
            try actions.append(allocator, .{ .click = .{ .maybe_slot_index = null, .count = if (button == .left) .all else .one_or_half } });
            return;
        }
        try actions.append(allocator, .{ .drag = .finish });
        return;
    }
    if (world.maybe_cursor_stack == null) return;

    if (double_click and button == .left) {
        if (hovered) |slot_index| try actions.append(allocator, .{ .collect = .{ .slot_index = slot_index } });
        return;
    }

    if (hovered) |slot_index| {
        if (button == .middle) {
            try actions.append(allocator, .{ .clone = .{ .slot_index = slot_index } });
        } else if (shift) {
            try actions.append(allocator, .{ .quick_move = .{ .slot_index = slot_index } });
        } else {
            try actions.append(allocator, .{ .click = .{ .maybe_slot_index = slot_index, .count = if (button == .left) .all else .one_or_half } });
        }
    } else if (!isInsideBackground(cursor_pos)) {
        try actions.append(allocator, .{ .click = .{ .maybe_slot_index = null, .count = if (button == .left) .all else .one_or_half } });
    }
}

const std = @import("std");

const glfw = @import("mach-glfw");
const main = @import("main");
const render = @import("render");
const za = @import("zalgebra");

const Menu = main.Menu;
const Vector2xy = main.Vector2xy;
const World = main.World;
const Renderer = render.Renderer;
const resource_pack = render.resource_pack;
