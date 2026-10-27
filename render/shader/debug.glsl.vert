#version 460

layout(location = 0) uniform mat4 transform;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in uint texture;

flat out uint texture_id;
out vec2 uv_varying;

void main() {
    gl_Position = vec4(pos, 1) * transform;
    texture_id = texture;
    uv_varying = uv;
}