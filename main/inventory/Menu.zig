const std = @import("std");

const main = @import("main");

const Entity = main.Entity;
const Inventory = main.Inventory;
const Item = main.Item;
const World = main.World;
const Menu = @This();

pub const Type = union(enum) {
    player,
    crafting_table: *Inventory,
    chest,
    hopper,
    anvil,
    brewing_stand,
    horse,
    dropper,
    dispenser,
    furnace,
};

type: Type,
network_id: i32,
slots: []Slot,
drag_state: DragState = .none,
next_transaction_id: i16 = 0,

pub fn nextTransactionId(self: *@This()) i16 {
    self.next_transaction_id += 1;
    return self.next_transaction_id;
}

pub fn setSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: SlotIndex, new_item_stack: ?Item.Stack) void {
    const slot = self.slots[@backingInt(slot_index)];

    // free old stack, if present
    Item.Stack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);

    slot.backer.stacks[slot.index_into_backer] = new_item_stack;
}

pub fn getSlot(self: *const @This(), slot_index: SlotIndex) ?Item.Stack {
    const slot = self.slots[@backingInt(slot_index)];

    return slot.backer.stacks[slot.index_into_backer];
}

pub fn clearSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: SlotIndex) void {
    self.setSlot(allocator, slot_index, null);
}

pub fn getSlotPtr(self: *@This(), slot_index: SlotIndex) *?Item.Stack {
    const slot = self.slots[@backingInt(slot_index)];

    return &slot.backer.stacks[slot.index_into_backer];
}

pub fn initPlayerMenu(
    allocator: std.mem.Allocator,
    main_inventory: *Inventory,
    crafting_inventory: *Inventory,
    crafting_result_inventory: *Inventory,
) !@This() {
    var slots: std.ArrayList(Slot) = try .initCapacity(
        allocator,
        main_inventory.stacks.len + crafting_inventory.stacks.len + crafting_result_inventory.stacks.len,
    );

    // crafting result
    slots.appendAssumeCapacity(.{
        .backer = crafting_result_inventory,
        .type = .crafting_result,
        .index_into_backer = 0,
    });
    // 2x2 crafting
    for (0..4) |i| {
        slots.appendAssumeCapacity(.{
            .backer = crafting_inventory,
            .type = .generic,
            .index_into_backer = @intCast(i),
        });
    }
    // armor
    inline for (0..4, .{ .helmet, .chestplate, .leggings, .boots }) |i, armor_piece| {
        slots.appendAssumeCapacity(.{
            .backer = main_inventory,
            .type = armor_piece,
            .index_into_backer = @intCast(main_inventory.stacks.len - 1 - i),
        });
    }
    appendPlayerSlots(&slots, main_inventory);

    return .{
        .type = .player,
        .network_id = 0,
        .slots = slots.toOwnedSliceAssert(),
    };
}

pub fn initChestMenu(allocator: std.mem.Allocator, network_id: i16, player_inventory: *Inventory, chest_inventory: *Inventory) !@This() {
    std.debug.assert(chest_inventory.type == .chest);
    const rows = @divFloor(chest_inventory.stacks.len, 9);
    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, rows * 9 + 36);

    for (0..rows) |row| {
        for (0..9) |col| {
            slots.appendAssumeCapacity(.{
                .type = .generic,
                .backer = chest_inventory,
                .index_into_backer = @intCast(row * 9 + col),
            });
        }
    }
    appendPlayerSlots(&slots, player_inventory);

    return .{
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .type = .chest,
    };
}

pub fn initHopperMenu(allocator: std.mem.Allocator, network_id: i16, player_inventory: *Inventory, hopper_inventory: *Inventory) !@This() {
    std.debug.assert(hopper_inventory.type == .hopper);
    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, hopper_inventory.stacks.len + 36);

    for (0..hopper_inventory.stacks.len) |i| {
        slots.appendAssumeCapacity(.{
            .type = .generic,
            .backer = hopper_inventory,
            .index_into_backer = @intCast(i),
        });
    }
    appendPlayerSlots(&slots, player_inventory);

    return .{
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .type = .hopper,
    };
}

