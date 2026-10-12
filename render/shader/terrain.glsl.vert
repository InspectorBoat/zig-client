#version 460

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

layout(std430, binding = 0) restrict readonly buffer geometry {
    uint data[];
};

out vec2 uv;
flat out uint texture_id;
flat out uint block_light;
flat out uint sky_light;
flat out uint shade;

void main() {
    // one TerrainVertex is 16 bytes = 4 uints; the index buffer holds 0,1,2,3
    // per quad, so gl_VertexID is already the vertex index
    uint base = gl_VertexID * 4;

    vec3 vertex_pos = vec3(
        float(data[base + 0] & 0xFFFF) / 2048.0 - 8.0,
        float(data[base + 0] >>    16) / 2048.0 - 8.0,
        float(data[base + 1] & 0xFFFF) / 2048.0 - 8.0
    );

    sky_light = (data[base + 1] >> 16) & 0xF;
    block_light = (data[base + 1] >> 20) & 0xF;
    shade = (data[base + 1] >> 24) & 0xFF;

    // the last uint is texture | u << 16 | v << 24
    uint last = data[base + 3];

    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;

    texture_id = last & 0xFFFF;
    // uv is quantized out of the model's 0..16 texture space
    uv = vec2(float((last >> 16) & 0xFF), float((last >> 24) & 0xFF)) / 16.0;
}