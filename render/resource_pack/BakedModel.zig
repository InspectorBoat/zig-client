const ResolvedBlockModel = @import("ResolvedBlockModel.zig");
const Vector3 = @import("root").Vector3;
const Vector2xy = @import("root").Vector2xy;
const Renderer = @import("../Renderer.zig");
const za = @import("zalgebra");
const Direction = @import("root").Direction;
const std = @import("std");
const StateToModelMap = @import("StateToModelMap.zig");

faces: []const Face,

const Face = struct {
    pos: [4]Vector3(f32),
    uv: [4]Vector2xy(f32),
    texture: Renderer.TextureHandle,
    cullface: ?Direction,
};

pub fn bake(gpa: std.mem.Allocator, model: ResolvedBlockModel, y_rotation: StateToModelMap.ModelVariant.Angle) !@This() {
    var face_count: usize = 0;
    for (model.elements) |element| {
        inline for (Direction.names) |dir| {
            face_count += @intFromBool(@field(element.faces, dir) != null);
        }
    }

    var faces: std.ArrayList(Face) = try .initCapacity(gpa, face_count);

    for (model.elements) |element| {
        bakeElement(&faces, rotateElementY(element, y_rotation));
    }
    return .{ .faces = faces.toOwnedSliceAssert() };
}

/// Rotates the element around the y axis
pub fn rotateElementY(element: ResolvedBlockModel.Element, angle: StateToModelMap.ModelVariant.Angle) ResolvedBlockModel.Element {
    var element_mut = element;
    for (0..@backingInt(angle)) |_| {
        const from_delta: Vector3(f32) = .sub(element_mut.from, .splat(8));
        const new_from_delta: Vector3(f32) = .{ .x = -from_delta.z, .y = from_delta.y, .z = from_delta.x };
        const new_from: Vector3(f32) = .add(new_from_delta, .splat(8));

        const to_delta: Vector3(f32) = .sub(element_mut.to, .splat(8));
        const new_to_delta: Vector3(f32) = .{ .x = -to_delta.z, .y = to_delta.y, .z = to_delta.x };
        const new_to: Vector3(f32) = .add(new_to_delta, .splat(8));

        const new_rotation: ?ResolvedBlockModel.Element.Rotation = if (element_mut.rotation) |rotation| blk: {
            const rotation_origin_delta: Vector3(f32) = .sub(rotation.origin, .splat(8));
            const new_rotation_origin_delta: Vector3(f32) = .{ .x = -rotation_origin_delta.z, .y = rotation_origin_delta.y, .z = rotation_origin_delta.x };
            const new_rotation_origin: Vector3(f32) = .add(new_rotation_origin_delta, .splat(8));
            break :blk .{
                .origin = new_rotation_origin,
                .axis = switch (rotation.axis) {
                    .x => .z,
                    .z => .x,
                    .y => .y,
                },
                .angle = rotation.angle,
                .rescale = rotation.rescale,
            };
        } else null;

        const new_faces: ResolvedBlockModel.Element.Faces = .{
            .west = element_mut.faces.north,
            .north = element_mut.faces.east,
            .east = element_mut.faces.south,
            .south = element_mut.faces.west,
            .up = element_mut.faces.up,
            .down = element_mut.faces.down,
        };

        element_mut = .{
            // needed to fix winding orders
            .from = .{ .x = new_from.x, .y = new_from.y, .z = new_to.z },
            .to = .{ .x = new_to.x, .y = new_to.y, .z = new_from.z },
            .faces = new_faces,
            .rotation = new_rotation,
            .shade = element_mut.shade,
        };
    }

    // this is correct, but i'm not sure why
    if (angle == .@"90" or angle == .@"180") {
        if (element_mut.rotation) |*rotation| {
            rotation.angle = switch (rotation.angle) {
                .@"-45" => .@"45",
                .@"-22.5" => .@"22.5",
                .@"0" => .@"0",
                .@"22.5" => .@"-22.5",
                .@"45" => .@"-45",
            };
        }
    }

    return element_mut;
}

pub fn bakeElement(baked_faces: *std.ArrayList(Face), element: ResolvedBlockModel.Element) void {
    const anchor = transformAnchor(element.rotation, element.from);
    const basis = getBasis(element.rotation);
    const size: Vector3(f32) = .sub(element.to, element.from);

    const scaled_anchor: Vector3(f32) = anchor.scaleUniform(1.0 / 16.0);
    const scaled_basis: Vector3(Vector3(f32)) = .{
        .x = basis.x.scaleUniform(size.x).scaleUniform(1.0 / 16.0),
        .y = basis.y.scaleUniform(size.y).scaleUniform(1.0 / 16.0),
        .z = basis.z.scaleUniform(size.z).scaleUniform(1.0 / 16.0),
    };

    // zig fmt: off
    const @"000" = scaled_anchor                                                            ;
    const @"001" = scaled_anchor                                        .add(scaled_basis.z);
    const @"010" = scaled_anchor                    .add(scaled_basis.y)                    ;
    const @"011" = scaled_anchor                    .add(scaled_basis.y).add(scaled_basis.z);
    const @"100" = scaled_anchor.add(scaled_basis.x)                                        ;
    const @"101" = scaled_anchor.add(scaled_basis.x)                    .add(scaled_basis.z);
    const @"110" = scaled_anchor.add(scaled_basis.x).add(scaled_basis.y)                    ;
    const @"111" = scaled_anchor.add(scaled_basis.x).add(scaled_basis.y).add(scaled_basis.z);

    if (element.faces.west)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"000", @"001", @"011", @"010" }, face));
    if (element.faces.south) |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"001", @"101", @"111", @"011" }, face));
    if (element.faces.east)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"101", @"100", @"110", @"111" }, face));
    if (element.faces.north) |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"100", @"000", @"010", @"110" }, face));
    if (element.faces.up)    |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"011", @"111", @"110", @"010" }, face));
    if (element.faces.down)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"000", @"100", @"101", @"001" }, face));
    // zig fmt: on
}