pub fn initDispenserMenu(allocator: std.mem.Allocator, network_id: i16, player_inventory: *Inventory, dispenser_inventory: *Inventory) !@This() {
    std.debug.assert(dispenser_inventory.type == .dispenser);
    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 9 + 36);

    for (0..3) |row| {
        for (0..3) |col| {
            slots.appendAssumeCapacity(.{
                .type = .generic,
                .backer = dispenser_inventory,
                .index_into_backer = @intCast(row * 3 + col),
            });
        }
    }
    appendPlayerSlots(&slots, player_inventory);

    return .{
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .type = .dispenser,
    };
}

fn appendPlayerSlots(slots: *std.ArrayList(Slot), player_inventory: *Inventory) void {
    std.debug.assert(player_inventory.type == .player);
    // main 3 rows
    for (1..4) |row| {
        for (0..9) |col| {
            slots.appendAssumeCapacity(.{
                .type = .generic,
                .backer = player_inventory,
                .index_into_backer = @intCast(row * 9 + col),
            });
        }
    }
    // hotbar
    for (0..9) |col| {
        slots.appendAssumeCapacity(.{
            .type = .generic,
            .backer = player_inventory,
            .index_into_backer = @intCast(col),
        });
    }
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    allocator.free(self.slots);
}

pub const Slot = struct {
    type: Slot.Type,
    backer: *Inventory,
    index_into_backer: u8,

    pub fn canPickUp(self: @This(), player: *const Entity.LocalPlayer) bool {
        _ = self;
        _ = player;
        // TODO: Anvil menu canPickUp depends on player xp level. FUCKKKK
        return true;
    }

    pub fn onItemRemoved(self: @This()) void {
        _ = self;
        // TODO: Implement
    }

    pub const Type = enum {
        generic,
        helmet,
        chestplate,
        leggings,
        boots,
        crafting_result,
        furnace_fuel,
        furnace_result,
        trade_result,
        beacon_payment,
        brewing_ingredient,
        brewing_potion,
        creative_inventory,
        anvil_result,

        pub fn isItemAllowed(self: @This(), item: Item) bool {
            _ = self;
            _ = item;
            // TODO: Implement
            return true;
        }

        pub fn maxStackSize(self: @This(), item: Item) i32 {
            _ = self;
            _ = item;
            // TODO: Implement
            return 64;
        }
    };
};

pub const SlotIndex = enum(u8) { _ };

