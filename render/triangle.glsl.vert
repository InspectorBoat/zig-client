#version 460

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

layout(location = 0) in vec3 vertex_pos;

out vec2 uv;

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
    gl_Position = vec4(vertex_pos.xyz + chunk_pos * 16, 1) * transform;
}