#version 460

flat in uint texture_id;
flat in uint block_light;
flat in uint sky_light;
flat in uint shade;
in vec2 uv;

out vec4 color;

layout(location = 2) uniform sampler2DArray block_texture;

void main() {
    color = texture(block_texture, vec3(uv, texture_id));
    // color.rgb *= max(float(sky_light + 0.5) / 16.5, float(block_light) / 16.0);
    switch (shade) {
        case 0:
            color.rgb *= 0.5F;
            break;
        case 1:
            color.rgb *= 1.0F;
            break;
        case 2:
        case 3:
            color.rgb *= 0.8F;
            break;
        case 4:
        case 5:
            color.rgb *= 0.6F;
            break;
    }
    if (color.a == 0) discard;
}