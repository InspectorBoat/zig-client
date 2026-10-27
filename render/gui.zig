var done = false;
pub fn debug(world: *const World) void {
    defer done = true;
    if (done) return;
    for (world.player_inventory_menu.slots, 0..) |slot, i| {
        std.log.debug("{} {} {}", .{ i, slot.index_into_backer, slot.backer.type });
    }
}

pub fn bufferInventory(self: *Renderer, world: *const World, item_models_lookup: std.AutoHashMapUnmanaged(u16, resource_pack.BakedModel), cursor_pos: Vector2xy(f32)) !void {
    const size: f32 = 0.11;

    const window_width: f32 = @floatFromInt(render.window_input.window_size.x);
    const window_height: f32 = @floatFromInt(render.window_input.window_size.y);

    const aspect_ratio = window_width / window_height;

    if (world.maybe_cursor_stack) |cursor_stack| {
        const model = item_models_lookup.get(@backingInt(cursor_stack.item) << 4).?;

        const translate: za.Mat4 = .fromTranslate(.new(cursor_pos.x, cursor_pos.y, 0));

        const scale: za.Mat4 = .fromScale(.new(
            size / if (aspect_ratio > 1) aspect_ratio else 1,
            size * if (aspect_ratio < 1) aspect_ratio else 1,
            1,
        ));
        const center: za.Mat4 = .fromTranslate(.new(-0.5, -0.5, -0.5));
        const transform: za.Mat4 = .mul(.mul(translate, scale), center);
        for (model.faces) |face| {
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

        const model = item_models_lookup.get(@backingInt(slot_stack.item) << 4).?;

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
        const rotate: za.Mat4 = .fromEulerAngles(.new(0, r, 0));

        const transform: za.Mat4 = .mul(.mul(.mul(translate, scale), rotate), center);

        for (model.faces) |face| {
            var positions = face.pos;
            for (&positions) |*pos| {
                const za_pos = transform.mulByVec3(.new(pos.x, pos.y, pos.z));
                pos.* = .{ .x = za_pos.x(), .y = za_pos.y(), .z = -za_pos.z() };
            }
            try self.@"2d_debug_staging_buffer".write3dDebugQuad(positions, face.uv, face.texture);
        }
    }
    r += 0.2;
}

var r: f32 = 0;

pub fn onClick(world: *const World, cursor_pos: Vector2xy(f32), button: glfw.MouseButton) Menu.Action {
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
            return .{ .click = .{
                .maybe_slot_index = @fromBackingInt(@intCast(i)),
                .count = switch (button) {
                    .left => .all,
                    .right => .one_or_half,
                    else => unreachable,
                },
            } };
        }
    }
    return .{ .click = .{
        .maybe_slot_index = null,
        .count = switch (button) {
            .left => .all,
            .right => .one_or_half,
            else => unreachable,
        },
    } };
}

pub fn onHotbarKey(world: *const World, cursor_pos: Vector2xy(f32), key: u4) ?Menu.Action {
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
        .dispenser => return getSlotPosForDispenserMenu(menu, slot_index),
        else => std.debug.panic("TODO", .{}),
    }
}

pub fn getSlotPosForPlayerMenu(menu: *const Menu, slot_index: Menu.SlotIndex) Vector2xy(f32) {
    std.debug.assert(menu.type == .player);
    const slot = menu.slots[@backingInt(slot_index)];
    switch (slot.backer.type) {
        .player => {
            const inventory_index = slot.index_into_backer;

            if (inventory_index >= 36) return .{ .x = 100, .y = 100 };

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
