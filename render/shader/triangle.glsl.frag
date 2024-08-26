#version 460

flat in uint texture_id;
in vec2 uv;
flat in uint sky_light;
flat in uint block_light;

out vec4 color;

layout(location = 2) uniform sampler2DArray block_texture;

void main() {
    color = texture(block_texture, vec3(uv, texture_id)) * sky_light / 15;
    if (color.a == 0) discard;
}