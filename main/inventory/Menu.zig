type: Type,
network_id: i32,
slots: []Slot,
drag_state: DragState = .none,
next_transaction_id: i16 = 0,
owned_inventories: []*Inventory = &.{},
data: [9]i32 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
crafting_grid: ?*Inventory = null,

pub const Type = union(enum) {
    player,
    crafting_table,
    chest,
    hopper,
    anvil,
    brewing_stand,
    horse,
    dropper,
    dispenser,
    furnace,
    enchanting_table,
    beacon,
    villager,
    creative_inventory,
};

pub const DragState = union(enum) {
    none,
    dragging: struct { mode: Action.Drag.Mode, slot_indices: std.bit_set.Array(u64, 256) = .empty },
};

pub const SlotIndex = enum(u8) { _ };

pub const ArmorType = enum(std.meta.Tag(SlotIndex)) {
    helmet = 5,
    chestplate = 6,
    leggings = 7,
    boots = 8,
};

pub const Slot = struct {
    type: Slot.Type,
    backer: *Inventory,
    index_into_backer: u8,

    pub fn canPickUp(self: @This(), player: *const Entity.LocalPlayer, menu: *const Menu, slot_index: SlotIndex) bool {
        switch (self.type) {
            .anvil_result => {
                const cost = menu.data[0];
                return (player.abilities.creative_mode or player.xp_level >= cost) and
                    cost > 0 and
                    menu.getSlot(slot_index) != null;
            },
            else => return true,
        }
    }

    pub fn onItemRemoved(self: @This()) void {
        _ = self;
        // Bookkeeping is handled by Menu.onItemRemoved, which has the world context.
    }

    pub const Type = union(enum) {
        generic,
        armor: ArmorType,
        crafting_result,
        furnace_input,
        furnace_fuel,
        furnace_result,
        trade_result,
        beacon_payment,
        brewing_ingredient,
        brewing_potion,
        creative_inventory,
        anvil_input,
        anvil_result,
        enchanting_item,
        enchanting_lapis,
        horse_saddle,
        horse_armor,

        fn isResult(self: @This()) bool {
            return switch (self) {
                .crafting_result, .furnace_result, .trade_result, .anvil_result => true,
                else => false,
            };
        }

        pub fn isItemAllowed(self: @This(), stack: Item.Stack) bool {
            const item = stack.item;
            return switch (self) {
                .armor => |armor| item.armorSlot() == armor,
                .furnace_fuel => item.isFuel() or item == .bucket,
                .beacon_payment => item == .emerald or item == .diamond or item == .gold_ingot or item == .iron_ingot,
                .brewing_ingredient => item.isPotionIngredient(),
                .brewing_potion => item == .potion or item == .glass_bottle,
                .enchanting_item => true,
                .enchanting_lapis => item == .dye and stack.metadata == 4,
                .horse_saddle => item == .saddle,
                .horse_armor => item == .iron_horse_armor or item == .golden_horse_armor or item == .diamond_horse_armor,
                .crafting_result, .furnace_result, .trade_result, .anvil_result => false,
                else => true,
            };
        }

        pub fn maxStackSize(self: @This(), item: Item) i32 {
            return switch (self) {
                .armor, .beacon_payment, .brewing_potion, .enchanting_item, .horse_saddle, .horse_armor => 1,
                .furnace_fuel => if (item == .bucket) 1 else 64,
                else => 64,
            };
        }
    };
};

