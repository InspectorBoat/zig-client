const std = @import("std");

const main = @import("main");

const Inventory = @import("Inventory.zig");

const ItemStack = main.ItemStack;

network_id: i32,
slots: []Slot,
drag_state: DragState = .none,

pub fn setSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: usize, new_item_stack: ?ItemStack) void {
    const slot = self.slots[slot_index];

    // free old stack, if present
    ItemStack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);

    slot.backer.stacks[slot.index_into_backer] = new_item_stack;
}

pub fn getSlot(self: *@This(), slot_index: SlotIndex) ?ItemStack {
    const slot = self.slots[slot_index];

    return slot.backer.stacks[slot.index_into_backer];
}

pub fn clearSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: usize) void {
    const slot = self.slots[slot_index];

    ItemStack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);
}

pub fn getSlotPtr(self: *@This(), slot_index: SlotIndex) *?ItemStack {
    const slot = self.slots[slot_index];

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

    for (0..4) |i| {
        slots.appendAssumeCapacity(.{
            .backer = main_inventory,
            .type = if (i == 0) .helmet_armor else .armor,
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

    pub const Type = enum {
        generic,
        helmet_armor,
        armor,
        crafting_result,
        furnace_fuel,
        furnace_result,
        trade_result,
    };
};

const SlotIndex = usize;

pub const Action = union(enum) {
    /// Slot Index
    pick_up: SlotIndex,
    /// Slot Index
    quick_move: SlotIndex,
    /// Slot Index, hotbar index
    hotbar_swap: struct { SlotIndex, usize },
    /// Creative clone, unimplemented
    clone,
    /// Throw the items in a slot out of the inventory
    throw: struct { SlotIndex, bool },

    /// Drag between slots
    drag: union(enum) {
        begin: DragMode,
        new_slot: SlotIndex,
        finish,
    },
    /// Double click
    move_all: usize,
};

pub const DragState = union(enum) {
    none,
    dragging: struct { mode: DragMode, slot_indices: std.bit_set.Array(u32, 4) },
};

pub const DragMode = enum { split, single, duplicate };

comptime {
    _ = &clickSlot;
}

pub fn clickSlot(self: *@This(), allocator: std.mem.Allocator, action: Action) !?ItemStack {
    switch (action) {
        .throw => |throw| {
            const slot_index, const entire_stack = throw;
            if (entire_stack) {
                self.clearSlot(allocator, slot_index);
            } else {
                if (self.getSlotPtr(slot_index).*) |*item_stack| {
                    item_stack.size -= 1;
                    if (item_stack.size <= 0) self.clearSlot(allocator, slot_index);
                }
            }
        },
        .drag => |drag| {
            switch (drag) {
                .begin => |mode| {
                    std.debug.assert(self.drag_state == .none);
                    self.drag_state = .{ .dragging = .{ .mode = mode, .slot_indices = .empty } };
                },
                .new_slot => |slot_index| {
                    std.debug.assert(self.drag_state == .none);
                    self.drag_state.dragging.slot_indices.set(slot_index);
                },
                .finish => {
                    // TODO
                },
            }
        },
        .clone => std.debug.panic("TODO!", .{}),
        .move_all => std.debug.panic("TODO!", .{}),
        .pick_up => std.debug.panic("TODO!", .{}),
        .quick_move => std.debug.panic("TODO!", .{}),
        .hotbar_swap => std.debug.panic("TODO!", .{}),
    }
    return null;
}

//
//
//
//
//
//
// The following action types are in use:
// <br>0: pickup      - move a stack between the inventory and the cursor
// <br>1: quick move  - move a stack between the inventory and the hotbar
// <br>2: swap        - swap an inventory stack and a hotbar stack
// <br>3: clone       - use the pick item key on an inventory slot
// <br>4: throw       - use the drop item key on an inventory slot
// <br>5: quick craft - click-and-drag a stack over an inventory slot
// <br>6: pickup all  - double click with a stack on an inventory slot
//
//
//
//
//
//
//
// public ItemStack onClickSlot(int id, int clickData, int action, PlayerEntity player) {
//     ItemStack itemStack = null;
//     PlayerInventory playerInventory = player.inventory;
//     if (action == .drag) {
//         int prevStage = this.clickDragStage;
//         this.clickDragStage = unpackClickDragStage(clickData);
//         // ONLY VALID TRANSITION IS 1 -> 2
//         if ((prevStage != 1 || this.clickDragStage != 2) && prevStage != this.clickDragStage) {
//             this.dropClickDragging();
//         } else if (playerInventory.getCursorItem() == null) {
//             this.dropClickDragging();
//         } else if (this.clickDragStage == 0) {
//             // BEGIN
//             this.clickDragMode = unpackClickDragMode(clickData);
//             if (isValidClickDragMode(this.clickDragMode, player)) {
//                 // GO TO STAGE 1
//                 this.clickDragStage = 1;
//                 this.clickDragSlots.clear();
//             } else {
//                 this.dropClickDragging();
//             }
//         } else if (this.clickDragStage == 1) {
//             // DRAG OVER NEW SLOT
//             InventorySlot inventorySlot = this.slots.get(id);
//             if (inventorySlot != null
//                 && canClickDragInto(inventorySlot, playerInventory.getCursorItem(), true)
//                 && inventorySlot.isItemAllowed(playerInventory.getCursorItem())
//                 && playerInventory.getCursorItem().size > this.clickDragSlots.size()
//                 && this.canClickDragInto(inventorySlot)) {
//                 this.clickDragSlots.add(inventorySlot);
//             }
//         } else if (this.clickDragStage == 2) {
//             // FINISH DRAGGING, ADD ALL ITEMS
//             if (!this.clickDragSlots.isEmpty()) {
//                 ItemStack itemStack2 = playerInventory.getCursorItem().copy();
//                 int j = playerInventory.getCursorItem().size;

//                 for (InventorySlot inventorySlot2 : this.clickDragSlots) {
//                     if (inventorySlot2 != null
//                         && canClickDragInto(inventorySlot2, playerInventory.getCursorItem(), true)
//                         && inventorySlot2.isItemAllowed(playerInventory.getCursorItem())
//                         && playerInventory.getCursorItem().size >= this.clickDragSlots.size()
//                         && this.canClickDragInto(inventorySlot2)) {
//                         ItemStack itemStack3 = itemStack2.copy();
//                         int k = inventorySlot2.hasItem() ? inventorySlot2.getItem().size : 0;
//                         updateClickDragStackSize(this.clickDragSlots, this.clickDragMode, itemStack3, k);
//                         if (itemStack3.size > itemStack3.getMaxSize()) {
//                             itemStack3.size = itemStack3.getMaxSize();
//                         }

//                         if (itemStack3.size > inventorySlot2.getMaxStackSize(itemStack3)) {
//                             itemStack3.size = inventorySlot2.getMaxStackSize(itemStack3);
//                         }

//                         j -= itemStack3.size - k;
//                         inventorySlot2.setItem(itemStack3);
//                     }
//                 }

//                 itemStack2.size = j;
//                 if (itemStack2.size <= 0) {
//                     itemStack2 = null;
//                 }

//                 playerInventory.setCursorItem(itemStack2);
//             }

//             this.dropClickDragging();
//         } else {
//             this.dropClickDragging();
//         }
//     } else if (this.clickDragStage != 0) {
//         // IF WE DO SOMETHING ELSE WHILE DRAGGING, CANCEL IT
//         this.dropClickDragging();
//     } else if ((action == 0 || action == 1) && (clickData == 0 || clickData == 1)) {
//         // DROP ITEM OUT OF INVENTORY
//         if (id == -999) {
//             if (playerInventory.getCursorItem() != null) {
//                 if (clickData == 0) {
//                     player.dropItem(playerInventory.getCursorItem(), true);
//                     playerInventory.setCursorItem(null);
//                 }

//                 if (clickData == 1) {
//                     player.dropItem(playerInventory.getCursorItem().split(1), true);
//                     if (playerInventory.getCursorItem().size == 0) {
//                         playerInventory.setCursorItem(null);
//                     }
//                 }
//             }
//         } else if (action == 1) {
//             // SHIFT CLICK
//             if (id < 0) {
//                 return null;
//             }

//             InventorySlot inventorySlot3 = this.slots.get(id);
//             if (inventorySlot3 != null && inventorySlot3.canPickUp(player)) {
//                 ItemStack itemStack2 = this.quickMoveItem(player, id);
//                 if (itemStack2 != null) {
//                     Item item = itemStack2.getItem();
//                     itemStack = itemStack2.copy();
//                     if (inventorySlot3.getItem() != null && inventorySlot3.getItem().getItem() == item) {
//                         this.clickSlot(id, clickData, true, player);
//                     }
//                 }
//             }
//         } else { // PICK UP
//             if (id < 0) {
//                 return null;
//             }

//             InventorySlot inventorySlot3 = this.slots.get(id);
//             if (inventorySlot3 != null) {
//                 ItemStack itemStack2 = inventorySlot3.getItem();
//                 ItemStack itemStack4 = playerInventory.getCursorItem();
//                 if (itemStack2 != null) {
//                     itemStack = itemStack2.copy();
//                 }

//                 if (itemStack2 == null) {
//                     if (itemStack4 != null && inventorySlot3.isItemAllowed(itemStack4)) {
//                         int l = clickData == 0 ? itemStack4.size : 1;
//                         if (l > inventorySlot3.getMaxStackSize(itemStack4)) {
//                             l = inventorySlot3.getMaxStackSize(itemStack4);
//                         }

//                         if (itemStack4.size >= l) {
//                             inventorySlot3.setItem(itemStack4.split(l));
//                         }

//                         if (itemStack4.size == 0) {
//                             playerInventory.setCursorItem(null);
//                         }
//                     }
//                 } else if (inventorySlot3.canPickUp(player)) {
//                     if (itemStack4 == null) {
//                         int l = clickData == 0 ? itemStack2.size : (itemStack2.size + 1) / 2;
//                         ItemStack itemStack5 = inventorySlot3.removeItem(l);
//                         playerInventory.setCursorItem(itemStack5);
//                         if (itemStack2.size == 0) {
//                             inventorySlot3.setItem(null);
//                         }

//                         inventorySlot3.onItemRemoved(player, playerInventory.getCursorItem());
//                     } else if (inventorySlot3.isItemAllowed(itemStack4)) {
//                         if (itemStack2.getItem() == itemStack4.getItem() && itemStack2.getMetadata() == itemStack4.getMetadata() && ItemStack.matchesNbt(itemStack2, itemStack4)
//                             )
//                             {
//                             int l = clickData == 0 ? itemStack4.size : 1;
//                             if (l > inventorySlot3.getMaxStackSize(itemStack4) - itemStack2.size) {
//                                 l = inventorySlot3.getMaxStackSize(itemStack4) - itemStack2.size;
//                             }

//                             if (l > itemStack4.getMaxSize() - itemStack2.size) {
//                                 l = itemStack4.getMaxSize() - itemStack2.size;
//                             }

//                             itemStack4.split(l);
//                             if (itemStack4.size == 0) {
//                                 playerInventory.setCursorItem(null);
//                             }

//                             itemStack2.size += l;
//                         } else if (itemStack4.size <= inventorySlot3.getMaxStackSize(itemStack4)) {
//                             inventorySlot3.setItem(itemStack4);
//                             playerInventory.setCursorItem(itemStack2);
//                         }
//                     } else if (itemStack2.getItem() == itemStack4.getItem()
//                         && itemStack4.getMaxSize() > 1
//                         && (!itemStack2.hasCustomData() || itemStack2.getMetadata() == itemStack4.getMetadata())
//                         && ItemStack.matchesNbt(itemStack2, itemStack4)) {
//                         int l = itemStack2.size;
//                         if (l > 0 && l + itemStack4.size <= itemStack4.getMaxSize()) {
//                             itemStack4.size += l;
//                             itemStack2 = inventorySlot3.removeItem(l);
//                             if (itemStack2.size == 0) {
//                                 inventorySlot3.setItem(null);
//                             }

//                             inventorySlot3.onItemRemoved(player, playerInventory.getCursorItem());
//                         }
//                     }
//                 }

//                 inventorySlot3.markDirty();
//             }
//         }
//     } else if (action == 2 && clickData >= 0 && clickData < 9) {
//         // HOTBAR SWAP
//         InventorySlot inventorySlot3 = this.slots.get(id);
//         if (inventorySlot3.canPickUp(player)) {
//             ItemStack itemStack2 = playerInventory.getItem(clickData);
//             boolean bl = itemStack2 == null || inventorySlot3.inventory == playerInventory && inventorySlot3.isItemAllowed(itemStack2);
//             int l = -1;
//             if (!bl) {
//                 l = playerInventory.getEmptySlot();
//                 bl |= l > -1;
//             }

//             if (inventorySlot3.hasItem() && bl) {
//                 ItemStack itemStack5 = inventorySlot3.getItem();
//                 playerInventory.setItem(clickData, itemStack5.copy());
//                 if ((inventorySlot3.inventory != playerInventory || !inventorySlot3.isItemAllowed(itemStack2)) && itemStack2 != null) {
//                     if (l > -1) {
//                         playerInventory.addItem(itemStack2);
//                         inventorySlot3.removeItem(itemStack5.size);
//                         inventorySlot3.setItem(null);
//                         inventorySlot3.onItemRemoved(player, itemStack5);
//                     }
//                 } else {
//                     inventorySlot3.removeItem(itemStack5.size);
//                     inventorySlot3.setItem(itemStack2);
//                     inventorySlot3.onItemRemoved(player, itemStack5);
//                 }
//             } else if (!inventorySlot3.hasItem() && itemStack2 != null && inventorySlot3.isItemAllowed(itemStack2)) {
//                 playerInventory.setItem(clickData, null);
//                 inventorySlot3.setItem(itemStack2);
//             }
//         }
//     } else if (action == 3 && player.abilities.creativeMode && playerInventory.getCursorItem() == null && id >= 0) {
//         InventorySlot inventorySlot3 = this.slots.get(id);
//         if (inventorySlot3 != null && inventorySlot3.hasItem()) {
//             ItemStack itemStack2 = inventorySlot3.getItem().copy();
//             itemStack2.size = itemStack2.getMaxSize();
//             playerInventory.setCursorItem(itemStack2);
//         }
//     } else if (action == 4 && playerInventory.getCursorItem() == null && id >= 0) {
//         // DROP ITEM
//         InventorySlot inventorySlot3 = this.slots.get(id);
//         if (inventorySlot3 != null && inventorySlot3.hasItem() && inventorySlot3.canPickUp(player)) {
//             ItemStack itemStack2 = inventorySlot3.removeItem(clickData == 0 ? 1 : inventorySlot3.getItem().size);
//             inventorySlot3.onItemRemoved(player, itemStack2);
//             player.dropItem(itemStack2, true);
//         }
//     } else if (action == 6 && id >= 0) {
//         // DOUBLE CLICK
//         InventorySlot inventorySlot3 = this.slots.get(id);
//         ItemStack itemStack2 = playerInventory.getCursorItem();
//         if (itemStack2 != null && (inventorySlot3 == null || !inventorySlot3.hasItem() || !inventorySlot3.canPickUp(player))) {
//             int j = clickData == 0 ? 0 : this.slots.size() - 1;
//             int l = clickData == 0 ? 1 : -1;

//             for (int m = 0; m < 2; m++) {
//                 for (int n = j; n >= 0 && n < this.slots.size() && itemStack2.size < itemStack2.getMaxSize(); n += l) {
//                     InventorySlot inventorySlot4 = this.slots.get(n);
//                     if (inventorySlot4.hasItem()
//                         && canClickDragInto(inventorySlot4, itemStack2, true)
//                         && inventorySlot4.canPickUp(player)
//                         && this.canRemoveForPickupAll(itemStack2, inventorySlot4)
//                         && (m != 0 || inventorySlot4.getItem().size != inventorySlot4.getItem().getMaxSize())) {
//                         int o = Math.min(itemStack2.getMaxSize() - itemStack2.size, inventorySlot4.getItem().size);
//                         ItemStack itemStack6 = inventorySlot4.removeItem(o);
//                         itemStack2.size += o;
//                         if (itemStack6.size <= 0) {
//                             inventorySlot4.setItem(null);
//                         }

//                         inventorySlot4.onItemRemoved(player, itemStack6);
//                     }
//                 }
//             }
//         }

//         this.updateListeners();
//     }

//     return itemStack;
// }
