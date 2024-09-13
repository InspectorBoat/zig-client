#version 460

layout(location = 0) uniform mat4 transform;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 color;

out vec3 color_in;

void main() {
    gl_Position = vec4(pos, 1) * transform;
    if (floatBitsToInt(pos.z) == 0xffffffff) gl_Position = vec4(pos.xy, -0.99, 1);
    color_in = color;
}