pub fn transformAnchor(maybe_rotation: ?ResolvedBlockModel.Element.Rotation, anchor: Vector3(f32)) Vector3(f32) {
    const rotation = maybe_rotation orelse return anchor;

    const rotation_axis: za.Vec3_f64 = rotationAxis(rotation.axis);
    const rotation_angle: f64 = rotationAngle(rotation.angle);
    const rescale = rescaleFactor(rotation);
    const rotation_matrix: za.Mat3_f64 = .fromRotation(rotation_angle, rotation_axis);

    const delta_to_origin = anchor.sub(rotation.origin);

    const rotated_delta = rotation_matrix.mulByVec3(.new(delta_to_origin.x, delta_to_origin.y, delta_to_origin.z));

    const new_anchor = (Vector3(f64){ .x = rotated_delta.x(), .y = rotated_delta.y(), .z = rotated_delta.z() })
        .floatCast(f32)
        .scale(.{
            .x = if (rotation.axis != .x) rescale else 1,
            .y = if (rotation.axis != .y) rescale else 1,
            .z = if (rotation.axis != .z) rescale else 1,
        })
        .add(rotation.origin);
    return new_anchor;
}

/// Linear algebra is my passion
pub fn getBasis(maybe_rotation: ?ResolvedBlockModel.Element.Rotation) Vector3(Vector3(f32)) {
    const rotation = maybe_rotation orelse return .{
        .x = .{ .x = 1, .y = 0, .z = 0 },
        .y = .{ .x = 0, .y = 1, .z = 0 },
        .z = .{ .x = 0, .y = 0, .z = 1 },
    };
    const rotation_axis: za.Vec3_f64 = rotationAxis(rotation.axis);
    const rotation_angle: f64 = rotationAngle(rotation.angle);
    const rescale = rescaleFactor(rotation);
    const rotation_matrix: za.Mat3_f64 = .fromRotation(rotation_angle, rotation_axis);

    const x = rotation_matrix.mulByVec3(.new(if (rotation.axis != .x) rescale else 1, 0, 0));
    const y = rotation_matrix.mulByVec3(.new(0, if (rotation.axis != .y) rescale else 1, 0));
    const z = rotation_matrix.mulByVec3(.new(0, 0, if (rotation.axis != .z) rescale else 1));
    return .{
        .x = .{ .x = @floatCast(x.x()), .y = @floatCast(x.y()), .z = @floatCast(x.z()) },
        .y = .{ .x = @floatCast(y.x()), .y = @floatCast(y.y()), .z = @floatCast(y.z()) },
        .z = .{ .x = @floatCast(z.x()), .y = @floatCast(z.y()), .z = @floatCast(z.z()) },
    };
}

fn rotationAxis(axis: ResolvedBlockModel.Element.Rotation.Axis) za.Vec3_f64 {
    return switch (axis) {
        .x => .new(1, 0, 0),
        .y => .new(0, 1, 0),
        .z => .new(0, 0, 1),
    };
}

fn rotationAngle(angle: ResolvedBlockModel.Element.Rotation.Angle) f64 {
    return switch (angle) {
        .@"-45" => -45,
        .@"-22.5" => -22.5,
        .@"0" => 0,
        .@"22.5" => 22.5,
        .@"45" => 45,
    };
}

fn rescaleFactor(rotation: ResolvedBlockModel.Element.Rotation) f32 {
    return if (rotation.rescale) switch (rotation.angle) {
        //  1/cos(angle)
        .@"-45", .@"45" => 1.41421356237,
        .@"-22.5", .@"22.5" => 1.08239220029,
        else => 1.0,
    } else 1.0;
}

fn fromFace(corners: [4]Vector3(f32), f: ResolvedBlockModel.Element.Face) Face {
    return .{
        .pos = corners,
        .texture = f.texture,
        .cullface = f.cullface,
        .uv = .{
            .{ .x = f.uv[0], .y = f.uv[3] },
            .{ .x = f.uv[2], .y = f.uv[3] },
            .{ .x = f.uv[2], .y = f.uv[1] },
            .{ .x = f.uv[0], .y = f.uv[1] },
        },
    };
}
