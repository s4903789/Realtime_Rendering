#version 420 core

layout (location = 0) in vec3 inVert;
uniform mat4 MVP;

void main(void)
{
    gl_Position = MVP * vec4(inVert, 1.f);
}