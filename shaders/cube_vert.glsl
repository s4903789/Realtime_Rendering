#version 430

layout (location=0) in vec3 VertexPosition;

layout (location=1) in vec2 TexCoord;

layout (location=2) in vec3 VertexNormal;

smooth out vec3 FragmentPosition;
smooth out vec3 FragmentNormal;
smooth out vec2 FragmentTexCoord;

out vec4 worldPos;

uniform mat4 MV;            
uniform mat4 MVP;           
uniform mat3 normalMatrix;             

void main() {

    FragmentNormal = normalize(normalMatrix * VertexNormal);

    worldPos = vec4(VertexPosition, 1.f);

    FragmentPosition = vec3(MVP * vec4(VertexPosition, 1.0)).xyz;

    FragmentTexCoord = TexCoord;

    gl_Position = MVP * vec4(VertexPosition,1.0);
}





