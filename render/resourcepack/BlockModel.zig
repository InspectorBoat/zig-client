const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const ParsedBlockModel = @import("ParsedBlockModel.zig");

elements: []Element,
ambientocclusion: ?bool,

pub const Element = struct {
    from: Vector3(f32),
    to: Vector3(f32),

    faces: struct {
        north: ?Face,
        south: ?Face,
        west: ?Face,
        east: ?Face,
        up: ?Face,
        down: ?Face,
    },
    rotation: ?Rotation,
    shade: bool,

    pub const Face = struct {
        uv: [4]f32,
        texture: []const u8,
        tintindex: ?i32,
        cullface: ?ParsedBlockModel.Element.Face.CullFace,
        rotation: ParsedBlockModel.Element.Face.TextureRotation,
        cull: ?bool,
    };

    pub const Rotation = struct {
        origin: Vector3(f32),
        axis: ParsedBlockModel.Element.Rotation.Axis,
        angle: ParsedBlockModel.Element.Rotation.Angle,
        rescale: bool,
    };
};
