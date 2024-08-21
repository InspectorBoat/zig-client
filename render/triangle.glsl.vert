#version 460

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

out vec2 uv;

layout(std430, binding = 0) restrict readonly buffer geometry {
    float data[];
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
    vec3 vertex_pos = vec3(data[gl_VertexID * 3], data[gl_VertexID * 3 + 1], data[gl_VertexID * 3 + 2]);
    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;
}