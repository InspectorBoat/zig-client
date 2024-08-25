#version 460

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

out vec2 uv;
flat out uint texture_id;

layout(std430, binding = 0) restrict readonly buffer geometry {
    uint data[];
    // packed struct(u64) {
    //     pos: packed struct(u48) {
    //         x: u16,
    //         y: u16,
    //         z: u16,
    //     },
    //     uv: packed struct(u8) {
    //         u: u4,
    //         v: u4,
    //     },
    //     texture: u8,
    // }
};

const mat3[] size_transforms = {
        mat3(
        1, 0, 0,
        0, 0, 0,
        0, 1, 0
        ),
        mat3(
        1, 0, 0,
        0, 0, 0,
        0, 1, 0
        ),
        mat3(
        1, 0, 0,
        0, 1, 0,
        0, 0, 0
        ),
        mat3(
        1, 0, 0,
        0, 1, 0,
        0, 0, 0
        ),
        mat3(
        0, 0, 0,
        0, 1, 0,
        1, 0, 0
        ),
        mat3(
        0, 0, 0,
        0, 1, 0,
        1, 0, 0
        )
};


void main() {
    uint base_offset = gl_VertexID / 4 * 4;

    vec3 vertex_pos = vec3(
           uvec3(data[base_offset + 0], data[base_offset + 0], data[base_offset + 1])
        >> uvec3(0, 16, 0)
        &  0xFFFF
    ) / 4095.9375;
    vec2 size = vec2(
          (uvec2(data[base_offset + 1], data[base_offset + 1])
        >> uvec2(16, 24)
        &  0xFF)
        +  1
    ) / 255;
    uint normal = data[base_offset + 2] >> 0 & 0xFF;

    vec3 offset = vec3(size * vec2(gl_VertexID & 1, (gl_VertexID & 2) >> 1), 0) * size_transforms[normal];

    gl_Position = vec4(vertex_pos + offset + chunk_pos * 16, 1) * transform;

    texture_id = (data[base_offset + 2] >> 16) & 0xFFFF;

    uv = vec2(gl_VertexID & 1, (gl_VertexID & 2) >> 1);
}