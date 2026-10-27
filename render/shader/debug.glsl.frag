#version 460

layout(location = 16) uniform sampler2DArray block_texture;

flat in uint texture_id;
in vec2 uv_varying;

out vec4 color;

void main() {
    color = texture(block_texture, vec3(uv_varying / 16, texture_id));
    if (color.a == 0) discard;
}