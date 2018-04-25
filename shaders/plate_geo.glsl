#version 420 core
layout(triangles) in;
layout(triangle_strip, max_vertices = 256) out;

#define M_PI 3.1415926535897932384626433832795

uniform mat4 MVP;
uniform mat3 N; 
smooth out vec3 plateNormal;
smooth out vec3 platePosition;

//function to return the position of a vertex on a ring given a radius and angle, using sin and cos functions
vec3 ring(float r, float theta, float yPos)
{
    vec3 pos;
    if(r < 0.00001f)
        pos = vec3(0.f, yPos, 0.f);
    else
    {
        pos.x = r*cos(theta);
        pos.z = r*sin(theta);
        pos.y = yPos;
    }
    return pos;
}
void calculateNormal(float _innerRadius, float _outerRadius, float _innerYPos, float _outerYPos, vec3 _pos)
{
    float a = _outerRadius - _innerRadius;
    float b = _outerYPos - _innerYPos;
    float alpha = atan(b/a);
    float phi = (M_PI/2.f) - alpha;
    float d = sqrt(pow(gl_Position.x, 2) + pow(gl_Position.z, 2));
    vec3 n = vec3(-_pos.x, d*tan(phi), -_pos.z);
    vec3 nHat = normalize(n);
    plateNormal = n;
}
void drawDisk(float _innerRadius, float _outerRadius, float _innerYPos, float _outerYPos)
{
    int numEdges = 40;
    float theta = 0.f;
    for(int i = 0; i < numEdges + 1; i++)
    {   
        vec3 pos = ring(_outerRadius, theta, _outerYPos);
        gl_Position = MVP * vec4(pos, 1.f);
        calculateNormal(_innerRadius, _outerRadius, _innerYPos, _outerYPos, pos);
        platePosition = gl_Position.xyz;
        EmitVertex();   
        pos = ring(_innerRadius, theta, _innerYPos);
        gl_Position = MVP * vec4(pos, 1.f);
        calculateNormal(_innerRadius, _outerRadius, _innerYPos, _outerYPos, pos);
        EmitVertex();
        theta = theta + (2.f * M_PI / numEdges);
    }
    EndPrimitive();
}



void main() 
{
    //inner radius of next is always outside of previous
    //small disk
    //drawDisk(0.3f, 0.3, 0.f, 0.02f);
    //big disk
    drawDisk(0.f, 0.49, 0.f, 0.2f);


}
