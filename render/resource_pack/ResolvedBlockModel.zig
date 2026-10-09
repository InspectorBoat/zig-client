/// BlockModelTemplate, but we walked the parent chain and resolved
/// all texture references, ambient occlusion, and elements
const Vector3 = @import("root").Vector3;
const Vector2 = @import("root").Vector2;
const BlockModelTemplate = @import("BlockModelTemplate.zig");

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
        cullface: ?BlockModelTemplate.Element.Face.CullFace,
        rotation: BlockModelTemplate.Element.Face.TextureRotation,
        cull: ?bool,
    };

    pub const Rotation = struct {
        origin: Vector3(f32),
        axis: BlockModelTemplate.Element.Rotation.Axis,
        angle: BlockModelTemplate.Element.Rotation.Angle,
        rescale: bool,
    };
};
