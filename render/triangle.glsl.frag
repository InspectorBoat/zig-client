#version 460

in vec2 uv;

out vec4 color;

void main() {
    color = vec4(uv.x, uv.y, 1, 0);
}