pub const Action = union(Action.Type) {
    pub const Type = enum(i8) {
        click = 0,
        quick_move = 1,
        hotbar_swap = 2,
        clone = 3,
        throw = 4,
        drag = 5,
        collect = 6,
    };

    pub const Click = struct {
        maybe_slot_index: ?SlotIndex,
        count: enum(u1) { all = 0, one_or_half = 1 },
    };
    pub const QuickMove = struct {
        slot_index: SlotIndex,
    };
    pub const HotbarSwap = struct {
        slot_index: SlotIndex,
        hotbar_slot: u4,
    };
    pub const Clone = struct {
        slot_index: SlotIndex,
    };
    pub const Throw = struct {
        slot_index: SlotIndex,
        count: enum(u1) { one = 0, all = 1 },
    };
    pub const Drag = union(Drag.Stage) {
        pub const Stage = enum(i8) { begin = 0, add_slot = 1, finish = 2 };
        pub const Mode = enum(i8) { split = 0, single = 1, duplicate = 2 };

        begin: Mode,
        add_slot: SlotIndex,
        finish,
    };
    pub const Collect = struct {
        slot_index: SlotIndex,
    };
    /// interact with the hovered slot
    /// if the slot index is null:
    ///     throw (all or one of) the items held by the cursor out of the inventory
    /// if the cursor slot is empty: try to pick up all or half of the items in the hovered slot
    /// if the hovered slot is empty: try to deposit the all or one of the cursor items into the hovered slot
    /// if both the cursor and the hovered slot contain items:
    ///     if the hovered slot is the result of a crafting operation, try to pick up *all* of the slot's items into the cursor
    ///     if the hovered slot's items and the cursor's items are mergable, try to deposit all or one of the cursor's items into the slot
    ///     otherwise, try to swap the cursor and the hovered slot's items
    click: Click,
    /// shift-click an item between two areas of the menu
    quick_move: QuickMove,
    /// swap hovered slot with hotbar slot (0-8), indexed directly into the player inventory
    /// ignores slot-specific *size* restrictions
    hotbar_swap: HotbarSwap,
    /// clone the hovered slot into the cursor
    /// creative mode only
    clone: Clone,
    /// throw the items in the hovered slot out of the inventory
    throw: Throw,
    /// spread the cursor's held stack between slots
    /// there are three modes:
    ///     single - drops a single item per stack
    ///     split - spread the stack evenly
    ///     duplicate - duplicate a full stack to each slot, creative only
    drag: Drag,
    /// collect the matching stacks of the hovered slot into the cursor
    collect: Collect,

    pub const WireFormat = struct {
        slot_id: i16,
        click_data: i8,
        action: i8,

        /// Converts a click action into the parts of a `menu_click_slot` packet.
        pub fn convert(action: Action, menu: *const Menu) Action.WireFormat {
            const action_id: i8 = @backingInt(action);
            const slot_id: i16 = switch (action) {
                .click => |click| if (click.maybe_slot_index) |slot_index| @backingInt(slot_index) else -999,
                .quick_move => |quick_move| @backingInt(quick_move.slot_index),
                .hotbar_swap => |hotbar_swap| @backingInt(hotbar_swap.slot_index),
                .clone => |clone| @backingInt(clone.slot_index),
                .throw => |throw| @backingInt(throw.slot_index),
                .drag => |drag| switch (drag) {
                    .begin => -999,
                    .add_slot => |slot_index| @backingInt(slot_index),
                    .finish => -999,
                },
                .collect => |collect| @backingInt(collect.slot_index),
            };
            const click_data: i8 = switch (action) {
                .click => |click| @backingInt(click.count),
                .quick_move => 0,
                .hotbar_swap => |hotbar_swap| hotbar_swap.hotbar_slot,
                .clone => 0,
                .throw => |throw| @backingInt(throw.count),
                .drag => |drag| blk: {
                    const drag_mode = switch (drag) {
                        .begin => |mode| mode,
                        else => menu.drag_state.dragging.mode,
                    };
                    const drag_stage: Action.Drag.Stage = drag;
                    break :blk @backingInt(drag_mode) << 2 | @backingInt(drag_stage);
                },
                .collect => 0,
            };

            return .{
                .action = action_id,
                .click_data = click_data,
                .slot_id = slot_id,
            };
        }
    };
};

pub const DragState = union(enum) {
    none,
    dragging: struct { mode: Action.Drag.Mode, slot_indices: std.bit_set.Array(u64, 256) = .empty },
};

