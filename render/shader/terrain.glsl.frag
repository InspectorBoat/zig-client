#version 460

#ifndef __FOG_IMPORT__
#define __FOG_IMPORT__

uniform bool uFogEnabled;
uniform vec4 uFogColor;
uniform float uFogStart;
uniform float uFogEnd;
uniform float uFogDensity;
uniform int uFogMode;
uniform int uFogDistanceMode;

#define FOG_MODE_EXP 2048
#define FOG_MODE_EXP2 2049
#define FOG_MODE_LINEAR 9729

// (3.31)
float fog_factor_exp(float distance, float density) {
    return exp(-density * distance);
}

// (3.32)
float fog_factor_exp2(float distance, float density) {
    float volume = density * distance;
    return exp(-(volume * volume));
}

// (3.33)
float fog_factor_linear(float distance, float start, float end) {
    return (end - distance) / (end - start);
}

float fog_factor(float distance, float density, float start, float end, int mode) {
    if (mode == FOG_MODE_EXP) {
        return fog_factor_exp(distance, density);
    } else if (mode == FOG_MODE_EXP2) {
        return fog_factor_exp2(distance, density);
    } else if (mode == FOG_MODE_LINEAR) {
        return fog_factor_linear(distance, start, end);
    } else {
        return 0.0;
    }
}

// (The rasterized fragment’s A value is not changed by fog blending.) Each component of FogColor is clamped to [0, 1].
// No matter which equation and approximation is used to compute factor, the result is clamped to [0, 1] to obtain the final factor.
vec4 apply_fog(vec4 color, vec4 fogColor, float factor) {
    if (uFogEnabled) {
        return vec4(mix(clamp(fogColor.rgb, 0.0, 1.0), color.rgb, clamp(factor, 0.0, 1.0)), color.a);
    } else {
        return color;
    }
}

vec4 apply_fog(vec4 color, float distance) {
    return apply_fog(color, uFogColor, fog_factor(distance, uFogDensity, uFogStart, uFogEnd, uFogMode));
}

// https://registry.khronos.org/OpenGL/extensions/NV/NV_fog_distance.txt
#define FOG_DISTANCE_EYE_PLANE_ABSOLUTE_NV 34140
#define FOG_DISTANCE_EYE_RADIAL_NV 34139

float fog_distance(vec3 pos, int mode) {
    if (mode == FOG_DISTANCE_EYE_PLANE_ABSOLUTE_NV) {
        return abs(pos.z);
    } else if (mode == FOG_DISTANCE_EYE_RADIAL_NV) {
        return length(pos);
    } else {
        return 0.0;
    }
}

float fog_distance(vec3 pos) {
    return fog_distance(pos, uFogDistanceMode);
}

#endif // __FOG_IMPORT__

flat in uint texture_id;
flat in uint block_light;
flat in uint sky_light;
flat in uint shade;
in vec2 uv;
in float vertexDistance;

out vec4 color;

layout(location = 16) uniform sampler2DArray block_texture;

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
    color = apply_fog(color, vertexDistance);
}