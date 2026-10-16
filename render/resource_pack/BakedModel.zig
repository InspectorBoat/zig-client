const std = @import("std");

const za = @import("zalgebra");
const Direction = @import("main").Direction;
const Vector2xy = @import("main").Vector2xy;
const Vector3 = @import("main").Vector3;

const Renderer = @import("../Renderer.zig");
const ResolvedBlockModel = @import("ResolvedBlockModel.zig");
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

    geometry_rotation: ?Rotation,

    uv: [2]Vector2xy(f32),

    cullface: ?Direction,
    texture_rotation: ResolvedBlockModel.Element.Face.TextureRotation,

    texture: Renderer.TextureHandle,
    flip_winding: bool = false,
    flip_uv_winding: bool = false,

    const Rotation = struct {
        origin: Vector3(f32),
        axis: Direction,
        angle: f32,
        rescale: bool,
    };

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
            .down => self.facing = .south,
            .south => self.facing = .up,
        }

        if (self.cullface) |cullface| {
            switch (cullface) {
                .east, .west => {},
                .up => self.cullface = .north,
                .north => self.cullface = .down,
                .down => self.cullface = .south,
                .south => self.cullface = .up,
            }
        }

        if (self.geometry_rotation) |*rotation| {
            switch (rotation.axis) {
                .@"+x", .@"-x" => {},
                .@"+y" => self.cullface = .@"+z",
                .@"-z" => self.cullface = .@"+y",
                .@"-y" => self.cullface = .@"-z",
                .@"+z" => self.cullface = .@"-y",
            }
            const origin = rotation.origin;
            rotation.origin = .{ .x = origin.x, .y = origin.z, .z = 16 - origin.y };
        }
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
            .north => self.facing = .east,
            .east => self.facing = .south,
            .south => self.facing = .west,
            .west => self.facing = .north,
        }

        if (self.cullface) |cullface| {
            switch (cullface) {
                .up, .down => {},
                .north => self.cullface = .east,
                .east => self.cullface = .south,
                .south => self.cullface = .west,
                .west => self.cullface = .north,
            }
        }

        if (self.geometry_rotation) |*rotation| {
            switch (rotation.axis) {
                .@"-y", .@"+y" => {},
                .@"-z" => rotation.axis = .@"+x",
                .@"+x" => rotation.axis = .@"+z",
                .@"+z" => rotation.axis = .@"-x",
                .@"-x" => rotation.axis = .@"-z",
            }
            const origin = rotation.origin;
            rotation.origin = .{ .x = 16 - origin.z, .y = origin.y, .z = origin.x };
        }
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

    fn bake(
        self: @This(),
    ) Face {
        const model_to_world_scale: f32 = 1.0 / 16.0;

        var uv: [4]Vector2xy(f32) = .{
            .{ .x = self.uv[0].x, .y = self.uv[1].y },
            .{ .x = self.uv[1].x, .y = self.uv[1].y },
            .{ .x = self.uv[1].x, .y = self.uv[0].y },
            .{ .x = self.uv[0].x, .y = self.uv[0].y },
        };
        if (self.flip_uv_winding) {
            const tmp = uv[1];
            uv[1] = uv[3];
            uv[3] = tmp;
        }
        for (0..@backingInt(self.texture_rotation)) |_| {
            const prev = uv;
            uv = .{ prev[1], prev[2], prev[3], prev[0] };
        }

        var pos: [4]Vector3(f32) = .{
            toWorld(self.facing, self.xy[0].x, self.xy[0].y, self.z),
            toWorld(self.facing, self.xy[1].x, self.xy[0].y, self.z),
            toWorld(self.facing, self.xy[1].x, self.xy[1].y, self.z),
            toWorld(self.facing, self.xy[0].x, self.xy[1].y, self.z),
        };

        const transform = rotationTransform(self.geometry_rotation);
        const scale: Vector3(f32) = .splat(model_to_world_scale);
        for (&pos) |*p| p.* = .mul(fromZa(transform.mulByVec3(toZa(p.*))), scale);

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
    uvlock: bool,
) !@This() {
    var face_count: usize = 0;
    for (model.elements) |element| {
        inline for (std.enums.values(Direction)) |dir| {
            face_count += @intFromBool(@field(element.faces, @tagName(dir)) != null);
        }
    }

    var faces: std.ArrayList(Face) = try .initCapacity(gpa, face_count);

    for (model.elements) |element| {
        bakeElement(&faces, element, x_rotation, y_rotation, uvlock);
    }

    return .{ .faces = try faces.toOwnedSlice(gpa) };
}

