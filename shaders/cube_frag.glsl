#version 420 core

// Attributes passed on from the vertex shader
in vec3 FragmentPosition;
in vec3 FragmentNormal;
in vec2 FragmentTexCoord;
in vec4 worldPos;

uniform samplerCube cubeMap;

/// @brief our output fragment colour
layout (location=0) out vec4 FragColour;

// A texture unit for storing the 3D texture
uniform samplerCube envMap;
void main()
{


    vec3 lookup = normalize(worldPos.xyz / worldPos.w);
    lookup.y *= -1;
    lookup.z *= -1;


    vec4 colour = texture(cubeMap, lookup);

    FragColour = colour;
    FragColour = vec4(1.f);

}