pub const Action = union(Action.Type) {
    /// interact with the hovered slot
    /// if the slot index is null:
    ///     throw (all or one) of the items held by the cursor out of the inventory
    /// if the cursor slot is empty: try to pick up (all or half) of the items in the hovered slot
    /// if the hovered slot is empty: try to deposit the (all or one) of the cursor items into the hovered slot
    /// if both the cursor and the hovered slot contain items:
    ///     if the hovered slot is the result of a crafting operation, try to pick up (all) of the slot's items into the cursor
    ///     if the hovered slot's items and the cursor's items are mergable, try to deposit (all or one) of the cursor's items into the slot
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

    pub fn performOn(self: @This(), allocator: std.mem.Allocator, world: *World, menu: *Menu) !?Item.Stack {
        // clears an in-progress drag when any other action arrives.
        if (menu.drag_state != .none and self != .drag) menu.drag_state = .none;
        switch (self) {
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

                const slot = menu.slots[@backingInt(slot_index)];

                // The *pre-click* contents of the slot
                var predicted: ?Item.Stack = null;
                if (menu.getSlot(slot_index)) |slot_stack| {
                    predicted = try .dupe(allocator, slot_stack);
                }

                const maybe_slot_stack = menu.getSlotPtr(slot_index);
                const maybe_cursor_stack = &world.maybe_cursor_stack;

                // slot is empty, so just try to drop the cursor stack (if it's allowed)
                if (maybe_slot_stack.* == null) predicted = null;
                if (maybe_slot_stack.* == null) {
                    if (maybe_cursor_stack.*) |*cursor_stack| if (slot.type.isItemAllowed(cursor_stack.*)) {
                        const deposit_count = @min(
                            if (count == .all) cursor_stack.size else 1,
                            slot.type.maxStackSize(cursor_stack.item),
                            cursor_stack.item.maxStackSize(),
                        );
                        maybe_slot_stack.* = try cursor_stack.split(allocator, deposit_count);
                        if (cursor_stack.size == 0) maybe_cursor_stack.* = null;
                    };
                }
                // check if we can take items from the slot before continuing
                else if (slot.canPickUp(&world.player, menu, slot_index)) {
                    const slot_stack = &maybe_slot_stack.*.?;
                    // if cursor is empty, try to pick up the items in the slot
                    if (maybe_cursor_stack.* == null) {
                        // Result inventories ignore the requested amount in vanilla.
                        const whole_stack = count == .all or (slot.type.isResult() and slot.type != .furnace_result);
                        const withdrawal_count = if (whole_stack) slot_stack.size else @divCeil(slot_stack.size, 2);
                        // TODO: use this logic instead for correctness with crafting operations
                        // slot.removeItem(withdrawal_count);
                        maybe_cursor_stack.* = try slot_stack.split(allocator, withdrawal_count);
                        if (slot_stack.size == 0) {
                            maybe_slot_stack.* = null;
                        }
                        menu.onItemRemoved(allocator, world, slot_index);
                    } else {
                        const cursor_stack = &maybe_cursor_stack.*.?;
                        // check if we can put items into the slot before continuing
                        if (slot.type.isItemAllowed(cursor_stack.*)) {
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
                        // This branch is only reached when the stacks match but the slot
                        // refused the deposit above because isItemAllowed returned false.
                        // This branch is intended for output slots, as their item was made
                        // by the recipe, not placed there by the player. This is also why
                        // this operation is all-or-nothing, since you can't perform half a
                        // recipe
                        else if (Item.Stack.canMerge(cursor_stack.*, slot_stack.*) and
                            cursor_stack.item.maxStackSize() > 1)
                        {
                            const size = slot_stack.size;
                            if (size > 0 and size + cursor_stack.size <= cursor_stack.item.maxStackSize()) {
                                cursor_stack.size += size;
                                menu.clearSlot(allocator, slot_index);
                                menu.onItemRemoved(allocator, world, slot_index);
                            }
                        }
                    }
                }
                return predicted;
            },
            .quick_move => |quick_move| {
                return try quickMove(allocator, quick_move, world, menu);
            },
            .hotbar_swap => |hotbar_swap| {
                const slot_index = hotbar_swap.slot_index;
                const hotbar_slot = hotbar_swap.hotbar_slot;

                // vanilla silently discards the action, but slot-clicking is entirely client-driven
                // so it should never happen anyways
                std.debug.assert(hotbar_slot <= 8);

                const slot = menu.slots[@backingInt(slot_index)];
                if (!slot.canPickUp(&world.player, menu, slot_index)) return null;

                const maybe_slot_stack = menu.getSlot(slot_index);
                const maybe_hotbar_stack = world.main_inventory.stacks[hotbar_slot];

                if (maybe_slot_stack) |slot_stack| {
                    // We can directly swap if the hotbar is empty, or if the hovered slot
                    // belongs to the main inventory and accepts the hotbar item.
                    const hotbar_stack_fits_hovered_slot = maybe_hotbar_stack == null or
                        (slot.backer == world.main_inventory and slot.type.isItemAllowed(maybe_hotbar_stack.?));

                    if (hotbar_stack_fits_hovered_slot) {
                        // swap stacks directly, without freeing
                        world.main_inventory.stacks[hotbar_slot] = slot_stack;
                        slot.backer.stacks[slot.index_into_backer] = maybe_hotbar_stack;
                    } else if (world.main_inventory.hasEmptyIndex()) {
                        world.main_inventory.stacks[hotbar_slot] = slot_stack;
                        // hotbar stack needs to be relocated
                        // TODO: add hotbar_stack to the main inventory, currently we just drop it which is incorrect
                        // slot.removeItem()
                        // world.main_inventory.addStack(maybe_hotbar_stack.?);
                        slot.onItemRemoved();
                    }
                } else if (maybe_hotbar_stack) |hotbar_stack| {
                    // the hovered slot is empty, so just try to move the hotbar stack in
                    if (slot.type.isItemAllowed(hotbar_stack)) {
                        menu.setSlot(allocator, slot_index, maybe_hotbar_stack);
                        world.main_inventory.stacks[hotbar_slot] = null;
                    }
                }
            },
            .clone => |clone| {
                // Middle-click / pick-block: creative only, requires an empty cursor.
                if (!world.player.abilities.creative_mode or world.maybe_cursor_stack != null) return null;
                const slot_stack = menu.getSlot(clone.slot_index) orelse return null;
                var new_stack = (try Item.Stack.dupe(allocator, slot_stack)).?;
                new_stack.size = new_stack.item.maxStackSize();
                world.maybe_cursor_stack = new_stack;
            },
            .throw => |throw| {
                const slot = menu.slots[@backingInt(throw.slot_index)];
                if (!slot.canPickUp(&world.player, menu, throw.slot_index)) return null;
                switch (throw.count) {
                    .all => {
                        menu.clearSlot(allocator, throw.slot_index);
                    },
                    .one => if (menu.getSlotPtr(throw.slot_index).*) |*item_stack| {
                        item_stack.size -= 1;
                        if (item_stack.size <= 0) menu.clearSlot(allocator, throw.slot_index);
                    },
                }
                menu.onItemRemoved(allocator, world, throw.slot_index);
            },
            .drag => |drag| {
                const cursor_item = world.maybe_cursor_stack orelse {
                    menu.drag_state = .none;
                    return null;
                };
                switch (drag) {
                    .begin => |mode| {
                        // Vanilla silently drops a drag begin in an unexpected state.
                        if (menu.drag_state != .none) return null;
                        menu.drag_state = .{ .dragging = .{ .mode = mode, .slot_indices = .empty } };
                    },
                    .add_slot => |slot_index| {
                        if (menu.drag_state != .dragging) return null;
                        const dragging = &menu.drag_state.dragging;

                        if (dragging.slot_indices.count() >= cursor_item.size) return null;
                        if (!canDragOverSlot(menu, slot_index, menu.slots[@backingInt(slot_index)], cursor_item)) return null;

                        menu.drag_state.dragging.slot_indices.set(@backingInt(slot_index));
                    },
                    .finish => {
                        if (menu.drag_state != .dragging) return null;

                        const dragging = &menu.drag_state.dragging;
                        // This CANNOT be an assert because the server could update our cursor item
                        // in the middle of a drag!
                        if (dragging.slot_indices.count() > cursor_item.size) return null;

                        // distribute items
                        var consumed: i32 = 0;

                        var iter = dragging.slot_indices.iterator(.{ .kind = .set });
                        while (iter.next()) |slot_index_raw| {
                            const slot_index: SlotIndex = @fromBackingInt(@intCast(slot_index_raw));
                            const slot = menu.slots[@backingInt(slot_index)];
                            // Vanilla revalidates each slot at stage 2: the cursor may
                            // have been changed authoritatively during the gesture.
                            if (!canDragOverSlot(menu, slot_index, slot, cursor_item)) continue;

                            const maybe_stack = menu.getSlotPtr(slot_index);
                            if (maybe_stack.* == null) {
                                maybe_stack.* = try Item.Stack.dupe(allocator, cursor_item);
                                maybe_stack.*.?.size = 0;
                            }
                            const stack = &maybe_stack.*.?;

                            const original_size = stack.size;

                            switch (menu.drag_state.dragging.mode) {
                                .single => stack.size += 1,
                                .split => stack.size += @divFloor(cursor_item.size, @as(i32, @intCast(dragging.slot_indices.count()))),
                                .duplicate => stack.size += if (world.player.abilities.creative_mode) stack.item.maxStackSize() else 1,
                            }

                            stack.size = @min(
                                stack.size,
                                menu.slots[@backingInt(slot_index)].type.maxStackSize(stack.item),
                                stack.item.maxStackSize(),
                            );

                            consumed += (stack.size - original_size);
                        }

                        world.maybe_cursor_stack.?.size -= consumed;
                        if (world.maybe_cursor_stack.?.size <= 0) {
                            Item.Stack.deinit(allocator, &world.maybe_cursor_stack);
                            world.maybe_cursor_stack = null;
                        }
                        // Finishing a drag clears the gesture; without this, every
                        // subsequent non-drag action is silently ignored.
                        menu.drag_state = .none;
                    },
                }
            },
            .collect => |collect| {
                const cursor_stack = &world.maybe_cursor_stack;
                const cursor = cursor_stack.* orelse return null;
                const hovered_stack = menu.getSlot(collect.slot_index);
                if (hovered_stack != null) return null;

                // Player and crafting-table menus exclude their result slots.
                const excludes_result = menu.type == .player or menu.type == .crafting_table;
                var pass: usize = 0;
                while (pass < 2) : (pass += 1) {
                    for (menu.slots, 0..) |slot, i| {
                        if (excludes_result and slot.type.isResult()) continue;
                        const slot_index: SlotIndex = @fromBackingInt(@intCast(i));
                        const stack = menu.getSlotPtr(slot_index);
                        if (stack.* == null) continue;
                        const existing = &stack.*.?;
                        if (!canDragOverSlot(menu, slot_index, slot, cursor)) continue;
                        if (pass == 0 and existing.size == existing.item.maxStackSize()) continue;
                        const room = cursor.item.maxStackSize() - cursor_stack.*.?.size;
                        if (room <= 0) return null;
                        const taken = @min(room, existing.size);
                        world.maybe_cursor_stack.?.size += taken;
                        existing.size -= taken;
                        if (existing.size == 0) stack.* = null;
                        menu.onItemRemoved(allocator, world, slot_index);
                    }
                }
            },
        }
        return null;
    }

    fn quickMove(allocator: std.mem.Allocator, quick_move: QuickMove, world: *World, menu: *Menu) !?Item.Stack {
        const index: usize = @backingInt(quick_move.slot_index);
        const slot = menu.slots[index];
        if (!slot.canPickUp(&world.player, menu, quick_move.slot_index)) return null;
        const moved_stack = menu.getSlotPtr(quick_move.slot_index);
        var original = moved_stack.* orelse return null;
        const initial_stack = (try Item.Stack.dupe(allocator, original)).?;
        const item = original.item;

        var from: usize = 0;
        var to: usize = 0;
        var moved = false;

        switch (menu.type) {
            .player, .creative_inventory => {
                switch (index) {
                    0 => {
                        from = 44;
                        to = 9;
                    },
                    1...8 => {
                        from = 9;
                        to = 44;
                    },
                    9...35 => {
                        from = 36;
                        to = 44;
                    },
                    36...44 => {
                        from = 9;
                        to = 35;
                    },
                    else => unreachable,
                }
                // Vanilla auto-equips armor from any other slot into an empty armor slot.
                if (menu.type == .player and ((index >= 1 and index <= 4) or index >= 9)) {
                    if (item.armorSlot()) |armor| {
                        const armor_index = @backingInt(armor);
                        if (menu.getSlot(@fromBackingInt(armor_index)) == null) {
                            from = armor_index;
                            to = armor_index;
                        }
                    }
                }
            },
            .chest, .hopper, .dispenser, .dropper => {
                const n = menu.slots.len - 36;
                if (index < n) {
                    from = n;
                    to = n + 35;
                } else {
                    from = 0;
                    to = n -| 1;
                }
            },
            .crafting_table => switch (index) {
                0 => {
                    from = 45;
                    to = 10;
                },
                1...9 => {
                    from = 10;
                    to = 45;
                },
                10...36 => {
                    from = 37;
                    to = 45;
                },
                37...45 => {
                    from = 10;
                    to = 36;
                },
                else => return null,
            },
            .furnace => switch (index) {
                2 => {
                    from = 38;
                    to = 3;
                },
                0, 1 => {
                    from = 3;
                    to = 38;
                },
                3...29, 30...38 => {
                    if (item.isSmeltable(original.metadata)) {
                        from = 0;
                        to = 0;
                    } else if (item.isFuel() or item == .bucket) {
                        from = 1;
                        to = 1;
                    } else if (index < 30) {
                        from = 30;
                        to = 38;
                    } else {
                        from = 3;
                        to = 29;
                    }
                },
                else => return null,
            },
            .anvil => switch (index) {
                2 => {
                    from = 38;
                    to = 3;
                },
                0, 1 => {
                    from = 3;
                    to = 38;
                },
                3...38 => {
                    from = 0;
                    to = 1;
                },
                else => return null,
            },
            .enchanting_table => switch (index) {
                0, 1 => {
                    from = 37;
                    to = 2;
                },
                2...37 => {
                    if (item == .dye and original.metadata == 4) {
                        // Vanilla merges blue dye into slot 1 (reverse range 2 -> 1).
                        from = 1;
                        to = 1;
                    } else if (menu.getSlot(@fromBackingInt(0)) == null) {
                        // Vanilla inserts one item; NBT is stripped for multi-item stacks.
                        const single: Item.Stack = .{
                            .nbt = if (original.size == 1) original.nbt else null,
                            .item = item,
                            .size = 1,
                            .metadata = original.metadata,
                        };
                        menu.getSlotPtr(@fromBackingInt(0)).* = try Item.Stack.dupe(allocator, single);
                        original.size -= 1;
                        moved_stack.* = if (original.size > 0) original else null;
                        moved = true;
                    } else if (index < 29) {
                        from = 29;
                        to = 37;
                    } else {
                        from = 2;
                        to = 28;
                    }
                },
                else => return null,
            },
            .brewing_stand => switch (index) {
                0...3 => {
                    from = 39;
                    to = 4;
                },
                4...39 => {
                    if (menu.getSlot(@fromBackingInt(3)) == null and item.isPotionIngredient()) {
                        from = 3;
                        to = 3;
                    } else if (slot.type.isItemAllowed(original) and (item == .potion or item == .glass_bottle)) {
                        from = 0;
                        to = 2;
                    } else if (index < 31) {
                        from = 31;
                        to = 39;
                    } else {
                        from = 4;
                        to = 30;
                    }
                },
                else => return null,
            },
            .beacon => switch (index) {
                0 => {
                    from = 36;
                    to = 1;
                },
                1...36 => {
                    if (menu.getSlot(@fromBackingInt(0)) == null and
                        slot.type.isItemAllowed(original) and original.size == 1)
                    {
                        from = 0;
                        to = 0;
                    } else if (index < 28) {
                        from = 28;
                        to = 36;
                    } else {
                        from = 1;
                        to = 27;
                    }
                },
                else => return null,
            },
            .horse => {
                var horse_count: usize = 0;
                for (menu.slots) |candidate| {
                    if (candidate.backer.type == .horse) horse_count += 1;
                }
                if (index < horse_count) {
                    from = menu.slots.len - 1;
                    to = horse_count;
                } else if (std.mem.endsWith(u8, @tagName(item), "_horse_armor") and
                    menu.getSlot(@fromBackingInt(1)) == null)
                {
                    from = 1;
                    to = 1;
                } else if (item == .saddle and menu.getSlot(@fromBackingInt(0)) == null) {
                    from = 0;
                    to = 0;
                } else if (horse_count > 2) {
                    from = 2;
                    to = horse_count - 1;
                } else {
                    return null; // no chest: vanilla makes no move
                }
            },
            .villager => switch (index) {
                2 => {
                    from = 38;
                    to = 3;
                },
                0, 1 => {
                    from = 3;
                    to = 38;
                },
                3...29 => {
                    from = 30;
                    to = 38;
                },
                30...38 => {
                    from = 3;
                    to = 29;
                },
                else => return null,
            },
        }

        if (!moved) try moveIntoRange(allocator, &moved_stack.*.?, menu, @fromBackingInt(@intCast(from)), @fromBackingInt(@intCast(to)));
        if (moved_stack.* == null or moved_stack.*.?.size == 0) menu.setSlot(allocator, quick_move.slot_index, null);

        // Only run the result-slot hook when the move actually succeeded
        if (slot.type.isResult() and (moved_stack.* == null or moved_stack.*.?.size != initial_stack.size)) {
            menu.onItemRemoved(allocator, world, quick_move.slot_index);
        }
        if (moved_stack.*) |remaining| {
            if (remaining.size == initial_stack.size) return null;
        }
        return initial_stack;
    }

    /// from...to is INCLUSIVE and `from` can be greater than `to`,
    /// in which case this function will iterate backwards
    fn moveIntoRange(allocator: std.mem.Allocator, stack: *Item.Stack, menu: *Menu, from: SlotIndex, to: SlotIndex) !void {
        const range: i32 = @backingInt(to) - @backingInt(from);
        if (stack.item.maxStackSize() > 1) {
            for (0..@abs(range) + 1) |i| {
                const offset: i32 = @as(i32, @intCast(i)) * std.math.sign(range);
                const slot = menu.slots[@intCast(@backingInt(from) + offset)];
                if (slot.backer.stacks[slot.index_into_backer]) |*slot_stack| {
                    if (!slot.type.isItemAllowed(stack.*) or !slot_stack.canMerge(stack.*)) continue;
                    // we need to make sure this behavior is correct even for
                    // negative stack sizes and overstacked items.
                    // if we didn't, we could write it simply as such:

                    // const deposit_count: i32 = @min(stack.size, slot_stack.item.maxStackSize() - slot_stack.size);
                    // stack.size -= deposit_count;
                    // slot_stack.size += deposit_count;
                    const max_stack_size = @min(slot_stack.item.maxStackSize(), slot.type.maxStackSize(stack.item));
                    if (slot_stack.size + stack.size <= max_stack_size) {
                        slot_stack.size += stack.size;
                        stack.size = 0;
                        return;
                    } else if (slot_stack.size < max_stack_size) {
                        stack.size -= max_stack_size - slot_stack.size;
                        slot_stack.size = max_stack_size;
                        if (stack.size == 0) return;
                    }
                }
            }
        }
        for (0..@abs(range) + 1) |i| {
            const offset: i32 = @as(i32, @intCast(i)) * std.math.sign(range);
            const slot = menu.slots[@intCast(@backingInt(from) + offset)];

            if (slot.backer.stacks[slot.index_into_backer] == null and slot.type.isItemAllowed(stack.*)) {
                var deposited = (try Item.Stack.dupe(allocator, stack.*)).?;
                deposited.size = @min(deposited.size, slot.type.maxStackSize(deposited.item), deposited.item.maxStackSize());
                stack.size -= deposited.size;
                slot.backer.stacks[slot.index_into_backer] = deposited;
                if (stack.size == 0) return;
            }
        }
    }

    /// TODO: implement menu-specific logic
    fn canDragOverSlot(menu: *const Menu, slot_index: SlotIndex, slot: Slot, stack: Item.Stack) bool {
        if (menu.getSlot(slot_index)) |existing_item| {
            return existing_item.canMerge(stack) and slot.type.isItemAllowed(stack);
        }
        return slot.type.isItemAllowed(stack);
    }

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
                        else => if (menu.drag_state == .dragging) menu.drag_state.dragging.mode else .split,
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

        test convert {
            var slots: [0]Slot = .{};
            var menu: Menu = .{ .type = .player, .network_id = 0, .slots = &slots };
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
    };
};

