#version 420 core
layout(triangles) in;
layout(triangle_strip, max_vertices = 256) out;

#define M_PI 3.1415926535897932384626433832795

uniform mat4 MVP;

//function to return the position of a vertex on a ring given a radius and angle, using sin and cos functions
vec3 ring(float r, float theta, float yPos)
{
    if(r < 0.00001f)
        return vec3(0.f, yPos, 0.f);
    
    vec3 pos;
    pos.x = r*cos(theta);
    pos.z = r*sin(theta);
    pos.y = yPos;
    
    return pos;
}

void drawDisk(float _innerRadius, float _outerRadius, float _innerYPos, float _outerYPos)
{
    int numEdges = 127;
    float theta = 0.f;
    for(int i = 0; i < numEdges + 1; i++)
    {          
        gl_Position = MVP * vec4(ring(_outerRadius, theta, _outerYPos), 1.f);
        EmitVertex();   
        gl_Position = MVP * vec4(ring(_innerRadius, theta, _innerYPos), 1.f);
        EmitVertex();
        theta = theta + (2.f * M_PI / numEdges);
    }
    EndPrimitive();
}

void main() 
{
    drawDisk
    drawDisk(0.2f, 0.49, 0.f, 0.2f);


}
