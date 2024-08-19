const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const Direction = @import("root").Direction;

buffer: [1024 * 1024 * 2]u8 = undefined,
write_index: usize = 0,

pub fn writeRect(self: *@This(), facing: Direction, min: Vector3(f32), size: Vector2(f32)) void {
    const vertex_count = 6;
    const elements_per_vertex = 3;
    var vertices: [vertex_count * elements_per_vertex]f32 = switch (facing) {
        .Down => .{
            min.x,          min.y, min.z,
            min.x + size.x, min.y, min.z + size.z,
            min.x,          min.y, min.z + size.z,
            min.x,          min.y, min.z,
            min.x + size.x, min.y, min.z,
            min.x + size.x, min.y, min.z + size.z,
        },
        .Up => .{
            min.x,          min.y, min.z,
            min.x,          min.y, min.z + size.z,
            min.x + size.x, min.y, min.z + size.z,
            min.x,          min.y, min.z,
            min.x + size.x, min.y, min.z + size.z,
            min.x + size.x, min.y, min.z,
        },
        .North => .{
            min.x,          min.y,          min.z,
            min.x,          min.y + size.z, min.z,
            min.x + size.x, min.y + size.z, min.z,
            min.x,          min.y,          min.z,
            min.x + size.x, min.y + size.z, min.z,
            min.x + size.x, min.y,          min.z,
        },
        .South => .{
            min.x,          min.y,          min.z,
            min.x + size.x, min.y + size.z, min.z,
            min.x,          min.y + size.z, min.z,
            min.x,          min.y,          min.z,
            min.x + size.x, min.y,          min.z,
            min.x + size.x, min.y + size.z, min.z,
        },
        .East => .{
            min.x, min.y,          min.z,
            min.x, min.y + size.z, min.z + size.x,
            min.x, min.y + size.z, min.z,
            min.x, min.y,          min.z,
            min.x, min.y,          min.z + size.x,
            min.x, min.y + size.z, min.z + size.x,
        },
        .West => .{
            min.x, min.y,          min.z,
            min.x, min.y + size.z, min.z,
            min.x, min.y + size.z, min.z + size.x,
            min.x, min.y,          min.z,
            min.x, min.y + size.z, min.z + size.x,
            min.x, min.y,          min.z + size.x,
        },
    };
    const consumed_bytes = @sizeOf(@TypeOf(vertices));
    @memcpy(
        self.buffer[self.write_index..][0..consumed_bytes],
        @as([*]u8, @ptrCast((&vertices).ptr)),
    );
    self.write_index += consumed_bytes;
}

pub fn writeBox(self: *@This(), min: Vector3(f32), max: Vector3(f32)) void {
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
    );
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
    );
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
    );
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
    );
    self.writeRect(
        .East,
        .{
            .x = min.x,
            .y = min.y,
            .z = min.z,
        },
        .{
            .x = max.z - min.z,
            .z = max.y - min.y,
        },
    );
    self.writeRect(
        .West,
        .{
            .x = max.x,
            .y = min.y,
            .z = min.z,
        },
        .{
            .x = max.z - min.z,
            .z = max.y - min.y,
        },
    );
}

pub fn getSlice(self: *const @This()) []const u8 {
    return self.buffer[0..self.write_index];
}
