#version 420

layout (location=0) in vec3 VertexPosition;

layout (location=1) in vec2 TexCoord;

layout (location=2) in vec3 VertexNormal;

uniform sampler2D noiseMap;
uniform float displacementFactor; //scale factor used to determine the amount of displacement based on key press
smooth out vec4 FragmentPosition;
smooth out vec3 FragmentNormal;
smooth out vec2 FragmentTexCoord;

uniform mat4 MV;            
uniform mat4 MVP;           
uniform mat3 N;             

void main() {
    FragmentNormal = normalize(N * VertexNormal);
    //Perturbing the banana negatively according to a noise map
    vec3 noiseTex = texture(noiseMap, vec2(TexCoord.x, -TexCoord.y)).rgb;
    vec3 PerturbedVertexPosition = VertexPosition + (VertexNormal * noiseTex * -0.02*displacementFactor);
    FragmentPosition = MV * vec4(PerturbedVertexPosition, 1.0);


    FragmentTexCoord = TexCoord;


    gl_Position = MVP * vec4(PerturbedVertexPosition,1.0);
}





