const std = @import("std");
const Vector3 = @import("root").Vector3;
const Vector2xy = @import("root").Vector2xy;
const Direction = @import("root").Direction;

backer: std.ArrayList(u8),

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
    sky_light: u8,
    block_light: u8,
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
        .sky_light = sky_light,
        .block_light = block_light,
    };
    try self.backer.appendSlice(std.mem.asBytes(&quad));
}

pub fn writeBox(
    self: *@This(),
    min: Vector3(f32),
    max: Vector3(f32),
    texture: u8,
    sky_light: std.enums.EnumFieldStruct(Direction, u8, null),
    block_light: std.enums.EnumFieldStruct(Direction, u8, null),
) !void {
    try self.writeBoxFaces(
        min,
        max,
        texture,
        .initFull(),
        sky_light,
        block_light,
    );
}

pub fn writeBoxFaces(
    self: *@This(),
    min: Vector3(f32),
    max: Vector3(f32),
    texture: u8,
    faces: std.EnumSet(Direction),
    sky_light: std.enums.EnumFieldStruct(Direction, u8, null),
    block_light: std.enums.EnumFieldStruct(Direction, u8, null),
) !void {
    if (faces.contains(.Down)) {
        try self.writeQuad(
            .Down,
            .{ min.x, min.y, min.z },
            .{ max.x - min.x, max.z - min.z },
            texture,
            sky_light.Down,
            block_light.Down,
        );
    }
    if (faces.contains(.Up)) {
        try self.writeQuad(
            .Up,
            .{ min.x, max.y, min.z },
            .{ max.x - min.x, max.z - min.z },
            texture,
            sky_light.Up,
            block_light.Up,
        );
    }
    if (faces.contains(.North)) {
        try self.writeQuad(
            .North,
            .{ min.x, min.y, min.z },
            .{ max.x - min.x, max.y - min.y },
            texture,
            sky_light.North,
            block_light.North,
        );
    }
    if (faces.contains(.South)) {
        try self.writeQuad(
            .South,
            .{ min.x, min.y, max.z },
            .{ max.x - min.x, max.y - min.y },
            texture,
            sky_light.South,
            block_light.South,
        );
    }
    if (faces.contains(.West)) {
        try self.writeQuad(
            .West,
            .{ min.x, min.y, min.z },
            .{ max.z - min.z, max.y - min.y },
            texture,
            sky_light.West,
            block_light.West,
        );
    }
    if (faces.contains(.East)) {
        try self.writeQuad(
            .East,
            .{ max.x, min.y, min.z },
            .{ max.z - min.z, max.y - min.y },
            texture,
            sky_light.East,
            block_light.East,
        );
    }
}

pub fn writeDebugCube(self: *@This(), min: Vector3(f32), max: Vector3(f32)) !void {
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
    try self.backer.appendSlice(std.mem.asBytes(&cube));
}

pub fn write2dDebugQuad(self: *@This(), min: Vector2xy(f32), max: Vector2xy(f32)) !void {
    const quad = [_]f32{
        min.x, min.y, @bitCast(@as(u32, 0xffffffff)),
        max.x, min.y, @bitCast(@as(u32, 0xffffffff)),
        min.x, max.y, @bitCast(@as(u32, 0xffffffff)),
        max.x, max.y, @bitCast(@as(u32, 0xffffffff)),
    };
    try self.backer.appendSlice(std.mem.asBytes(&quad));
}
