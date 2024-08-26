const std = @import("std");
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Direction = @import("root").Direction;

backer: std.ArrayList(u8),

pub const GpuVertex = packed struct(u64) {
    x: u16,
    y: u16,
    z: u16,
    u: u4,
    v: u4,
    texture: u8,
};

pub const GpuQuad = packed struct(u128) {
    pos: packed struct(u48) { x: u16, y: u16, z: u16 },
    size: packed struct(u16) { width: u8, height: u8 },
    normal: u16,
    texture: u16,
    sky_light: u8,
    block_light: u8,
    _: u16 = 0,
};

pub fn writeQuad(
    self: *@This(),
    facing: Direction,
    min: struct { f32, f32, f32 }, // x y z
    size: struct { f32, f32 }, // width height
    texture: u16,
    // sky_light: u8,
    // block_light: u8,
) !void {
    const quad: GpuQuad = .{
        .pos = .{
            .x = @intFromFloat(@round(min[0] * 4095.9375)),
            .y = @intFromFloat(@round(min[1] * 4095.9375)),
            .z = @intFromFloat(@round(min[2] * 4095.9375)),
        },
        .size = .{
            .width = @intFromFloat(@max(@round(size[0] * 256 - 1), 1)),
            .height = @intFromFloat(@max(@round(size[1] * 256 - 1), 1)),
        },
        .texture = texture,
        .normal = @intCast(@intFromEnum(facing)),
        .sky_light = 0,
        .block_light = 0,
    };
    try self.backer.appendSlice(std.mem.asBytes(&quad));
}

pub fn writeBox(self: *@This(), min: Vector3(f32), max: Vector3(f32), texture: u8) !void {
    try self.writeBoxFaces(min, max, texture, std.EnumSet(Direction).initFull());
}

pub fn writeBoxFaces(
    self: *@This(),
    min: Vector3(f32),
    max: Vector3(f32),
    texture: u8,
    faces: std.EnumSet(Direction),
) !void {
    if (faces.contains(.Down)) {
        try self.writeQuad(
            .Down,
            .{ min.x, min.y, min.z },
            .{ max.x - min.x, max.z - min.z },
            texture,
        );
    }
    if (faces.contains(.Up)) {
        try self.writeQuad(
            .Up,
            .{ min.x, max.y, min.z },
            .{ max.x - min.x, max.z - min.z },
            texture,
        );
    }
    if (faces.contains(.North)) {
        try self.writeQuad(
            .North,
            .{ min.x, min.y, min.z },
            .{ max.x - min.x, max.y - min.y },
            texture,
        );
    }
    if (faces.contains(.South)) {
        try self.writeQuad(
            .South,
            .{ min.x, min.y, max.z },
            .{ max.x - min.x, max.y - min.y },
            texture,
        );
    }
    if (faces.contains(.West)) {
        try self.writeQuad(
            .West,
            .{ min.x, min.y, min.z },
            .{ max.z - min.z, max.y - min.y },
            texture,
        );
    }
    if (faces.contains(.East)) {
        try self.writeQuad(
            .East,
            .{ max.x, min.y, min.z },
            .{ max.z - min.z, max.y - min.y },
            texture,
        );
    }
}