/// Client-side eligibility check from EnchantingTableMenu.onButtonClick.
pub fn canClickEnchantButton(self: *const @This(), player: *const Entity.LocalPlayer, button: usize) bool {
    if (self.type != .enchanting_table or button >= 3) return false;
    const item = self.getSlot(@fromBackingInt(0));
    const lapis = self.getSlot(@fromBackingInt(1));
    const needed_lapis: i32 = @intCast(button + 1);
    if ((lapis == null or lapis.?.size < needed_lapis) and !player.abilities.creative_mode) return false;
    const cost = self.data[button];
    return cost > 0 and item != null and
        ((player.xp_level >= needed_lapis and player.xp_level >= cost) or player.abilities.creative_mode);
}

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

/// Consumes the inputs behind a result slot when its output is taken
pub fn onItemRemoved(self: *@This(), allocator: std.mem.Allocator, world: *World, slot_index: SlotIndex) void {
    const slot = self.slots[@backingInt(slot_index)];
    switch (slot.type) {
        .crafting_result => {
            const grid = self.crafting_grid orelse world.crafting_inventory;
            for (grid.stacks) |*grid_stack| {
                if (grid_stack.* == null) continue;
                const stack = &grid_stack.*.?;
                const stack_item = stack.item;
                const remainder: ?Item = switch (stack_item) {
                    .water_bucket, .lava_bucket, .milk_bucket => .bucket,
                    else => null,
                };
                if (stack.size > 1) {
                    stack.size -= 1;
                    // Add the remainder to the player inventory if the
                    // grid slot is still occupied.
                    if (remainder) |item| {
                        for (world.main_inventory.stacks[0..36]) |*target| {
                            if (target.* == null) {
                                target.* = .{ .nbt = null, .item = item, .size = 1, .metadata = 0 };
                                break;
                            }
                        }
                    }
                } else {
                    Item.Stack.deinit(allocator, grid_stack);
                    grid_stack.* = null;
                    if (remainder) |item| {
                        grid_stack.* = .{ .nbt = null, .item = item, .size = 1, .metadata = 0 };
                    }
                }
            }
        },
        // The furnace input was already consumed when the item finished cooking.
        .furnace_result => {},
        .anvil_result => {
            self.clearSlot(allocator, @fromBackingInt(0));
            consumeOne(self, allocator, 1);
            self.data[0] = 0;
        },
        .trade_result => {
            consumeOne(self, allocator, 0);
            consumeOne(self, allocator, 1);
        },
        else => {},
    }
}

