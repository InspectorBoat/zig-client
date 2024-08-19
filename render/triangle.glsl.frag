#version 460

in vec2 uv;

out vec4 color;

layout(location = 3) uniform sampler2DArray block_texture;

void main() {
    color = texture(block_texture, vec3(uv, 0));
}