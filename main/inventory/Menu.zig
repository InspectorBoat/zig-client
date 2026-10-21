const std = @import("std");

const main = @import("main");

const Entity = main.Entity;
const Inventory = main.Inventory;
const Item = main.Item;
const ItemStack = main.ItemStack;
const World = main.World;

network_id: i32,
slots: []Slot,
drag_state: DragState = .none,

pub fn setSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: SlotIndex, new_item_stack: ?ItemStack) void {
    const slot = self.slots[@backingInt(slot_index)];

    // free old stack, if present
    ItemStack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);

    slot.backer.stacks[slot.index_into_backer] = new_item_stack;
}

pub fn getSlot(self: *const @This(), slot_index: SlotIndex) ?ItemStack {
    const slot = self.slots[@backingInt(slot_index)];

    return slot.backer.stacks[slot.index_into_backer];
}

pub fn clearSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: SlotIndex) void {
    const slot = self.slots[@backingInt(slot_index)];

    ItemStack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);
}

pub fn getSlotPtr(self: *@This(), slot_index: SlotIndex) *?ItemStack {
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

    slots.appendAssumeCapacity(.{
        .backer = crafting_result_inventory,
        .type = .crafting_result,
        .index_into_backer = 0,
    });

    for (0..4) |i| {
        slots.appendAssumeCapacity(.{
            .backer = crafting_inventory,
            .type = .generic,
            .index_into_backer = i,
        });
    }

    inline for (0..4, .{ .helmet, .chestplate, .leggings, .boots }) |i, armor_piece| {
        slots.appendAssumeCapacity(.{
            .backer = main_inventory,
            .type = armor_piece,
            .index_into_backer = main_inventory.stacks.len - 1 - i,
        });
    }

    for (1..4) |i| {
        for (0..9) |j| {
            slots.appendAssumeCapacity(.{
                .backer = main_inventory,
                .type = .generic,
                .index_into_backer = j + i * 9,
            });
        }
    }

    for (0..9) |i| {
        slots.appendAssumeCapacity(.{
            .backer = main_inventory,
            .type = .generic,
            .index_into_backer = i,
        });
    }

    return .{
        .network_id = 0,
        .slots = slots.toOwnedSliceAssert(),
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    allocator.free(self.slots);
}

pub const Slot = struct {
    type: Type,
    backer: *Inventory,
    index_into_backer: usize,

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

const SlotIndex = enum(u8) { _ };

pub const Action = union(enum) {
    /// interact with the hovered slot
    /// if the cursor slot is empty: try to pick up all or half of the items in the hovered slot
    /// if the hovered slot is empty: try to deposit the all or one of the cursor items into the hovered slot
    /// if both the cursor and the hovered slot contain items:
    ///     if the hovered slot is the result of a crafting operation, try to pick up *all* of the slot's items into the cursor
    ///     if the hovered slot's items and the cursor's items are mergable, try to deposit all or one of the cursor's items into the slot
    ///     otherwise, try to swap the cursor and the hovered slot's items
    click: struct { SlotIndex, enum { all, one_or_half } },
    /// throw the items held by the cursor out of the inventory
    /// vanilla implements this as a special slot index in `click`
    throw_cursor: enum { all, one },
    /// shift-click an item between two areas of the menu
    quick_move: SlotIndex,
    /// swap hovered slot with hotbar slot (0-8), indexed directly into the player inventory
    /// ignores slot-specific *size* restrictions
    hotbar_swap: struct { SlotIndex, u4 },
    /// clone the hovered slot into the cursor
    /// creative mode only
    clone,
    /// throw the items in the hovered slot out of the inventory
    throw: struct { SlotIndex, enum { all, one } },
    /// spread the cursor's held stack between slots
    /// there are three modes:
    ///     single - drops a single item in
    drag: union(enum) {
        begin: DragMode,
        add_slot: SlotIndex,
        finish,
    },
    /// TODO
    move_all,
};

pub const DragState = union(enum) {
    none,
    dragging: struct { mode: DragMode, slot_indices: std.bit_set.Array(u64, 256) = .empty },
};

pub const DragMode = enum { split, single, duplicate };

comptime {
    _ = &clickSlot;
}

pub fn clickSlot(self: *@This(), allocator: std.mem.Allocator, world: *World, action: Action) !?ItemStack {
    if (self.drag_state != .none and action != .drag) return null;
    switch (action) {
        .throw => |throw| {
            const slot_index, const mode = throw;
            switch (mode) {
                .all => self.clearSlot(allocator, slot_index),
                .one => if (self.getSlotPtr(slot_index).*) |*item_stack| {
                    item_stack.size -= 1;
                    if (item_stack.size <= 0) self.clearSlot(allocator, slot_index);
                },
            }
        },
        .throw_cursor => {
            // TODO
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
                            maybe_stack.* = try ItemStack.dupe(allocator, cursor_item);
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
                        ItemStack.deinit(allocator, &world.maybe_cursor_stack);
                        world.maybe_cursor_stack = null;
                    }
                },
            }
        },
        .clone => std.debug.panic("TODO!", .{}),
        .move_all => std.debug.panic("TODO!", .{}),
        .click => |click| {
            const slot_index, const mode = click;
            const slot = self.slots[@backingInt(slot_index)];

            const maybe_slot_stack = self.getSlotPtr(slot_index);
            const maybe_cursor_stack = &world.maybe_cursor_stack;

            // slot is empty, so just try to drop the cursor stack (if it's allowed)
            if (maybe_slot_stack.* == null) {
                if (maybe_cursor_stack.*) |*cursor_stack| if (slot.type.isItemAllowed(cursor_stack.item)) {
                    const deposit_count = @min(
                        if (mode == .all) cursor_stack.size else 1,
                        slot.type.maxStackSize(cursor_stack.item),
                    );
                    maybe_slot_stack.* = try cursor_stack.split(allocator, deposit_count);
                };
            }
            // check if we can take items from the slot before continuing
            else if (slot.canPickUp(&world.player)) {
                const slot_stack = &maybe_slot_stack.*.?;
                // if cursor is empty, try to pick up the items in the slot
                if (maybe_cursor_stack.* == null) {
                    const withdrawal_count = if (mode == .all) slot_stack.size else @divFloor(slot_stack.size + 1, 2);
                    // TODO: use this logic instead for correctness with crafting operations
                    // slot.removeItem(withdrawal_count);
                    maybe_cursor_stack.* = try slot_stack.split(allocator, withdrawal_count);
                    if (slot_stack.size == 0) maybe_slot_stack.* = null;
                    slot.onItemRemoved();
                } else {
                    const cursor_stack = &maybe_cursor_stack.*.?;
                    // check if we can put items into the slot before continuing
                    if (slot.type.isItemAllowed(cursor_stack.item)) {
                        // if we can merge, try to merge cursor into slot
                        if (ItemStack.canMerge(cursor_stack.*, slot_stack.*)) {
                            const deposit_count = @min(
                                if (mode == .all) cursor_stack.size else 1,
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
                    else if (ItemStack.canMerge(cursor_stack.*, slot_stack.*)) {
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
            const slot_index, const hotbar_slot = hotbar_swap;
            // vanilla silently discards the action, but slot-clicking is entirely client-driven
            // so it should never happen anyways
            std.debug.assert(hotbar_slot < 8);
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
fn canDragOverSlot(self: *const @This(), slot_index: SlotIndex, slot: Slot, stack: ItemStack) bool {
    if (self.getSlot(slot_index)) |existing_item| {
        return existing_item.canMerge(stack) and slot.type.isItemAllowed(stack.item);
    } else return true;
}
