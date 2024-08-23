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
    vec3 vertex_pos = vec3(
           uvec3(data[gl_VertexID * 2 + 0], data[gl_VertexID * 2 + 0], data[gl_VertexID * 2 + 1])
        >> uvec3(0, 16, 0)
        &  0xFFFF
    ) / 4095.9375;
    
    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;

    texture_id = (data[gl_VertexID * 2 + 1] >> 24) & 0xFF;

    uv = vec2(
           (uvec2(data[gl_VertexID * 2 + 1], data[gl_VertexID * 2 + 1])
        >> uvec2(16, 20)
        &  0xF)
        +  uvec2(gl_VertexID & 1, (gl_VertexID & 2) >> 1)
    ) / 16;
}