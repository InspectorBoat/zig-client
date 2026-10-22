const std = @import("std");

const glfw = @import("mach-glfw");

const main = @import("main");
const render = @import("render");

const Menu = main.Menu;
const Vector2xy = main.Vector2xy;
const World = main.World;
const Renderer = render.Renderer;

var done = false;
pub fn debug(world: *const World) void {
    defer done = true;
    if (done) return;
    for (world.player_inventory_menu.slots, 0..) |slot, i| {
        std.log.debug("{} {} {}", .{ i, slot.index_into_backer, slot.backer.type });
    }
}

pub fn bufferInventory(self: *Renderer, world: *const World, cursor_pos: Vector2xy(f32)) !void {
    const box_size: f32 = 0.11;

    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    if (world.maybe_cursor_stack) |_| {
        try self.@"2d_debug_staging_buffer".write2dDebugQuad(
            .{
                .x = cursor_pos.x - (box_size / 2 / if (aspect_ratio > 1) aspect_ratio else 1),
                .y = cursor_pos.y - (box_size / 2 * if (aspect_ratio < 1) aspect_ratio else 1),
            },
            .{
                .x = cursor_pos.x + (box_size / 2 / if (aspect_ratio > 1) aspect_ratio else 1),
                .y = cursor_pos.y + (box_size / 2 * if (aspect_ratio < 1) aspect_ratio else 1),
            },
        );
    }

    for (world.player_inventory_menu.slots, 0..) |_, i| {
        if (world.player_inventory_menu.getSlot(@fromBackingInt(@intCast(i))) == null) continue;
        const pos = getSlotPosForMenu(&world.player_inventory_menu, @fromBackingInt(@intCast(i)));
        // the 2d debug path wants clip space, with y pointing up
        try self.@"2d_debug_staging_buffer".write2dDebugQuad(
            .{
                .x = (pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
                .y = (pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
            },
            .{
                .x = (pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
                .y = (pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
            },
        );
    }
}

pub fn onClick(world: *const World, cursor_pos: Vector2xy(f32), button: glfw.MouseButton) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    for (world.player_inventory_menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(&world.player_inventory_menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            return .{ .click = .{ @fromBackingInt(@intCast(i)), switch (button) {
                .left => .all,
                .right => .one_or_half,
                else => continue,
            } } };
        }
    }
    return null;
}

pub fn onHotbarKey(world: *const World, cursor_pos: Vector2xy(f32), key: u4) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    for (world.player_inventory_menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(&world.player_inventory_menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            return .{ .hotbar_swap = .{ @fromBackingInt(@intCast(i)), key } };
        }
    }
    return null;
}

pub fn onDropKey(world: *const World, cursor_pos: Vector2xy(f32), all: bool) ?Menu.Action {
    const box_size: f32 = 0.11;
    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);
    const aspect_ratio = window_width / window_height;

    for (world.player_inventory_menu.slots, 0..) |_, i| {
        const slot_pos = getSlotPosForMenu(&world.player_inventory_menu, @fromBackingInt(@intCast(i)));
        const min: Vector2xy(f32) = .{
            .x = (slot_pos.x - box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y - box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        const max: Vector2xy(f32) = .{
            .x = (slot_pos.x + box_size / 2) / if (aspect_ratio > 1) aspect_ratio else 1,
            .y = (slot_pos.y + box_size / 2) * if (aspect_ratio < 1) aspect_ratio else 1,
        };
        if (cursor_pos.x >= min.x and cursor_pos.x <= max.x and cursor_pos.y >= min.y and cursor_pos.y <= max.y) {
            return .{ .throw = .{ @fromBackingInt(@intCast(i)), if (all) .all else .one } };
        }
    }
    return null;
}

/// Given a menu and a slot inside it, returns where it should be positioned
pub fn getSlotPosForMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    switch (menu.type) {
        .player => return getSlotPosForPlayerMenu(menu, slot_index),
        else => std.debug.panic("TODO!", .{}),
    }
}

pub fn getSlotPosForPlayerMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .player);
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
        .player_crafting => return .{ .x = 0, .y = 0 },
        .crafting_result => return .{ .x = 0, .y = 0 },
        else => unreachable,
    }
}
