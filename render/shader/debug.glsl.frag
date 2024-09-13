#version 460

in vec3 color_in;

out vec4 color;

void main() {
    color = vec4(color_in, 0);
}