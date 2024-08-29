const std = @import("std");

const Uuid = @import("util").Uuid;

uuid: ?Uuid = null,
name: ?[]const u8 = null,
properties: ?std.StringHashMapUnmanaged(Property) = null,

pub const Property = struct {
    name: []const u8,
    value: []const u8,
    signature: ?[]const u8,
};
