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

/// Intermediate representation
const IntermediateFace = struct {
    facing: Direction,

    // coordinates local to the face's `facing`
    xy: [2]Vector2xy(f32),
    z: f32,

    uv: [2]Vector2xy(f32),

    cullface: ?Direction,
    texture_rotation: ResolvedBlockModel.Element.Face.TextureRotation,
    texture: Renderer.TextureHandle,
    flip_winding: bool = false,

    /// Rotates clockwise around the +X axis going through the center of the model
    fn rotateX(self: *@This()) void {
        switch (self.facing) {
            .east => {
                const xy = self.xy;
                self.xy = .{
                    .{ .x = xy[0].y, .y = 16 - xy[0].x },
                    .{ .x = xy[1].y, .y = 16 - xy[1].x },
                };
                self.flip_winding = !self.flip_winding;
            },
            .west => {
                const xy = self.xy;
                self.xy = .{
                    .{ .x = 16 - xy[0].y, .y = xy[0].x },
                    .{ .x = 16 - xy[1].y, .y = xy[1].x },
                };
                self.flip_winding = !self.flip_winding;
            },

            .up => {
                self.facing = .north;
                const xy = self.xy;
                self.xy = .{
                    .{ .x = 16 - xy[0].x, .y = 16 - xy[0].y },
                    .{ .x = 16 - xy[1].x, .y = 16 - xy[1].y },
                };
            },
            .north => {
                self.facing = .down;
                const xy = self.xy;
                self.xy = .{
                    .{ .x = 16 - xy[0].x, .y = 16 - xy[0].y },
                    .{ .x = 16 - xy[1].x, .y = 16 - xy[1].y },
                };
            },
            .down => {
                self.facing = .south;
            },
            .south => {
                self.facing = .up;
            },
        }
        self.cullface = if (self.cullface) |cullface| switch (cullface) {
            .east, .west => cullface,
            .up => .north,
            .north => .down,
            .down => .south,
            .south => .up,
        } else null;
    }

    /// Rotates clockwise around the +Y axis going through the center of the model
    fn rotateY(self: *@This()) void {
        switch (self.facing) {
            .up => {
                const xy = self.xy;
                self.xy = .{
                    .{ .x = xy[0].y, .y = 16 - xy[0].x },
                    .{ .x = xy[1].y, .y = 16 - xy[1].x },
                };
                self.flip_winding = !self.flip_winding;
            },
            .down => {
                const xy = self.xy;
                self.xy = .{
                    .{ .x = 16 - xy[0].y, .y = xy[0].x },
                    .{ .x = 16 - xy[1].y, .y = xy[1].x },
                };
                self.flip_winding = !self.flip_winding;
            },
            .north => {
                self.facing = .east;
            },
            .east => {
                self.facing = .south;
            },
            .south => {
                self.facing = .west;
            },
            .west => {
                self.facing = .north;
            },
        }

        self.cullface = if (self.cullface) |cullface| switch (cullface) {
            .up, .down => cullface,
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,
        } else null;
    }

    /// Takes a pair of element points from model space and a direction and returns
    /// xy0, xy1, and z in that direction's frame
    fn toLocal(facing: Direction, from: Vector3(f32), to: Vector3(f32)) struct { Vector2xy(f32), Vector2xy(f32), f32 } {
        // zig fmt: off
        return switch (facing) {
            .down  => .{ .{ .x =    from.x, .y =    from.z }, .{ .x =        to.x, .y =        to.z },    from.y },
            .up    => .{ .{ .x =    from.x, .y = 16 - to.z }, .{ .x =        to.x, .y = 16 - from.z }, 16 - to.y },
            .south => .{ .{ .x =    from.x, .y =    from.y }, .{ .x =        to.x, .y =        to.y }, 16 - to.z },
            .north => .{ .{ .x = 16 - to.x, .y =    from.y }, .{ .x = 16 - from.x, .y =        to.y },    from.z },
            .west  => .{ .{ .x =    from.z, .y =    from.y }, .{ .x =        to.z, .y =        to.y },    from.x },
            .east  => .{ .{ .x = 16 - to.z, .y =    from.y }, .{ .x = 16 - from.z, .y =        to.y }, 16 - to.x },
        };
        // zig fmt: on
    }

    /// Places a point from a directional frame back into model space
    fn toWorld(facing: Direction, x: f32, y: f32, z: f32) Vector3(f32) {
        // zig fmt: off
        return switch (facing) {
            .down  => .{ .x =      x, .y =      z, .z =      y },
            .up    => .{ .x =      x, .y = 16 - z, .z = 16 - y },
            .south => .{ .x =      x, .y =      y, .z = 16 - z },
            .north => .{ .x = 16 - x, .y =      y, .z =      z },
            .west  => .{ .x =      z, .y =      y, .z =      x },
            .east  => .{ .x = 16 - z, .y =      y, .z = 16 - x },
        };
        // zig fmt: on
    }

    fn bake(self: @This()) Face {
        const model_to_world_scale: f32 = 1.0 / 16.0;

        var uv: [4]Vector2xy(f32) = .{
            .{ .x = self.uv[0].x, .y = self.uv[1].y },
            .{ .x = self.uv[1].x, .y = self.uv[1].y },
            .{ .x = self.uv[1].x, .y = self.uv[0].y },
            .{ .x = self.uv[0].x, .y = self.uv[0].y },
        };
        for (0..@backingInt(self.texture_rotation)) |_| {
            const prev = uv;
            uv = .{ prev[1], prev[2], prev[3], prev[0] };
        }

        var pos: [4]Vector3(f32) = .{
            .mul(toWorld(self.facing, self.xy[0].x, self.xy[0].y, self.z), .splat(model_to_world_scale)),
            .mul(toWorld(self.facing, self.xy[1].x, self.xy[0].y, self.z), .splat(model_to_world_scale)),
            .mul(toWorld(self.facing, self.xy[1].x, self.xy[1].y, self.z), .splat(model_to_world_scale)),
            .mul(toWorld(self.facing, self.xy[0].x, self.xy[1].y, self.z), .splat(model_to_world_scale)),
        };

        if (self.flip_winding) {
            const tmp = pos[1];
            pos[1] = pos[3];
            pos[3] = tmp;
        }

        return .{
            .pos = pos,
            .uv = uv,
            .texture = self.texture,
            .cullface = self.cullface,
        };
    }
};