/// Decompose into faces, then apply transforms and bake
pub fn bakeElement(
    baked_faces: *std.ArrayList(Face),
    element: ResolvedBlockModel.Element,
    x_rotation: StateToModelMap.ModelVariant.Angle,
    y_rotation: StateToModelMap.ModelVariant.Angle,
    uvlock: bool,
) void {
    inline for (std.enums.values(Direction)) |dir| {
        if (@field(element.faces, @tagName(dir))) |face| {
            const xy0, const xy1, const z = IntermediateFace.toLocal(dir, element.from, element.to);

            var ir: IntermediateFace = .{
                .facing = dir,
                .xy = .{ xy0, xy1 },
                .z = z,
                .geometry_rotation = if (element.rotation) |rotation| .{
                    .origin = rotation.origin,
                    .axis = switch (rotation.axis) {
                        .z => .@"+z",
                        .x => .@"+x",
                        .y => .@"+y",
                    },
                    .angle = rotationAngle(rotation.angle),
                    .rescale = rotation.rescale,
                } else null,
                .uv = .{ .{ .x = face.uv[0], .y = face.uv[1] }, .{ .x = face.uv[2], .y = face.uv[3] } },
                .cullface = face.cullface,
                .texture_rotation = face.rotation,
                .texture = face.texture,
            };

            for (0..@backingInt(x_rotation)) |_| ir.rotateX();
            for (0..@backingInt(y_rotation)) |_| ir.rotateY();

            if (uvlock) {
                // ir.uv = .{
                //     .{ .x = @max(ir.xy[0].x, ir.xy[1].x), .y = @max(ir.xy[0].y, ir.xy[1].y) },
                //     .{ .x = @min(ir.xy[0].x, ir.xy[1].x), .y = @min(ir.xy[0].y, ir.xy[1].y) },
                // };
                if (ir.flip_winding) ir.flip_uv_winding = true;
                ir.uv = .{
                    .{ .x = ir.xy[0].x, .y = ir.xy[0].y },
                    .{ .x = ir.xy[1].x, .y = ir.xy[1].y },
                };
                // ir.texture_rotation = .@"90";
            }

            baked_faces.appendAssumeCapacity(ir.bake());
        }
    }
}

/// An element's rotation as one affine matrix
fn rotationTransform(maybe_rotation: ?IntermediateFace.Rotation) za.Mat4 {
    const rotation = maybe_rotation orelse return .identity();

    // 1 along the axis it spins about, 1/cos(angle) along the other two
    const stretch_factor: f32 = if (rotation.rescale) 1.0 / @cos(rotation.angle * std.math.pi / 180.0) else 1.0;
    const stretch: za.Vec3 = switch (rotation.axis) {
        .@"+x", .@"-x" => .new(1, stretch_factor, stretch_factor),
        .@"+y", .@"-y" => .new(stretch_factor, 1, stretch_factor),
        .@"+z", .@"-z" => .new(stretch_factor, stretch_factor, 1),
    };

    const origin: za.Vec3 = .new(rotation.origin.x, rotation.origin.y, rotation.origin.z);
    const back: za.Vec3 = .new(-rotation.origin.x, -rotation.origin.y, -rotation.origin.z);

    var m: za.Mat4 = .fromTranslate(origin);
    m = .mul(m, .fromScale(stretch));
    m = .mul(m, .fromRotation(rotation.angle, rotationAxis(rotation.axis)));
    m = .mul(m, .fromTranslate(back));
    return m;
}

fn toZa(v: Vector3(f32)) za.Vec3 {
    return .new(v.x, v.y, v.z);
}

fn fromZa(v: za.Vec3) Vector3(f32) {
    return .{ .x = v.x(), .y = v.y(), .z = v.z() };
}

fn rotationAxis(axis: Direction) za.Vec3 {
    // zig fmt: off
    return switch (axis) {
        .@"+x" => .new( 1,  0,  0),
        .@"+y" => .new( 0,  1,  0),
        .@"+z" => .new( 0,  0,  1),
        .@"-x" => .new(-1,  0,  0),
        .@"-y" => .new( 0, -1,  0),
        .@"-z" => .new( 0,  0, -1),
    };
    // zig fmt: on
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
