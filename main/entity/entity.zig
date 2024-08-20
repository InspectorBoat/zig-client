pub const Entity = union(enum) {
    LocalPlayer: @import("impl/player/LocalPlayerEntity.zig"),
    RemotePlayer: @import("impl/player/RemotePlayerEntity.zig"),
    Boat: @import("impl/vehicle/BoatEntity.zig"),
    Cow: @import("impl/living/passive/CowEntity.zig"),

    pub fn tick(entity: @This()) !void {
        switch (entity) {
            inline else => |specific_entity| {
                specific_entity.tick();
            },
        }
    }
};
