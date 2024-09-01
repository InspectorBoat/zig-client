const std = @import("std");
const root = @import("root");
const Entity = root.Entity;

entities: std.AutoHashMap(*Entity, void),
entities_by_network_id: std.AutoHashMap(i32, *Entity),
pool: std.heap.MemoryPoolExtra(Entity, .{}),
entities_to_remove: std.ArrayList(*Entity),

pub fn init(allocator: std.mem.Allocator) !@This() {
    return .{
        .entities = std.AutoHashMap(*Entity, void).init(allocator),
        .entities_by_network_id = std.AutoHashMap(i32, *Entity).init(allocator),
        .entities_to_remove = std.ArrayList(*Entity).init(allocator),
        .pool = try std.heap.MemoryPoolExtra(Entity, .{}).initPreheated(allocator, 256),
    };
}
pub fn deinit(self: *@This()) void {
    self.entities.deinit();
    self.entities_by_network_id.deinit();
    self.pool.deinit();
    self.entities_to_remove.deinit();
}
pub fn addEntity(self: *@This(), entity: Entity) !*Entity {
    const new_entity: *Entity = try self.pool.create();
    new_entity.* = entity;
    const network_id = switch (entity) {
        .removed => return error.RemovedEntity,
        inline else => |specific_entity| blk: {
            @import("log").add_entity(.{ entity, specific_entity.base.pos });
            break :blk specific_entity.base.network_id;
        },
    };
    try self.entities.put(new_entity, void{});
    try self.entities_by_network_id.put(network_id, new_entity);

    return new_entity;
}

pub fn queueEntityRemoval(self: *@This(), network_id: i32) !void {
    const removed_entity = self.entities_by_network_id.fetchRemove(network_id).?.value;
    try self.entities_to_remove.append(removed_entity);
    removed_entity.* = .removed;
    self.entities_to_remove.items.len = 0;
}

pub fn processEntityRemovals(self: *@This()) void {
    for (self.entities_to_remove.items) |entity_to_remove| {
        std.debug.assert(self.entities.remove(entity_to_remove));
        self.pool.destroy(entity_to_remove);
    }
}

pub fn getEntityByNetworkId(self: *@This(), network_id: i32) ?*Entity {
    return self.entities_by_network_id.get(network_id);
}
