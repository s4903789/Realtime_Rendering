#version 430

// The modelview and projection matrices are no longer given in OpenGL 4.2
uniform mat4 MV;
uniform mat4 MVP;
uniform mat3 N; // This is the inverse transpose of the MV matrix

//creating a vec3 for the colour
vec3 colour = vec3(1.0, 1.0, 0.0);



// The fragment position attribute
layout (location=0) out vec4 FragColor;

// Structure for holding light parameters
struct LightInfo {
    vec4 Position; // Light position in eye coords.
    vec3 La; // Ambient light intensity
    vec3 Ld; // Diffuse light intensity
    vec3 Ls; // Specular light intensity
};

// We'll have a single light in the scene with some default values
uniform LightInfo Light = LightInfo(
            vec4(2.0, 2.0, 10.0, 1.0),   // position
            vec3(0.2, 0.2, 0.2),        // La
            vec3(1.0, 1.0, 1.0),        // Ld
            vec3(1.0, 1.0, 1.0)         // Ls
            );

// The material properties of our object
struct MaterialInfo {
    vec3 Ka; // Ambient reflectivity
    vec3 Kd; // Diffuse reflectivity
    vec3 Ks; // Specular reflectivity
    float Shininess; // Specular shininess factor
};

// The object has a material
uniform MaterialInfo Material = MaterialInfo(
            vec3(0.1, 0.1, 0.1),    // Ka
            vec3(1.0, 1.0, 1.0),    // Kd
            vec3(1.0, 1.0, 1.0),    // Ks
            10.0                  // Shininess
            );

// This is passed on from the vertex shader
in vec3 FragNormal;
in vec4 FragmentPosition;


void main() {

    // Transform your input normal
    vec3 n = normalize(FragNormal );
    
    vec3 p = FragmentPosition.xyz / FragmentPosition.w;

    // Calculate the light vector
    vec3 s = normalize( vec3(Light.Position) - p); //this is s for the h equation

    // Calculate the vertex position (view vector)
    vec3 v = normalize(vec3(-p));

    // Reflect the light about the surface normal
    vec3 r = reflect( -s, n );

    //creating a roughness value
   /* vec3 h = (v+s)/abs(v+s);
    float m = 0.5;
    float mSquared = m*m;
    float NdotH = dot(n, h); //dot product of surface and light position
    float r1  = 1.0 / (4.0 * mSquared * pow(NdotH, 4.0));
    float r2 = (NdotH * NdotH - 1.0) / (mSquared * NdotH * NdotH);
    float roughness = r1 * exp(r2);*/

    //computing h
    //s = negative direction of incoming light
    //v = direction of outgoing light
    //h = (v+s)/abs(v+s)
    //second attempt
    /*vec3 h = (v+s)/abs(v+s);
    float alpha = acos(dot(n,h));
    float m = 0.1;
    float tanPow = pow(tan(alpha),2);
    float cosPow = pow(cos(alpha),4);
    float mpow = pow(m, 2);

    float beckmann = (exp(-tanPow / mpow)) / (3.1415936*mpow*cosPow);*/
    //third attempt

    
    
    
    //first attemp
    /*float m = 0.1;
    float mSquared = m*m;
    float NdotH = dot(n, h); //dot product of surface and light position
    float r1  = 1.0 / (4.0 * mSquared * pow(NdotH, 4.0));
    float r2 = (NdotH * NdotH - 1.0) / (mSquared * NdotH * NdotH);
    float roughness = r1 * exp(r2);*/

    // Compute the light from the ambient, diffuse and specular components
    vec3 LightIntensity = (
            Light.La * Material.Ka +
            Light.Ld * Material.Kd * max( dot(s, n), 0.0 ) +
            Light.Ls * Material.Ks * pow( max( dot(r,v), 0.0 ), Material.Shininess));
    // Set the output color of our current pixel
    FragColor = vec4(colour* LightIntensity,1.0);//*roughness;
}

