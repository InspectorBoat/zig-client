const std = @import("std");

const main = @import("main");

const ItemStack = main.ItemStack;
const Inventory = @import("Inventory.zig");

network_id: i32,
slots: []Slot,

pub fn setSlot(self: *@This(), allocator: std.mem.Allocator, slot_index: usize, new_item_stack: ?ItemStack) void {
    const slot = self.slots[slot_index];

    // free old stack, if present
    ItemStack.deinit(allocator, &slot.backer.stacks[slot.index_into_backer]);

    if (new_item_stack) |n| {
        std.log.debug("setting {} in slot {}", .{ n.item, slot.index_into_backer });
    }

    slot.backer.stacks[slot.index_into_backer] = new_item_stack;
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
    pub const Type = enum {
        generic,
        helmet_armor,
        armor,
        crafting_result,
        furnace_fuel,
        furnace_result,
        trade_result,
    };
    type: Type,
    backer: *Inventory,
    index_into_backer: usize,
};
