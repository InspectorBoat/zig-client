//! ModelTemplate, but we walked the parent chain and resolved
//! all texture references, ambient occlusion, and elements

geometry: Geometry,
ambientocclusion: bool,
display: Display,

pub const Geometry = union(enum) {
    elements: []Element,
    generated_item: [5]?TextureHandle,
};

pub const Element = struct {
    from: Vector3(f32),
    to: Vector3(f32),

    faces: Faces,
    rotation: ?Rotation,
    shade: bool,

    pub const Faces = struct {
        north: ?Face,
        south: ?Face,
        west: ?Face,
        east: ?Face,
        up: ?Face,
        down: ?Face,
    };

    pub const Face = struct {
        uv: [4]f32,
        texture: TextureHandle,
        tintindex: ?i32,
        cullface: ?CullFace,
        rotation: TextureRotation,
        cull: ?bool,

        pub const CullFace = ModelTemplate.Element.Face.CullFace;
        pub const TextureRotation = ModelTemplate.Element.Face.TextureRotation;
    };

    pub const Rotation = struct {
        origin: Vector3(f32),
        axis: Axis,
        angle: Angle,
        rescale: bool,

        pub const Axis = ModelTemplate.Element.Rotation.Axis;
        pub const Angle = ModelTemplate.Element.Rotation.Angle;
    };
};

const Vector3 = @import("main").Vector3;

const ModelTemplate = @import("ModelTemplate.zig");
const TextureHandle = @import("../Renderer.zig").TextureHandle;

pub const Display = ModelTemplate.Display;
