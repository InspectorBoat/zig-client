#version 460

flat in uint texture_id;
in vec2 uv;

out vec4 color;

layout(location = 2) uniform sampler2DArray block_texture;

void main() {
    color = texture(block_texture, vec3(uv, texture_id));
    if (color.a == 0) discard;
    // color = vec4(0, sqrt(uv), 0);
}