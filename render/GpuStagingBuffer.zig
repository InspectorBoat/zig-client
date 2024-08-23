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

var rand_impl = std.Random.DefaultPrng.init(155215);
const rand = rand_impl.random();

pub fn writeVertex(self: *@This(), pos: struct { f32, f32, f32 }, uv: struct { u4, u4 }, texture: u8) void {
    // {x/y/z} have the interval [0.0, 16.0]
    var vertex: GpuVertex = .{
        .x = @intFromFloat(@round(pos[0] * 4095.9375)),
        .y = @intFromFloat(@round(pos[1] * 4095.9375)),
        .z = @intFromFloat(@round(pos[2] * 4095.9375)),
        .u = uv[0],
        .v = uv[1],
        .texture = texture,
    };

    const consumed_bytes = @bitSizeOf(GpuVertex) / 8;
    @memcpy(
        self.buffer[self.write_index..][0..consumed_bytes],
        @as([*]const u8, @ptrCast(&vertex)),
    );
    self.write_index += consumed_bytes;
}

pub fn writeRect(self: *@This(), comptime facing: Direction, min: Vector3(f32), size: Vector2(f32), texture: u8) void {
    switch (facing) {
        // zig fmt: off
        .Down => {
            self.writeVertex(.{ min.x,          min.y, min.z          }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y, min.z          }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x,          min.y, min.z + size.z }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y, min.z + size.z }, .{ 15, 15 }, texture);
        },
        .Up => {
            self.writeVertex(.{ min.x,          min.y, min.z          }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x,          min.y, min.z + size.z }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y, min.z          }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y, min.z + size.z }, .{ 15, 15 }, texture);
        },
        .North => {
            self.writeVertex(.{ min.x,          min.y,          min.z }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x,          min.y + size.z, min.z }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y,          min.z }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y + size.z, min.z }, .{ 15, 15 }, texture);
        },
        .South => {
            self.writeVertex(.{ min.x,          min.y,          min.z }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y,          min.z }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x,          min.y + size.z, min.z }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x + size.x, min.y + size.z, min.z }, .{ 15, 15 }, texture);
        },
        .West => {
            self.writeVertex(.{ min.x, min.y,          min.z          }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x, min.y,          min.z + size.x }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x, min.y + size.z, min.z          }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x, min.y + size.z, min.z + size.x }, .{ 15, 15 }, texture);
        },
        .East => {
            self.writeVertex(.{ min.x, min.y,          min.z,         }, .{  0,  0 }, texture);
            self.writeVertex(.{ min.x, min.y + size.z, min.z,         }, .{ 15,  0 }, texture);
            self.writeVertex(.{ min.x, min.y,          min.z + size.x }, .{  0, 15 }, texture);
            self.writeVertex(.{ min.x, min.y + size.z, min.z + size.x }, .{ 15, 15 }, texture);
        },
        // zig fmt: on
    }
}

pub fn writeBox(self: *@This(), min: Vector3(f32), max: Vector3(f32), texture: u8) void {
    self.writeBoxFaces(min, max, texture, std.EnumSet(Direction).initFull());
}

pub fn writeBoxFaces(self: *@This(), min: Vector3(f32), max: Vector3(f32), texture: u8, faces: std.EnumSet(Direction)) void {
    if (faces.contains(.Down)) {
        self.writeRect(
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
        self.writeRect(
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
        self.writeRect(
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
        self.writeRect(
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
        self.writeRect(
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
        self.writeRect(
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
