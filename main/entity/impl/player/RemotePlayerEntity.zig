const EntityBase = @import("../EntityBase.zig");
const PlayerInventory = @import("../../inventory/PlayerInventory.zig");
const LivingEntityBase = @import("../living/LivingEntityBase.zig");
const PlayerEntityBase = @import("PlayerEntityBase.zig");

base: EntityBase,
living: LivingEntityBase = .{},
player: PlayerEntityBase = .{},
