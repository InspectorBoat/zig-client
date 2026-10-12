const std = @import("std");
const Vector3 = @import("root").Vector3;
const Vector2xy = @import("root").Vector2xy;
const Direction = @import("root").Direction;

backer: std.ArrayList(u8),
allocator: std.mem.Allocator,

pub const TerrainVertex = packed struct {
    pos: packed struct { x: u16, y: u16, z: u16 },
    sky_light: u4,
    block_light: u4,
    shade: i8,
    _: u32 = 0,
    texture: Renderer.TextureHandle,
    uv: packed struct { u: u8, v: u8 },
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
    block_light: u4,
    sky_light: u4,
    texture: Renderer.TextureHandle,
    uv: Vector2xy(f32),
    cullface: ?Direction,
) !void {
    const quantized_uv: Vector2xy(u8) = .intFromFloat(uv);
    const vertex: TerrainVertex = .{
        .pos = .{
            .x = @round((vertex_pos.x + 8) * 2048),
            .y = @round((vertex_pos.y + 8) * 2048),
            .z = @round((vertex_pos.z + 8) * 2048),
        },
        .sky_light = sky_light,
        .block_light = block_light,
        .texture = texture,
        .shade = if (cullface) |c| @backingInt(c) else 7,
        .uv = .{ .u = quantized_uv.x, .v = quantized_uv.y },
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
