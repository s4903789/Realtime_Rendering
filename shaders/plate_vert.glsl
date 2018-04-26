#version 420 core
// The vertex position attribute
layout (location=0) in vec3 VertexPosition;

// The texture coordinate attribute
layout (location=1) in vec2 TexCoord;

// The vertex normal attribute
layout (location=2) in vec3 VertexNormal;

uniform mat4 MVP;
uniform vec3 LightPos;
uniform mat3 N; 
//uniform mat3 VertexNormal;
out vec3 n;
out vec3 P;
out vec3 V;
out vec3 L;



void main()
{    
    n = normalize(N*VertexNormal);
    P = VertexPosition.xyz;
    V = -vec3(MVP* vec4(VertexPosition, 1.f)).xyz;
	L = vec3(MVP*(vec4(LightPos,1)-vec4(VertexPosition, 1.f))).xyz;
    gl_Position = MVP * vec4(VertexPosition, 1.f);
}

/*layout (location = 0) in vec3 inVert;
uniform mat4 MVP;

void main(void)
{
    gl_Position = MVP * vec4(inVert, 1.f);
}*/