test "click parts" {
    var slots: [0]Slot = .{};
    var menu: @This() = .{ .type = .player, .network_id = 0, .slots = &slots };
    const slot: SlotIndex = @fromBackingInt(@intCast(5));

    const click_all: Action.WireFormat = .convert(.{ .click = .{ .maybe_slot_index = slot, .count = .all } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), click_all.slot_id);
    try std.testing.expectEqual(@as(i8, 0), click_all.click_data);
    try std.testing.expectEqual(@as(i8, 0), click_all.action);

    const click_half: Action.WireFormat = .convert(.{ .click = .{ .maybe_slot_index = slot, .count = .one_or_half } }, &menu);
    try std.testing.expectEqual(@as(i8, 1), click_half.click_data);
    try std.testing.expectEqual(@as(i8, 0), click_half.action);

    const throw_cursor: Action.WireFormat = .convert(.{ .click = .{ .maybe_slot_index = null, .count = .one_or_half } }, &menu);
    try std.testing.expectEqual(@as(i16, -999), throw_cursor.slot_id);
    try std.testing.expectEqual(@as(i8, 1), throw_cursor.click_data);
    try std.testing.expectEqual(@as(i8, 0), throw_cursor.action);

    const quick_move: Action.WireFormat = .convert(.{ .quick_move = .{ .slot_index = slot } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), quick_move.slot_id);
    try std.testing.expectEqual(@as(i8, 1), quick_move.action);

    const hotbar_swap: Action.WireFormat = .convert(.{ .hotbar_swap = .{ .slot_index = slot, .hotbar_slot = 3 } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), hotbar_swap.slot_id);
    try std.testing.expectEqual(@as(i8, 3), hotbar_swap.click_data);
    try std.testing.expectEqual(@as(i8, 2), hotbar_swap.action);

    const clone: Action.WireFormat = .convert(.{ .clone = .{ .slot_index = slot } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), clone.slot_id);
    try std.testing.expectEqual(@as(i8, 3), clone.action);

    const throw: Action.WireFormat = .convert(.{ .throw = .{ .slot_index = slot, .count = .all } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), throw.slot_id);
    try std.testing.expectEqual(@as(i8, 1), throw.click_data);
    try std.testing.expectEqual(@as(i8, 4), throw.action);

    const collect: Action.WireFormat = .convert(.{ .collect = .{ .slot_index = slot } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), collect.slot_id);
    try std.testing.expectEqual(@as(i8, 6), collect.action);

    const begin: Action.WireFormat = .convert(.{ .drag = .{ .begin = .split } }, &menu);
    try std.testing.expectEqual(@as(i16, -999), begin.slot_id);
    try std.testing.expectEqual(@as(i8, 0), begin.click_data);
    try std.testing.expectEqual(@as(i8, 5), begin.action);

    menu.drag_state = .{ .dragging = .{ .mode = .single } };
    const add_slot: Action.WireFormat = .convert(.{ .drag = .{ .add_slot = slot } }, &menu);
    try std.testing.expectEqual(@as(i16, 5), add_slot.slot_id);
    try std.testing.expectEqual(@as(i8, 1 | (1 << 2)), add_slot.click_data);
    try std.testing.expectEqual(@as(i8, 5), add_slot.action);

    const finish: Action.WireFormat = .convert(.{ .drag = .finish }, &menu);
    try std.testing.expectEqual(@as(i16, -999), finish.slot_id);
    try std.testing.expectEqual(@as(i8, 2 | (1 << 2)), finish.click_data);
    try std.testing.expectEqual(@as(i8, 5), finish.action);
}

