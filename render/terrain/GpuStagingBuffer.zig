const std = @import("std");
const Vector3 = @import("root").Vector3;
const Vector2xy = @import("root").Vector2xy;
const Direction = @import("root").Direction;

backer: std.ArrayList(u8),
allocator: std.mem.Allocator,

pub const TerrainVertex = extern struct {
    pos: extern struct { x: f32, y: f32, z: f32 },
    texture: Renderer.TextureHandle, // uvs unimplemented for now
    light: u8, // sky << 4 | block
    _: u8 = 0,
};

pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !@This() {
    return .{
        .backer = try .initCapacity(allocator, num),
        .allocator = allocator,
    };
}

pub fn writeVertex(
    self: *@This(),
    vertex_pos: Vector3(f32),
    block_light: u8,
    sky_light: u8,
    texture: Renderer.TextureHandle,
) !void {
    const vertex: TerrainVertex = .{
        .pos = .{ .x = vertex_pos.x, .y = vertex_pos.y, .z = vertex_pos.z },
        .texture = texture,
        .light = sky_light << 4 | block_light,
    };
    try self.backer.appendSlice(self.allocator, std.mem.asBytes(&vertex));
}

const Renderer = @import("../Renderer.zig");

pub fn writeDebugCube(self: *@This(), min: Vector3(f32), max: Vector3(f32)) !void {
    @setRuntimeSafety(false);

    const cube = [_]f32{
        min.x, min.y, min.z,
        max.x, min.y, min.z,
        min.x, min.y, max.z,
        max.x, min.y, max.z,

        min.x, max.y, min.z,
        max.x, max.y, min.z,
        min.x, max.y, max.z,
        max.x, max.y, max.z,

        min.x, min.y, min.z,
        min.x, max.y, min.z,
        min.x, min.y, max.z,
        min.x, max.y, max.z,

        max.x, min.y, min.z,
        max.x, max.y, min.z,
        max.x, min.y, max.z,
        max.x, max.y, max.z,

        min.x, min.y, min.z,
        min.x, max.y, min.z,
        max.x, min.y, min.z,
        max.x, max.y, min.z,

        min.x, min.y, max.z,
        min.x, max.y, max.z,
        max.x, min.y, max.z,
        max.x, max.y, max.z,
    };
    try self.backer.appendSlice(self.allocator, std.mem.asBytes(&cube));
}

pub fn write2dDebugQuad(self: *@This(), min: Vector2xy(f32), max: Vector2xy(f32)) !void {
    @setRuntimeSafety(false);

    const quad = [_]f32{
        min.x, min.y, @bitCast(@as(u32, 0xffffffff)),
        max.x, min.y, @bitCast(@as(u32, 0xffffffff)),
        min.x, max.y, @bitCast(@as(u32, 0xffffffff)),
        max.x, max.y, @bitCast(@as(u32, 0xffffffff)),
    };
    try self.backer.appendSlice(self.allocator, std.mem.asBytes(&quad));
}
