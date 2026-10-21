#version 460

#ifndef __FOG_IMPORT__
#define __FOG_IMPORT__

layout(location = 2) uniform bool uFogEnabled;
layout(location = 3) uniform vec4 uFogColor;
layout(location = 4) uniform float uFogStart;
layout(location = 5) uniform float uFogEnd;
layout(location = 6) uniform float uFogDensity;
layout(location = 7) uniform int uFogMode;
layout(location = 8) uniform int uFogDistanceMode;
layout(location = 9) uniform mat4 uMvMatrix;

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

layout(location = 0) uniform mat4 transform;
layout(location = 1) uniform vec3 chunk_pos;

layout(std430, binding = 0) restrict readonly buffer geometry {
    uint data[];
};

out vec2 uv;
out float vertexDistance;
flat out uint texture_id;
flat out uint block_light;
flat out uint sky_light;
flat out uint shade;

void main() {
    // one TerrainVertex is 16 bytes = 4 uints; the index buffer holds 0,1,2,3
    // per quad, so gl_VertexID is already the vertex index
    uint base = gl_VertexID * 4;

    vec3 vertex_pos = vec3(
        float(data[base + 0] & 0xFFFF) / 2048.0 - 8.0,
        float(data[base + 0] >>    16) / 2048.0 - 8.0,
        float(data[base + 1] & 0xFFFF) / 2048.0 - 8.0
    );

    sky_light = (data[base + 1] >> 16) & 0xF;
    block_light = (data[base + 1] >> 20) & 0xF;
    shade = (data[base + 1] >> 24) & 0xFF;

    // the last uint is texture | u << 16 | v << 24
    uint last = data[base + 3];

    gl_Position = vec4(vertex_pos + chunk_pos * 16, 1) * transform;

    texture_id = last & 0xFFFF;
    // uv is quantized out of the model's 0..16 texture space
    uv = vec2(float((last >> 16) & 0xFF), float((last >> 24) & 0xFF)) / 16.0;
    vertexDistance = fog_distance((vec4(vertex_pos + chunk_pos * 16, 1) * uMvMatrix).xyz);
}