pub fn clickSlot(self: *@This(), allocator: std.mem.Allocator, world: *World, action: Action) !?Item.Stack {
    if (self.drag_state != .none and action != .drag) return null;
    switch (action) {
        .throw => |throw| {
            switch (throw.count) {
                .all => {
                    self.clearSlot(allocator, throw.slot_index);
                },
                .one => if (self.getSlotPtr(throw.slot_index).*) |*item_stack| {
                    item_stack.size -= 1;
                    if (item_stack.size <= 0) self.clearSlot(allocator, throw.slot_index);
                },
            }
        },
        .drag => |drag| {
            const cursor_item = world.maybe_cursor_stack orelse {
                self.drag_state = .none;
                return null;
            };
            switch (drag) {
                .begin => |mode| {
                    // vanilla just silently drops the action on an unexpected drag state,
                    // but slot-clicking is entirely client-driven so it should never happen anyways
                    std.debug.assert(self.drag_state == .none);
                    self.drag_state = .{ .dragging = .{ .mode = mode, .slot_indices = .empty } };
                },
                .add_slot => |slot_index| {
                    std.debug.assert(self.drag_state == .dragging);
                    const dragging = &self.drag_state.dragging;

                    if (dragging.slot_indices.count() >= cursor_item.size) return null;
                    if (!self.canDragOverSlot(slot_index, self.slots[@backingInt(slot_index)], cursor_item)) return null;

                    self.drag_state.dragging.slot_indices.set(@backingInt(slot_index));
                },
                .finish => {
                    std.debug.assert(self.drag_state == .dragging);

                    const dragging = &self.drag_state.dragging;
                    // This CANNOT be an assert because the server could update our cursor item
                    // in the middle of a drag!
                    if (dragging.slot_indices.count() > cursor_item.size) return null;

                    // distribute items
                    var consumed: i32 = 0;

                    var iter = dragging.slot_indices.iterator(.{ .kind = .set });
                    while (iter.next()) |slot_index_raw| {
                        const slot_index: SlotIndex = @fromBackingInt(@intCast(slot_index_raw));

                        const maybe_stack = self.getSlotPtr(slot_index);
                        if (maybe_stack.* == null) {
                            maybe_stack.* = try Item.Stack.dupe(allocator, cursor_item);
                            maybe_stack.*.?.size = 0;
                        }
                        const stack = &maybe_stack.*.?;

                        const original_size = stack.size;

                        switch (self.drag_state.dragging.mode) {
                            .single => stack.size += 1,
                            .split => stack.size += @floor(@as(f32, @floatFromInt(cursor_item.size)) / @as(f32, @floatFromInt(dragging.slot_indices.count()))),
                            .duplicate => stack.size += 64,
                        }

                        stack.size = @min(
                            stack.size,
                            self.slots[@backingInt(slot_index)].type.maxStackSize(stack.item),
                            stack.item.maxStackSize(),
                        );

                        consumed += (stack.size - original_size);
                    }

                    world.maybe_cursor_stack.?.size -= consumed;
                    if (world.maybe_cursor_stack.?.size < 0) {
                        Item.Stack.deinit(allocator, &world.maybe_cursor_stack);
                        world.maybe_cursor_stack = null;
                    }
                },
            }
        },
        .clone => |slot_index| {
            _ = slot_index;
            std.debug.panic("TODO!", .{});
        },
        .collect => |slot_index| {
            _ = slot_index;
            std.debug.panic("TODO!", .{});
        },
        .click => |click| {
            const slot_index = click.maybe_slot_index orelse {
                // throw cursor stack
                switch (click.count) {
                    .all => {
                        world.maybe_cursor_stack = null;
                    },
                    .one_or_half => if (world.maybe_cursor_stack) |*cursor_stack| {
                        cursor_stack.size -= 1;
                        if (cursor_stack.size <= 0) world.maybe_cursor_stack = null;
                    },
                }

                return null;
            };
            const count = click.count;

            const slot = self.slots[@backingInt(slot_index)];

            const maybe_slot_stack = self.getSlotPtr(slot_index);
            const maybe_cursor_stack = &world.maybe_cursor_stack;

            // slot is empty, so just try to drop the cursor stack (if it's allowed)
            std.log.debug("slot: {?}", .{maybe_slot_stack.*});
            if (maybe_slot_stack.* == null) {
                std.log.debug("dropping into empty", .{});
                if (maybe_cursor_stack.*) |*cursor_stack| if (slot.type.isItemAllowed(cursor_stack.item)) {
                    const deposit_count = @min(
                        if (count == .all) cursor_stack.size else 1,
                        slot.type.maxStackSize(cursor_stack.item),
                    );
                    maybe_slot_stack.* = try cursor_stack.split(allocator, deposit_count);
                    if (cursor_stack.size == 0) maybe_cursor_stack.* = null;
                };
            }
            // check if we can take items from the slot before continuing
            else if (slot.canPickUp(&world.player)) {
                std.log.debug("trying to pick up", .{});

                const slot_stack = &maybe_slot_stack.*.?;
                // if cursor is empty, try to pick up the items in the slot
                if (maybe_cursor_stack.* == null) {
                    const withdrawal_count = if (count == .all) slot_stack.size else @divFloor(slot_stack.size + 1, 2);
                    // TODO: use this logic instead for correctness with crafting operations
                    // slot.removeItem(withdrawal_count);
                    maybe_cursor_stack.* = try slot_stack.split(allocator, withdrawal_count);
                    if (slot_stack.size == 0) {
                        maybe_slot_stack.* = null;
                        std.log.debug("clearing slot: {?}", .{self.getSlot(slot_index)});
                    }
                    slot.onItemRemoved();
                } else {
                    const cursor_stack = &maybe_cursor_stack.*.?;
                    // check if we can put items into the slot before continuing
                    if (slot.type.isItemAllowed(cursor_stack.item)) {
                        // if we can merge, try to merge cursor into slot
                        if (Item.Stack.canMerge(cursor_stack.*, slot_stack.*)) {
                            const deposit_count = @min(
                                if (count == .all) cursor_stack.size else 1,
                                slot.type.maxStackSize(cursor_stack.item) - slot_stack.size,
                                cursor_stack.item.maxStackSize() - slot_stack.size,
                            );
                            cursor_stack.size -= deposit_count;
                            if (cursor_stack.size == 0) maybe_cursor_stack.* = null;
                            slot_stack.size += deposit_count;
                        }
                        // otherwise, just swap them
                        else if (cursor_stack.size <= slot.type.maxStackSize(cursor_stack.item)) {
                            const tmp = cursor_stack.*;
                            cursor_stack.* = slot_stack.*;
                            slot_stack.* = tmp;
                        }
                    }
                    // this branch is very strange

                    // we only enter it if both the slot and the cursor contains stacks
                    // and the slot and the cursor's stacks are compatible,
                    // but the slot cannot accept the cursor's item type

                    // but if the slot cannot accept the cursor's item type, how
                    // did the slot's current stack get in there in the first place?

                    // answer: it's for slots that are the result of crafting operations, such as anvils,
                    // furnaces, or crafting tables
                    // (they always false on isItemAllowed, since you cannot place items *into* them)
                    // this is also why this operation is all-or-nothing
                    else if (Item.Stack.canMerge(cursor_stack.*, slot_stack.*)) {
                        const size = slot_stack.size;
                        if (size > 0 and size + cursor_stack.size <= cursor_stack.item.maxStackSize()) {
                            cursor_stack.size += size;
                            // TODO: implement this logic for this stuff
                            // slot.removeItem(slot_stack.size);
                            slot.onItemRemoved();
                        }
                    }
                }
            }
        },
        .quick_move => std.debug.panic("TODO!", .{}),
        .hotbar_swap => |hotbar_swap| {
            const slot_index = hotbar_swap.slot_index;
            const hotbar_slot = hotbar_swap.hotbar_slot;

            // vanilla silently discards the action, but slot-clicking is entirely client-driven
            // so it should never happen anyways
            std.debug.assert(hotbar_slot <= 8);
            const slot = self.slots[@backingInt(slot_index)];
            if (!slot.canPickUp(&world.player)) return null;
            const maybe_slot_stack = self.getSlot(slot_index);
            const maybe_hotbar_stack = world.main_inventory.stacks[hotbar_slot];
            var bl = maybe_hotbar_stack == null or (slot.backer == world.main_inventory and world.main_inventory.hasEmptyIndex());
            var relocate: bool = false;
            if (!bl) {
                relocate = world.main_inventory.hasEmptyIndex();
                bl |= relocate;
            }
            if (maybe_slot_stack != null and bl) {
                const slot_stack = maybe_slot_stack.?;
                world.main_inventory.stacks[hotbar_slot] = slot_stack;
                if (maybe_hotbar_stack != null and (slot.backer != world.main_inventory or !slot.type.isItemAllowed(maybe_hotbar_stack.?.item))) {
                    // otherwise we'd just be deleting items, which is definitely wrong
                    std.debug.assert(relocate);
                    // slot.removeItem()
                    // world.main_inventory.addStack(maybe_hotbar_stack.?);
                    slot.onItemRemoved();
                } else {
                    self.setSlot(allocator, slot_index, maybe_hotbar_stack);
                }
            } else if (maybe_slot_stack == null and maybe_hotbar_stack != null and slot.type.isItemAllowed(maybe_hotbar_stack.?.item)) {
                self.setSlot(allocator, slot_index, maybe_hotbar_stack);
                world.main_inventory.stacks[hotbar_slot] = null;
            }
        },
    }
    return null;
}

/// TODO: implement menu-specific logic
fn canDragOverSlot(self: *const @This(), slot_index: SlotIndex, slot: Slot, stack: Item.Stack) bool {
    if (self.getSlot(slot_index)) |existing_item| {
        return existing_item.canMerge(stack) and slot.type.isItemAllowed(stack.item);
    } else return true;
}
