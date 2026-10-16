const std = @import("std");

const main = @import("main");

const Entity = main.Entity;

entities: std.AutoHashMap(*Entity, void),
entities_by_network_id: std.AutoHashMap(i32, *Entity),
pool: std.heap.MemoryPool(Entity),
entities_to_remove: std.ArrayList(*Entity),
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !@This() {
    return .{
        .entities = .init(allocator),
        .entities_by_network_id = .init(allocator),
        .entities_to_remove = .empty,
        .pool = try .initCapacity(allocator, 256),
        .allocator = allocator,
    };
}
pub fn deinit(self: *@This()) void {
    self.entities.deinit();
    self.entities_by_network_id.deinit();
    self.pool.deinit(self.allocator);
    self.entities_to_remove.deinit(self.allocator);
}
// TODO: Forced entities, insert into chunk
pub fn addEntity(self: *@This(), entity: Entity) !*Entity {
    const new_entity: *Entity = try self.pool.create(self.allocator);
    new_entity.* = entity;
    const network_id = switch (entity) {
        .removed => return error.RemovedEntity,
        inline else => |specific_entity| blk: {
            std.log.scoped(.entity).debug("added entity {any} at {any}", .{ entity, specific_entity.base.pos });
            break :blk specific_entity.base.network_id;
        },
    };
    try self.entities.put(new_entity, {});
    try self.entities_by_network_id.put(network_id, new_entity);

    return new_entity;
}

pub fn queueEntityRemoval(self: *@This(), network_id: i32) !void {
    const removed_entity = (self.entities_by_network_id.fetchRemove(network_id) orelse {
        std.log.scoped(.entity).warn("tried to remove missing entity with network id {}", .{network_id});
        return;
    }).value;
    try self.entities_to_remove.append(self.allocator, removed_entity);
    std.log.scoped(.entity).debug("removed entity {any}", .{removed_entity.*});
    removed_entity.* = .removed;
}

pub fn processEntityRemovals(self: *@This()) void {
    for (self.entities_to_remove.items) |entity_to_remove| {
        std.debug.assert(self.entities.remove(entity_to_remove));
        self.pool.destroy(entity_to_remove);
    }
    self.entities_to_remove.items.len = 0;
}

pub fn getEntityByNetworkId(self: *@This(), network_id: i32) ?*Entity {
    return self.entities_by_network_id.get(network_id);
}