fn consumeOne(menu: *@This(), allocator: std.mem.Allocator, slot_index: usize) void {
    const target = menu.getSlotPtr(@fromBackingInt(@intCast(slot_index)));
    if (target.* == null) return;
    const stack = &target.*.?;
    if (stack.size > 1) {
        stack.size -= 1;
    } else {
        Item.Stack.deinit(allocator, target);
        target.* = null;
    }
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
    for (0..4, std.enums.values(ArmorType)) |i, armor| {
        slots.appendAssumeCapacity(.{
            .backer = main_inventory,
            .type = .{ .armor = armor },
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

pub fn initChestMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory, slot_count: usize) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const chest_inventory = try ownedInventory(allocator, &owned, .chest, slot_count);
    const rows = @divFloor(slot_count, 9);
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
        .owned_inventories = try owned.toOwnedSlice(allocator),
        .type = .chest,
    };
}

pub fn initHopperMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory, slot_count: usize) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const hopper_inventory = try ownedInventory(allocator, &owned, .hopper, slot_count);
    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, slot_count + 36);

    for (0..slot_count) |i| {
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
        .owned_inventories = try owned.toOwnedSlice(allocator),
        .type = .hopper,
    };
}

pub fn initDispenserMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory, slot_count: usize) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const dispenser_inventory = try ownedInventory(allocator, &owned, .dispenser, @min(slot_count, 9));
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
        .owned_inventories = try owned.toOwnedSlice(allocator),
        .type = .dispenser,
    };
}

