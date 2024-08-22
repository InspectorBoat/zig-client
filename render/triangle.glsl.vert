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

void main() {
    switch (gl_VertexID % 4) {
        case 0:
            uv = vec2(0, 0);
            break;
        case 1:
            uv = vec2(1, 0);
            break;
        case 2:
            uv = vec2(1, 1);
            break;
        case 3:
            uv = vec2(0, 1);
            break;
    }

    vec3 vertex_pos = vec3(
           uvec3(data[gl_VertexID * 2 + 0], data[gl_VertexID * 2 + 0], data[gl_VertexID * 2 + 1])
        >> uvec3(0, 16, 0)
        &  uvec3(0xFFFF)
    ) / 4095.9375;
    
    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;

    texture_id = (data[gl_VertexID * 2 + 1] >> 24) & 0xFF;
}