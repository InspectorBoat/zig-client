#version 460

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

layout(std430, binding = 0) restrict readonly buffer geometry {
    uint data[];
};

out vec2 uv;
flat out uint texture_id;
flat out uint light_level;

void main() {
    uint base = gl_VertexID * 4;

    vec3 vertex_pos = vec3(
        uintBitsToFloat(data[base + 0]),
        uintBitsToFloat(data[base + 1]),
        uintBitsToFloat(data[base + 2])
    );

    // packed is a keyword or something, apparently
    uint texture = data[base + 3] & 0xFFFF;
    uint light = (data[base + 3] >> 16) & 0xFF;

    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;

    texture_id = texture;
    light_level = light;

    int corner = gl_VertexID % 4;
    switch (corner) {
        case 0:
            uv = vec2(0, 1);
            break;
        case 1:
            uv = vec2(1, 1);
            break;
        case 2:
            uv = vec2(1, 0);
            break;
        case 3:
            uv = vec2(0, 0);
            break;
    }
}
