const std = @import("std");
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Direction = @import("root").Direction;

buffer: [1024 * 1024 * 2]u8 = undefined,
write_index: usize = 0,

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

var rand_impl = std.Random.DefaultPrng.init(155215);
const rand = rand_impl.random();

pub fn writeQuad(
    self: *@This(),
    facing: Direction,
    min: Vector3(f32),
    size: Vector2(f32),
    texture: u16,
    // sky_light: u8,
    // block_light: u8,
) void {
    const quad: GpuQuad = .{
        .pos = .{
            .x = @intFromFloat(@round(min.x * 4095.9375)),
            .y = @intFromFloat(@round(min.y * 4095.9375)),
            .z = @intFromFloat(@round(min.z * 4095.9375)),
        },
        .size = .{
            .width = @intFromFloat(@max(@round(size.x * 256 - 1), 1)),
            .height = @intFromFloat(@max(@round(size.z * 256 - 1), 1)),
        },
        .texture = texture,
        .normal = @intCast(@intFromEnum(facing)),
        .sky_light = 0,
        .block_light = 0,
    };

    const consumed_bytes = @bitSizeOf(GpuQuad) / 8;
    @memcpy(
        self.buffer[self.write_index..][0..consumed_bytes],
        @as([*]const u8, @ptrCast(&quad)),
    );
    self.write_index += consumed_bytes;
}

pub fn writeBox(self: *@This(), min: Vector3(f32), max: Vector3(f32), texture: u8) void {
    self.writeBoxFaces(min, max, texture, std.EnumSet(Direction).initFull());
}

pub fn writeBoxFaces(self: *@This(), min: Vector3(f32), max: Vector3(f32), texture: u8, faces: std.EnumSet(Direction)) void {
    if (faces.contains(.Down)) {
        self.writeQuad(
            .Down,
            .{
                .x = min.x,
                .y = min.y,
                .z = min.z,
            },
            .{
                .x = max.x - min.x,
                .z = max.z - min.z,
            },
            texture,
        );
    }
    if (faces.contains(.Up)) {
        self.writeQuad(
            .Up,
            .{
                .x = min.x,
                .y = max.y,
                .z = min.z,
            },
            .{
                .x = max.x - min.x,
                .z = max.z - min.z,
            },
            texture,
        );
    }
    if (faces.contains(.North)) {
        self.writeQuad(
            .North,
            .{
                .x = min.x,
                .y = min.y,
                .z = min.z,
            },
            .{
                .x = max.x - min.x,
                .z = max.y - min.y,
            },
            texture,
        );
    }
    if (faces.contains(.South)) {
        self.writeQuad(
            .South,
            .{
                .x = min.x,
                .y = min.y,
                .z = max.z,
            },
            .{
                .x = max.x - min.x,
                .z = max.y - min.y,
            },
            texture,
        );
    }
    if (faces.contains(.West)) {
        self.writeQuad(
            .West,
            .{
                .x = min.x,
                .y = min.y,
                .z = min.z,
            },
            .{
                .x = max.z - min.z,
                .z = max.y - min.y,
            },
            texture,
        );
    }
    if (faces.contains(.East)) {
        self.writeQuad(
            .East,
            .{
                .x = max.x,
                .y = min.y,
                .z = min.z,
            },
            .{
                .x = max.z - min.z,
                .z = max.y - min.y,
            },
            texture,
        );
    }
}

pub fn getSlice(self: *const @This()) []const u8 {
    return self.buffer[0..self.write_index];
}
