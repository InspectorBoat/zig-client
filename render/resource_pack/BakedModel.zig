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
    // model units are 0..16 per block,
    // but world space is 0..1 per block
    const model_to_world_scale: f32 = 1.0 / 16.0;

    const transform = elementTransform(element.rotation);
    const size: Vector3(f32) = .sub(element.to, element.from);

    // anchor is the origin corner (element.from) mapped through transform
    const anchor: Vector3(f32) = .mul(
        fromZa(transform.mulByVec3(toZa(element.from))),
        .splat(model_to_world_scale),
    );
    // the basis is its columns scaled by each edge's length
    const basis: Vector3(Vector3(f32)) = .{
        .x = .mul(column(transform, 0), .splat(size.x * model_to_world_scale)),
        .y = .mul(column(transform, 1), .splat(size.y * model_to_world_scale)),
        .z = .mul(column(transform, 2), .splat(size.z * model_to_world_scale)),
    };

    // zig fmt: off
    const @"000" = anchor                                       ;
    const @"001" = anchor                          .add(basis.z);
    const @"010" = anchor             .add(basis.y)             ;
    const @"011" = anchor             .add(basis.y).add(basis.z);
    const @"100" = anchor.add(basis.x)                          ;
    const @"101" = anchor.add(basis.x)             .add(basis.z);
    const @"110" = anchor.add(basis.x).add(basis.y)             ;
    const @"111" = anchor.add(basis.x).add(basis.y).add(basis.z);

    if (element.faces.west)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"000", @"001", @"011", @"010" }, face));
    if (element.faces.south) |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"001", @"101", @"111", @"011" }, face));
    if (element.faces.east)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"101", @"100", @"110", @"111" }, face));
    if (element.faces.north) |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"100", @"000", @"010", @"110" }, face));
    if (element.faces.up)    |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"011", @"111", @"110", @"010" }, face));
    if (element.faces.down)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"000", @"100", @"101", @"001" }, face));
    // zig fmt: on
}

/// An element's rotation as one affine matrix
fn elementTransform(maybe_rotation: ?ResolvedBlockModel.Element.Rotation) za.Mat4 {
    const rotation = maybe_rotation orelse return .identity();

    const angle = rotationAngle(rotation.angle);

    // 1 along the axis it spins about, 1/cos(angle) along the other two
    const stretch_factor: f32 = if (rotation.rescale) 1.0 / @cos(angle * std.math.pi / 180.0) else 1.0;
    const stretch: za.Vec3 = .new(
        if (rotation.axis == .x) 1.0 else stretch_factor,
        if (rotation.axis == .y) 1.0 else stretch_factor,
        if (rotation.axis == .z) 1.0 else stretch_factor,
    );

    const origin: za.Vec3 = .new(rotation.origin.x, rotation.origin.y, rotation.origin.z);
    const back: za.Vec3 = .new(-origin.x(), -origin.y(), -origin.z());

    var m: za.Mat4 = .fromTranslate(origin);
    m = .mul(m, .fromScale(stretch));
    m = .mul(m, .fromRotation(angle, rotationAxis(rotation.axis)));
    m = .mul(m, .fromTranslate(back));
    return m;
}

fn column(m: za.Mat4, i: usize) Vector3(f32) {
    return .{ .x = m.data[i][0], .y = m.data[i][1], .z = m.data[i][2] };
}

fn toZa(v: Vector3(f32)) za.Vec3 {
    return .new(v.x, v.y, v.z);
}

fn fromZa(v: za.Vec3) Vector3(f32) {
    return .{ .x = v.x(), .y = v.y(), .z = v.z() };
}

fn rotationAxis(axis: ResolvedBlockModel.Element.Rotation.Axis) za.Vec3 {
    return switch (axis) {
        .x => .new(1, 0, 0),
        .y => .new(0, 1, 0),
        .z => .new(0, 0, 1),
    };
}

fn rotationAngle(angle: ResolvedBlockModel.Element.Rotation.Angle) f32 {
    return switch (angle) {
        .@"-45" => -45,
        .@"-22.5" => -22.5,
        .@"0" => 0,
        .@"22.5" => 22.5,
        .@"45" => 45,
    };
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