fn ownedInventory(allocator: std.mem.Allocator, owned: *std.ArrayList(*Inventory), @"type": Inventory.Type, count: usize) !*Inventory {
    const inventory: *Inventory = try .init(allocator, @"type", count);
    try owned.append(allocator, inventory);
    return inventory;
}

pub fn initCraftingTableMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const grid = try ownedInventory(allocator, &owned, .crafting_table, 9);
    const result = try ownedInventory(allocator, &owned, .crafting_result, 1);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 46);
    slots.appendAssumeCapacity(.{ .type = .crafting_result, .backer = result, .index_into_backer = 0 });
    for (0..9) |i| slots.appendAssumeCapacity(.{ .type = .generic, .backer = grid, .index_into_backer = @intCast(i) });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .crafting_table,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
        .crafting_grid = grid,
    };
}

pub fn initFurnaceMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .furnace, 3);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 39);
    slots.appendAssumeCapacity(.{ .type = .furnace_input, .backer = inventory, .index_into_backer = 0 });
    slots.appendAssumeCapacity(.{ .type = .furnace_fuel, .backer = inventory, .index_into_backer = 1 });
    slots.appendAssumeCapacity(.{ .type = .furnace_result, .backer = inventory, .index_into_backer = 2 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .furnace,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initAnvilMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .anvil, 3);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 39);
    slots.appendAssumeCapacity(.{ .type = .anvil_input, .backer = inventory, .index_into_backer = 0 });
    slots.appendAssumeCapacity(.{ .type = .anvil_input, .backer = inventory, .index_into_backer = 1 });
    slots.appendAssumeCapacity(.{ .type = .anvil_result, .backer = inventory, .index_into_backer = 2 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .anvil,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initEnchantingMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .enchanting, 2);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 38);
    slots.appendAssumeCapacity(.{ .type = .enchanting_item, .backer = inventory, .index_into_backer = 0 });
    slots.appendAssumeCapacity(.{ .type = .enchanting_lapis, .backer = inventory, .index_into_backer = 1 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .enchanting_table,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initBrewingMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .brewing_stand, 4);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 40);
    for (0..3) |i| slots.appendAssumeCapacity(.{ .type = .brewing_potion, .backer = inventory, .index_into_backer = @intCast(i) });
    slots.appendAssumeCapacity(.{ .type = .brewing_ingredient, .backer = inventory, .index_into_backer = 3 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .brewing_stand,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initBeaconMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .beacon, 1);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 37);
    slots.appendAssumeCapacity(.{ .type = .beacon_payment, .backer = inventory, .index_into_backer = 0 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .beacon,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initHorseMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory, rows: usize) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .horse, 2 + rows * 5);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 2 + rows * 5 + 36);
    slots.appendAssumeCapacity(.{ .type = .horse_saddle, .backer = inventory, .index_into_backer = 0 });
    slots.appendAssumeCapacity(.{ .type = .horse_armor, .backer = inventory, .index_into_backer = 1 });
    for (0..rows * 5) |i| slots.appendAssumeCapacity(.{ .type = .generic, .backer = inventory, .index_into_backer = @intCast(i + 2) });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .horse,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initTraderMenu(allocator: std.mem.Allocator, network_id: i32, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const inventory = try ownedInventory(allocator, &owned, .villager, 3);

    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 39);
    slots.appendAssumeCapacity(.{ .type = .generic, .backer = inventory, .index_into_backer = 0 });
    slots.appendAssumeCapacity(.{ .type = .generic, .backer = inventory, .index_into_backer = 1 });
    slots.appendAssumeCapacity(.{ .type = .trade_result, .backer = inventory, .index_into_backer = 2 });
    appendPlayerSlots(&slots, player_inventory);
    return .{
        .type = .villager,
        .network_id = network_id,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
    };
}

