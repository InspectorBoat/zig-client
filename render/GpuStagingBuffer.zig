const Vector3 = @import("common").Vector3;

buffer: [1024 * 1024 * 2]u8 = undefined,
write_index: usize = 0,

pub fn writeCube(self: *@This(), pos: Vector3(i32)) void {
    const vertex_count = 36;
    const elements_per_vertex = 3;
    var vertices: [vertex_count * elements_per_vertex]f32 = .{
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000,
        0.000, 1.000, 1.000,
        1.000, 1.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        1.000, 0.000, 1.000,
        0.000, 0.000, 0.000,
        1.000, 0.000, 0.000,
        1.000, 1.000, 0.000,
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 1.000, 1.000,
        0.000, 1.000, 0.000,
        1.000, 0.000, 1.000,
        0.000, 0.000, 1.000,
        0.000, 0.000, 0.000,
        0.000, 1.000, 1.000,
        0.000, 0.000, 1.000,
        1.000, 0.000, 1.000,
        1.000, 1.000, 1.000,
        1.000, 0.000, 0.000,
        1.000, 1.000, 0.000,
        1.000, 0.000, 0.000,
        1.000, 1.000, 1.000,
        1.000, 0.000, 1.000,
        1.000, 1.000, 1.000,
        1.000, 1.000, 0.000,
        0.000, 1.000, 0.000,
        1.000, 1.000, 1.000,
        0.000, 1.000, 0.000,
        0.000, 1.000, 1.000,
        1.000, 1.000, 1.000,
        0.000, 1.000, 1.000,
        1.000, 0.000, 1.000,
    };

    for (0..vertex_count) |i| {
        vertices[i * elements_per_vertex + 0] += @floatFromInt(pos.x);
        vertices[i * elements_per_vertex + 1] += @floatFromInt(pos.y);
        vertices[i * elements_per_vertex + 2] += @floatFromInt(pos.z);
    }

    @memcpy(
        self.buffer[self.write_index..][0..@sizeOf(@TypeOf(vertices))],
        @as([*]u8, @ptrCast((&vertices).ptr)),
    );
    self.write_index += @sizeOf(@TypeOf(vertices));
}

pub fn writeBox(self: *@This(), min: Vector3(f32), max: Vector3(f32)) void {
    const vertex_count = 36;
    const elements_per_vertex = 3;
    var vertices: [vertex_count * elements_per_vertex]f32 = .{
        min.x, min.y, min.z,
        min.x, min.y, max.z,
        min.x, max.y, max.z,
        max.x, max.y, min.z,
        min.x, min.y, min.z,
        min.x, max.y, min.z,
        max.x, min.y, max.z,
        min.x, min.y, min.z,
        max.x, min.y, min.z,
        max.x, max.y, min.z,
        max.x, min.y, min.z,
        min.x, min.y, min.z,
        min.x, min.y, min.z,
        min.x, max.y, max.z,
        min.x, max.y, min.z,
        max.x, min.y, max.z,
        min.x, min.y, max.z,
        min.x, min.y, min.z,
        min.x, max.y, max.z,
        min.x, min.y, max.z,
        max.x, min.y, max.z,
        max.x, max.y, max.z,
        max.x, min.y, min.z,
        max.x, max.y, min.z,
        max.x, min.y, min.z,
        max.x, max.y, max.z,
        max.x, min.y, max.z,
        max.x, max.y, max.z,
        max.x, max.y, min.z,
        min.x, max.y, min.z,
        max.x, max.y, max.z,
        min.x, max.y, min.z,
        min.x, max.y, max.z,
        max.x, max.y, max.z,
        min.x, max.y, max.z,
        max.x, min.y, max.z,
    };

    @memcpy(
        self.buffer[self.write_index..][0..@sizeOf(@TypeOf(vertices))],
        @as([*]u8, @ptrCast((&vertices).ptr)),
    );
    self.write_index += @sizeOf(@TypeOf(vertices));
}

pub fn getSlice(self: *const @This()) []const u8 {
    return self.buffer[0..self.write_index];
}
