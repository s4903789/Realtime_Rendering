#version 420 core
// The vertex position attribute
layout (location=0) in vec3 VertexPosition;

// The texture coordinate attribute
layout (location=1) in vec2 TexCoord;

// The vertex normal attribute
layout (location=2) in vec3 VertexNormal;

uniform sampler2D perturbMap;
uniform mat4 MV;  
uniform mat4 MVP;
uniform vec3 LightPos;
uniform mat3 N; 
//uniform mat3 VertexNormal;
smooth out vec4 FragmentPosition;
out vec3 FragmentNormal;
out vec3 P;
out vec3 V;
out vec3 L;
out vec2 FragmentTexCoord;


void main()
{    
    FragmentNormal = normalize(N*VertexNormal);
    P = VertexPosition.xyz;
    V = -vec3(MVP* vec4(VertexPosition, 1.f)).xyz;
	L = vec3(MVP*(vec4(LightPos,1)-vec4(VertexPosition, 1.f))).xyz;
    gl_Position = MVP * vec4(VertexPosition, 1.f);


    vec3 noiseTex = texture(perturbMap, vec2(TexCoord.x, -TexCoord.y)).rgb;
    vec3 PerturbedVertexPosition = VertexPosition + (VertexNormal * noiseTex * -0.0175f);
    FragmentPosition = MV * vec4(PerturbedVertexPosition, 1.0);



    FragmentTexCoord = TexCoord;

    // Compute the position of the vertex
    gl_Position = MVP * vec4(PerturbedVertexPosition,1.0);
}