pub fn bake(
    gpa: std.mem.Allocator,
    model: ResolvedBlockModel,
    x_rotation: StateToModelMap.ModelVariant.Angle,
    y_rotation: StateToModelMap.ModelVariant.Angle,
) !@This() {
    var face_count: usize = 0;
    for (model.elements) |element| {
        inline for (std.enums.values(Direction)) |dir| {
            face_count += @intFromBool(@field(element.faces, @tagName(dir)) != null);
        }
    }

    var faces: std.ArrayList(Face) = try .initCapacity(gpa, face_count);

    for (model.elements) |element| {
        decomposeElement(&faces, element, x_rotation, y_rotation);
    }

    return .{ .faces = try faces.toOwnedSlice(gpa) };
}

/// Decompose into faces, then apply transforms and bake
pub fn decomposeElement(
    baked_faces: *std.ArrayList(Face),
    element: ResolvedBlockModel.Element,
    x_rotation: StateToModelMap.ModelVariant.Angle,
    y_rotation: StateToModelMap.ModelVariant.Angle,
) void {
    inline for (std.enums.values(Direction)) |dir| {
        if (@field(element.faces, @tagName(dir))) |face| {
            const xy0, const xy1, const z = IntermediateFace.toLocal(dir, element.from, element.to);

            var ir: IntermediateFace = .{
                .facing = dir,
                .xy = .{ xy0, xy1 },
                .z = z,
                .uv = .{ .{ .x = face.uv[0], .y = face.uv[1] }, .{ .x = face.uv[2], .y = face.uv[3] } },
                .cullface = face.cullface,
                .texture_rotation = face.rotation,
                .texture = face.texture,
            };

            for (0..@backingInt(x_rotation)) |_| ir.rotateX();
            for (0..@backingInt(y_rotation)) |_| ir.rotateY();

            baked_faces.appendAssumeCapacity(ir.bake());
        }
    }
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
    if (element.faces.east)  |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"101", @"100", @"110", @"111" }, face));
    if (element.faces.south) |face| baked_faces.appendAssumeCapacity(fromFace(.{ @"001", @"101", @"111", @"011" }, face));
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
    var uvs: [4]Vector2xy(f32) = .{
        .{ .x = f.uv[0], .y = f.uv[3] },
        .{ .x = f.uv[2], .y = f.uv[3] },
        .{ .x = f.uv[2], .y = f.uv[1] },
        .{ .x = f.uv[0], .y = f.uv[1] },
    };
    for (0..@backingInt(f.rotation)) |_| {
        // beware of rls!
        const uvs_const = uvs;
        uvs = .{ uvs_const[1], uvs_const[2], uvs_const[3], uvs_const[0] };
    }
    return .{
        .pos = corners,
        .texture = f.texture,
        .cullface = f.cullface,
        .uv = uvs,
    };
}