pub fn initCreativeMenu(allocator: std.mem.Allocator, player_inventory: *Inventory) !@This() {
    var owned: std.ArrayList(*Inventory) = .empty;
    const grid = try ownedInventory(allocator, &owned, .creative, 45);

    // Until a creative tab/item-list UI exists, expose the first items by id so
    // the creative inventory is at least usable for acquiring items.
    const item_info = @typeInfo(Item).@"enum";
    inline for (0..@min(45, item_info.field_names.len)) |i| {
        grid.stacks[i] = .{
            .nbt = null,
            .item = @fromBackingInt(@intCast(item_info.field_values[i])),
            .size = 1,
            .metadata = 0,
        };
    }
    var slots: std.ArrayList(Slot) = try .initCapacity(allocator, 54);
    for (0..45) |i| slots.appendAssumeCapacity(.{ .type = .creative_inventory, .backer = grid, .index_into_backer = @intCast(i) });
    for (0..9) |i| slots.appendAssumeCapacity(.{ .type = .generic, .backer = player_inventory, .index_into_backer = @intCast(i) });
    return .{
        .type = .creative_inventory,
        .network_id = 0,
        .slots = slots.toOwnedSliceAssert(),
        .owned_inventories = try owned.toOwnedSlice(allocator),
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
    for (self.owned_inventories) |inventory| inventory.deinit(allocator);
    allocator.free(self.owned_inventories);
    allocator.free(self.slots);
}

test {
    _ = Action.WireFormat;
    _ = Slot.Type;
    _ = Slot.Type;
}

test "slot restrictions" {
    const stone: Item.Stack = .{ .nbt = null, .item = .stone, .size = 1, .metadata = 0 };
    const result_slots: [3]Slot.Type = .{ .crafting_result, .furnace_result, .anvil_result };
    for (result_slots) |slot| try std.testing.expect(!slot.isItemAllowed(stone));

    const helmet_slot: Slot.Type = .{ .armor = .helmet };
    try std.testing.expect(helmet_slot.isItemAllowed(.{ .nbt = null, .item = .diamond_helmet, .size = 1, .metadata = 0 }));
    try std.testing.expect(!helmet_slot.isItemAllowed(.{ .nbt = null, .item = .diamond_boots, .size = 1, .metadata = 0 }));
    try std.testing.expectEqual(1, helmet_slot.maxStackSize(.diamond_helmet));

    const fuel_slot: Slot.Type = .furnace_fuel;
    try std.testing.expect(fuel_slot.isItemAllowed(.{ .nbt = null, .item = .planks, .size = 1, .metadata = 0 }));
    try std.testing.expect(fuel_slot.isItemAllowed(.{ .nbt = null, .item = .crafting_table, .size = 1, .metadata = 0 }));
    try std.testing.expect(fuel_slot.isItemAllowed(.{ .nbt = null, .item = .bucket, .size = 1, .metadata = 0 }));
    try std.testing.expect(!fuel_slot.isItemAllowed(.{ .nbt = null, .item = .water_bucket, .size = 1, .metadata = 0 }));
    try std.testing.expect(fuel_slot.isItemAllowed(.{ .nbt = null, .item = .lava_bucket, .size = 1, .metadata = 0 }));
    try std.testing.expect(fuel_slot.isItemAllowed(.{ .nbt = null, .item = .coal, .size = 1, .metadata = 0 }));
    const payment_slot: Slot.Type = .beacon_payment;
    try std.testing.expect(payment_slot.isItemAllowed(.{ .nbt = null, .item = .emerald, .size = 1, .metadata = 0 }));
    try std.testing.expect(!payment_slot.isItemAllowed(stone));
    const potion_slot: Slot.Type = .brewing_potion;
    try std.testing.expect(potion_slot.isItemAllowed(.{ .nbt = null, .item = .potion, .size = 1, .metadata = 0 }));
    try std.testing.expect(!potion_slot.isItemAllowed(stone));
}

test "menu layouts" {
    const gpa = std.testing.allocator;
    var player = try Inventory.init(gpa, .player, 40);
    defer player.deinit(gpa);

    const layouts = [_]struct {
        menu: Menu,
        expected_slots: usize,
        expected_owned: usize,
    }{
        .{ .menu = try initCraftingTableMenu(gpa, 1, player), .expected_slots = 46, .expected_owned = 2 },
        .{ .menu = try initFurnaceMenu(gpa, 2, player), .expected_slots = 39, .expected_owned = 1 },
        .{ .menu = try initAnvilMenu(gpa, 3, player), .expected_slots = 39, .expected_owned = 1 },
        .{ .menu = try initEnchantingMenu(gpa, 4, player), .expected_slots = 38, .expected_owned = 1 },
        .{ .menu = try initBrewingMenu(gpa, 5, player), .expected_slots = 40, .expected_owned = 1 },
        .{ .menu = try initBeaconMenu(gpa, 6, player), .expected_slots = 37, .expected_owned = 1 },
        .{ .menu = try initHorseMenu(gpa, 7, player, 3), .expected_slots = 53, .expected_owned = 1 },
        .{ .menu = try initTraderMenu(gpa, 8, player), .expected_slots = 39, .expected_owned = 1 },
        .{ .menu = try initChestMenu(gpa, 9, player, 27), .expected_slots = 63, .expected_owned = 1 },
        .{ .menu = try initHopperMenu(gpa, 10, player, 5), .expected_slots = 41, .expected_owned = 1 },
        .{ .menu = try initDispenserMenu(gpa, 11, player, 9), .expected_slots = 45, .expected_owned = 1 },
        .{ .menu = try initCreativeMenu(gpa, player), .expected_slots = 54, .expected_owned = 1 },
    };
    for (layouts) |layout| {
        var menu = layout.menu;
        defer menu.deinit(gpa);
        try std.testing.expectEqual(layout.expected_slots, menu.slots.len);
        try std.testing.expectEqual(layout.expected_owned, menu.owned_inventories.len);
        // The last 36 slots must always be the player's main inventory and hotbar
        // (the creative screen only exposes the 9 hotbar slots).
        if (menu.type != .creative_inventory) {
            for (menu.slots[menu.slots.len - 36 ..]) |slot| {
                try std.testing.expect(slot.backer == player);
            }
        }
    }
}

const std = @import("std");

const main = @import("main");

const Menu = @This();
const Entity = main.Entity;
const Inventory = main.Inventory;
const Item = main.Item;
const World = main.World;
