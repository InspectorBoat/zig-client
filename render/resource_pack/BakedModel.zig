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

pub fn bake(
    gpa: std.mem.Allocator,
    model: ResolvedBlockModel,
    x_rotation: StateToModelMap.ModelVariant.Angle,
    y_rotation: StateToModelMap.ModelVariant.Angle,
) !@This() {
    var face_count: usize = 0;
    for (model.elements) |element| {
        inline for (Direction.names) |dir| {
            face_count += @intFromBool(@field(element.faces, dir) != null);
        }
    }

    var faces: std.ArrayList(Face) = try .initCapacity(gpa, face_count);

    for (model.elements) |element| {
        bakeElement(&faces, rotateElementY(rotateElementX(element, x_rotation), y_rotation));
    }
    return .{ .faces = faces.toOwnedSliceAssert() };
}

/// Rotates the element around the y axis
pub fn rotateElementY(element: ResolvedBlockModel.Element, angle: StateToModelMap.ModelVariant.Angle) ResolvedBlockModel.Element {
    var element_mut = element;
    for (0..@backingInt(angle)) |_| {
        const from = element_mut.from;
        const to = element_mut.to;

        // A quarter turn about y is (x, y, z) -> (16 - z, y, x) in 0..16 model units.
        // from and to trade their z values too, otherwise each face would come out wound
        // the wrong way and vanish under back-face culling.

        const new_from: Vector3(f32) = .{ .x = 16 - from.z, .y = from.y, .z = to.x };
        const new_to: Vector3(f32) = .{ .x = 16 - to.z, .y = to.y, .z = from.x };

        const new_faces: ResolvedBlockModel.Element.Faces = .{
            .west = spinFaceY(element_mut.faces.north),
            .north = spinFaceY(element_mut.faces.east),
            .east = spinFaceY(element_mut.faces.south),
            .south = spinFaceY(element_mut.faces.west),
            .up = element_mut.faces.up,
            .down = element_mut.faces.down,
        };

        const new_rotation: ?ResolvedBlockModel.Element.Rotation = if (element_mut.rotation) |rotation| .{
            .origin = .{ .x = 16 - rotation.origin.z, .y = rotation.origin.y, .z = rotation.origin.x },
            .axis = switch (rotation.axis) {
                .x => .z,
                .z => .x,
                .y => .y,
            },
            .angle = rotation.angle,
            .rescale = rotation.rescale,
        } else null;

        element_mut = .{
            .from = new_from,
            .to = new_to,
            .faces = new_faces,
            .rotation = new_rotation,
            .shade = element_mut.shade,
        };
    }

    // The block's spin carries the element's own tilt axis along with it. When
    // the axis lands pointing the opposite way ("+X" versus "-X" are the same
    // line, but leaning around them tilts opposite ways), the tilt has to
    // reverse; when it lands on a different axis in the same direction, it
    // doesn't. An axis along y is never disturbed by a spin about y.
    //
    //     tilt about | 90 | 180 | 270
    //     -----------+-----+-----+-----
    //     y          |  -  |  -  |  -
    //     z          | rev | rev |  -
    //     x          |  -  | rev | rev
    //
    // Read the axis off the ORIGINAL rotation: the loop above has already
    // swapped x and z once per quarter turn.
    const reverse_tilt: bool = if (element.rotation) |original| switch (original.axis) {
        .y => false,
        .z => angle == .@"90" or angle == .@"180",
        .x => angle == .@"180" or angle == .@"270",
    } else false;

    if (reverse_tilt) {
        if (element_mut.rotation) |*rotation| {
            rotation.angle = negateAngle(rotation.angle);
        }
    }

    return element_mut;
}

/// Rotates the element around the x axis
pub fn rotateElementX(element: ResolvedBlockModel.Element, angle: StateToModelMap.ModelVariant.Angle) ResolvedBlockModel.Element {
    var element_mut = element;
    for (0..@backingInt(angle)) |_| {
        const from = element_mut.from;
        const to = element_mut.to;

        // A quarter turn about x is (x, y, z) -> (x, z, 16 - y) in 0..16 model units.
        // from and to trade their y values too, otherwise each face would come out wound
        // the wrong way and vanish under back-face culling.

        const new_from: Vector3(f32) = .{ .x = from.x, .y = to.z, .z = 16 - from.y };
        const new_to: Vector3(f32) = .{ .x = to.x, .y = from.z, .z = 16 - to.y };

        const new_faces: ResolvedBlockModel.Element.Faces = .{
            .up = spinFaceX(element_mut.faces.north),
            .south = spinFaceX(element_mut.faces.up),
            .down = spinFaceX(element_mut.faces.south),
            .north = spinFaceX(element_mut.faces.down),
            .east = element_mut.faces.east,
            .west = element_mut.faces.west,
        };

        const new_rotation: ?ResolvedBlockModel.Element.Rotation = if (element_mut.rotation) |rotation| .{
            .origin = .{ .x = rotation.origin.x, .y = rotation.origin.z, .z = 16 - rotation.origin.y },
            .axis = switch (rotation.axis) {
                .y => .z,
                .z => .y,
                .x => .x,
            },
            .angle = rotation.angle,
            .rescale = rotation.rescale,
        } else null;

        element_mut = .{
            .from = new_from,
            .to = new_to,
            .faces = new_faces,
            .rotation = new_rotation,
            .shade = element_mut.shade,
        };
    }

    // Same reasoning as rotateElementY: the spin can carry the element's own tilt
    // axis over to its opposite, which reverses the lean. A spin about x leaves x
    // alone, and cycles y and z through each other.
    //
    //     tilt about | 90 | 180 | 270
    //     -----------+-----+-----+-----
    //     x          |  -  |  -  |  -
    //     y          | rev | rev | rev
    //     z          |  -  | rev |  -
    const reverse_tilt: bool = if (element.rotation) |original| switch (original.axis) {
        .x => false,
        .y => angle != .@"0",
        .z => angle == .@"180",
    } else false;

    if (reverse_tilt) {
        if (element_mut.rotation) |*rotation| {
            rotation.angle = negateAngle(rotation.angle);
        }
    }

    return element_mut;
}

/// A face records the direction it culls against, and that has to travel with
/// it when the element spins
fn spinFaceY(maybe_face: ?ResolvedBlockModel.Element.Face) ?ResolvedBlockModel.Element.Face {
    var face = maybe_face orelse return null;
    if (face.cullface) |*cullface| {
        cullface.* = switch (cullface.*) {
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,

            .up, .down => |dir| dir,
        };
    }
    return face;
}

/// Same job as spinFaceY for a turn about x: up, north, down and south cycle
/// through each other, east and west stay put.
fn spinFaceX(maybe_face: ?ResolvedBlockModel.Element.Face) ?ResolvedBlockModel.Element.Face {
    var face = maybe_face orelse return null;
    if (face.cullface) |*cullface| {
        cullface.* = switch (cullface.*) {
            .north => .down,
            .down => .south,
            .south => .up,
            .up => .north,

            .east, .west => |dir| dir,
        };
    }
    return face;
}

fn negateAngle(angle: ResolvedBlockModel.Element.Rotation.Angle) ResolvedBlockModel.Element.Rotation.Angle {
    return switch (angle) {
        .@"-45" => .@"45",
        .@"-22.5" => .@"22.5",
        .@"0" => .@"0",
        .@"22.5" => .@"-22.5",
        .@"45" => .@"-45",
    };
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
