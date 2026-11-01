planes: [6]Plane,

pub const Plane = struct {
    normal: Vector3(f32),
    d: f32,
};

pub fn fromMatrix(matrix: Mat4) @This() {
    const row0: [4]f32 = .{ matrix.data[0][0], matrix.data[1][0], matrix.data[2][0], matrix.data[3][0] };
    const row1: [4]f32 = .{ matrix.data[0][1], matrix.data[1][1], matrix.data[2][1], matrix.data[3][1] };
    const row2: [4]f32 = .{ matrix.data[0][2], matrix.data[1][2], matrix.data[2][2], matrix.data[3][2] };
    const row3: [4]f32 = .{ matrix.data[0][3], matrix.data[1][3], matrix.data[2][3], matrix.data[3][3] };

    return .{ .planes = .{
        fromRows(row3, row0, 1),
        fromRows(row3, row0, -1),
        fromRows(row3, row1, 1),
        fromRows(row3, row1, -1),
        fromRows(row3, row2, 1),
        fromRows(row3, row2, -1),
    } };
}

pub fn fromRows(a: [4]f32, b: [4]f32, scale: f32) Plane {
    return .{
        .normal = .{
            .x = a[0] + b[0] * scale,
            .y = a[1] + b[1] * scale,
            .z = a[2] + b[2] * scale,
        },
        .d = a[3] + b[3] * scale,
    };
}

pub fn intersectsAabb(self: @This(), min: Vector3(f32), max: Vector3(f32)) bool {
    for (self.planes) |plane| {
        const positive: Vector3(f32) = .{
            .x = if (plane.normal.x >= 0) max.x else min.x,
            .y = if (plane.normal.y >= 0) max.y else min.y,
            .z = if (plane.normal.z >= 0) max.z else min.z,
        };
        const distance = plane.normal.x * positive.x + plane.normal.y * positive.y + plane.normal.z * positive.z + plane.d;
        if (distance < 0) return false;
    }
    return true;
}

const main = @import("main");
const za = @import("zalgebra");

const Vector3 = main.Vector3;
const Mat4 = za.Mat4;
