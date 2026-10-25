parent: ?[]const u8 = null,
textures: ?JsonMap([]const u8) = null,
elements: ?[]Element = null,
ambientocclusion: ?bool = null,
display: ?Display = null,
__comment: ?[]const u8 = null,

pub const Vector3 = [3]f32;

pub const Element = struct {
    from: Vector3,
    to: Vector3,

    faces: struct {
        north: ?Face = null,
        south: ?Face = null,
        west: ?Face = null,
        east: ?Face = null,
        up: ?Face = null,
        down: ?Face = null,
    },
    rotation: ?Rotation = null,
    shade: bool = true,

    __comment: ?[]const u8 = null,

    pub const Face = struct {
        uv: ?[4]f32 = null,
        texture: []const u8,
        tintindex: ?i32 = null,
        cullface: ?CullFace = null,
        rotation: TextureRotation = .@"0",
        cull: ?bool = null,

        pub const TextureRotation = enum { @"0", @"90", @"180", @"270" };
        pub const CullFace = Direction;
    };

    pub const Rotation = struct {
        origin: Vector3,
        axis: Axis,
        angle: Angle,
        rescale: bool = false,

        pub const Axis = enum { x, y, z };

        pub const Angle = enum { @"0", @"22.5", @"-22.5", @"45", @"-45" };
    };
};

pub const Display = struct {
    thirdperson: ?Transform = null,
    firstperson: ?Transform = null,
    gui: ?Transform = null,
    head: ?Transform = null,
    ground: ?Transform = null,
    fixed: ?Transform = null,

    pub const Transform = struct {
        rotation: ?Vector3 = null,
        translation: ?Vector3 = null,
        scale: ?Vector3 = null,
    };
};

/// Pretty much directly parsed from json
const Direction = @import("main").Direction;

const JsonMap = @import("json_map.zig").JsonMap;
