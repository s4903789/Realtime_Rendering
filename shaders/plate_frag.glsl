#version 420 core

/// @brief our output fragment colour
layout (location=0) out vec4 FragColour;

smooth in vec4 FragmentPosition;
smooth in vec3 FragmentNormal;
smooth in vec2 FragmentTexCoord;

// A texture sampler to store the normal information
uniform sampler2D woodNormal;

uniform vec3 lightPositions[18];
uniform vec3 lightColours[18];
uniform mat4 MV;
uniform mat4 MVP;
uniform vec3 LightPos;
uniform mat3 N; 
//uniform mat3 VertexNormal;
in vec3 P;
in vec3 V;
in vec3 L;

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
            //10.0  
            20.0                  // Shininess
            );



//wood stuff

/*****SETTING UP THE NOISE FOR THE SPEC MAP SMUDGES****/
/******************************************************
  * The following simplex noise functions have been taken from WebGL-noise
  * https://github.com/stegu/webgl-noise/blob/master/src/noise2D.glsl
  *>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                + i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}
/*********** END REFERENCE ************************/

/***************************************************
  * This function is ported from
  * https://cmaher.github.io/posts/working-with-simplex-noise/
  ****************************************************/
float sumOctave(in vec2 pos,
                in int num_iterations,
                in float persistence,
                in float scale,
                in float low,
                in float high) {
    float maxAmp = 0.0f;
    float amp = 1.0f;
    float freq = scale;
    float noise = 0.0f;
    int i;

    for (i = 0; i < num_iterations; ++i) {
        noise += snoise(pos * freq) * amp;
        maxAmp += amp;
        amp *= persistence;
        freq *= 2.0f;
    }
    noise /= maxAmp;
    noise = noise*(high-low)*0.5f + (high+low)*0.5f;
    return noise;
}



/*******************************************************/

    //rotation matrix
    mat4 rotationMatrix(vec3 axis, float angle)
    {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
    }

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

vec3 calculateLightIntensity(vec3 lightPos, vec3 lightCol, vec3 p, vec3 n, vec3 v, vec2 fragTexCoord)
{
  //lightCol = lightCol / 5;
    lightPos = (MV * vec4(lightPos, 1.f)).xyz;
    vec3 s = normalize(lightPos - p); //this is s for the h equation

    // Reflect the light about the surface normal
    vec3 r = reflect( -s, n );

    //creating a roughness value
    vec3 h = normalize(v+s);

    //Creating the lookup vector for cube map.
    vec3 lookup = reflect(v, n);

    // Distribution function
     
    float m = 0.3;
  
    /***********************************************************************/


    float mSquared = m*m;
    float NdotH = dot(n, h); //dot product of surface and light position
    float VdotH = dot(v, h); //dot product of surface and light position
    float NdotV = dot(n, v); //dot product of surface and light position
    float NdotL = dot(n, s); //dot product of surface and light position
    
    float r1  = 1.0 / (4.0f * mSquared * pow(NdotH, 4.0f));
    float r2 = (NdotH * NdotH - 1.0) / (mSquared * NdotH * NdotH);
    float D = r1 * exp(r2);
    
    // Geometric attenuation    
    float NH2 = 2.0 * NdotH;
    float eps = 0.0001f;
    float invVdotH = (VdotH > eps)?(1.0 / VdotH):1.0;    
    float g1 = (NH2 * NdotV) * invVdotH;
    float g2 = (NH2 * NdotL) * invVdotH;
    float G = min(1.0, min(g1, g2));   

    // Schlick approximation
    float F0 = 1.0f; // Fresnel reflectance at normal incidence
    float F_r = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 1.0; // Fresnel reflectance at normal incidence
    float F_g = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 1.0; // Fresnel reflectance at normal incidence
    float F_b = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    
    // Compute the light from the ambient, diffuse and specular components
    
    vec3 spec = G * vec3(F_r, F_g, F_b) * D / NdotV;
  
    spec = max(spec, 0.f);
    vec3 LightIntensity = (
            lightCol * max( dot(s, n), 0.0 ) +
            lightCol * spec);
    
    float dist = length(lightPos - FragmentPosition.xyz);
    
    //float falloff = 1.f/pow(dist, 2.f);
    float distLess = dist / 1.15f;
    float falloff = 1.f/(distLess * distLess);
    return LightIntensity*vec3(falloff, falloff, falloff);
}



void main()
{
   vec3 p = FragmentPosition.xyz / FragmentPosition.w;
        // Calculate the light vector
    vec3 s = normalize( vec3(Light.Position) - FragmentPosition.xyz ); 

    // Calculate the view vector
    vec3 v = vec3(0.f, 0.f, 1.f);

    // Calculate the normal (this is the expensive bit in Phong)
    vec3 n = normalize( FragmentNormal );

    // ***********************************************************
    // What you'll need to do here is rotate n based on the normal
    // provided in the normal map. After this, the lighting
    // calculations will work below.
    // ***********************************************************

    //gets the RGB value of the current value
    vec3 normalMapColour = texture(woodNormal, FragmentTexCoord*6).rgb;
    //scaling the vector
    normalMapColour = normalize(normalMapColour*2 - 1);

    //finding the angle where cosx = a dot b
    float cosAngle = dot(normalMapColour, v);
    float angle = acos(cosAngle);
    //using the rotate function to rotate the normal of the teapot
    n = rotate(n,v, angle);

    // Reflect the light about the surface normal
    vec3 darkWood = vec3(0.015f, 0.007f, 0.001f);
    darkWood+=vec3(0.05f, 0.05f, 0.05f);
    vec3 lightWood = vec3(0.159f, 0.069f, 0.012f);
    lightWood+=vec3(0.05f, 0.05f, 0.05f);
    vec2 PP = FragmentTexCoord*2.f;
    float freq = 2.f;
    float variation = 0.1f;
    float l;
    float woodNoise = sumOctave(PP, 12, 0.5f, freq, 0.0f, 1.0f); //iterations, persistence, frequency, low, high  
    PP+=woodNoise*variation;
    float woodNoise2 = sumOctave(PP, 12, 0.5f, freq*2.1, 0.0f, 1.0f);
    PP+= woodNoise*variation/2.1;
    
    l=sqrt((PP.x*PP.x) + (PP.y*PP.y));
    FragColour = vec4(mix(darkWood, lightWood, mod(l*8, 1)),1.f);

    vec3 totalLightIntensity;
    for(int i=0; i<18; i++)
    {
      totalLightIntensity += calculateLightIntensity(lightPositions[i]*50, lightColours[i], p, n, v, FragmentTexCoord);
    }
    totalLightIntensity*=5000;

    FragColour *= vec4(totalLightIntensity, 1.0);
    //FragColour = vec4(lightColours[0], 1.0);
    //FragColour *= vec4(LightIntensity, 1.0);
   //FragColour = vec4(n, 1.f);

    
}

