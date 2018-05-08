#version 420 core

smooth in vec4 FragmentPosition;
smooth in vec3 FragmentNormal;
smooth in vec2 FragmentTexCoord;

layout (location=0) out vec4 FragColour;

uniform samplerCube envMap;
uniform sampler2D bananaTex;
uniform sampler2D banana;
uniform sampler2D normal;
uniform sampler2D ramp;
uniform sampler2D tex;

//Setting the light colour and positions for all the lights corresponding to the env cube
uniform vec3 lightPositions[18];
uniform vec3 lightColours[18];
uniform mat4 MV;

//Setting the factor to multiply the noise by, depending on how old the banana should be
uniform float noiseFactor;
// Set the maximum environment level of detail
uniform int envMaxLOD = 10;

uniform mat4 invV;

//The rotation matrix used in calculations for the normal map
mat4 rotationMatrix(vec3 axis, float angle) {
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

struct LightInfo {
    vec4 Position; // Light position in eye coords.
    vec3 La; // Ambient light intensity
    vec3 Ld; // Diffuse light intensity
    vec3 Ls; // Specular light intensity
};

uniform LightInfo Light = LightInfo(
            vec4(2.0, 2.0, 10.0, 1.0),   // position
            vec3(1.0, 1.0, 1.0),        // La
            vec3(1.0, 1.0, 1.0),        // Ld       
            vec3(0.1, 0.1, 0.1)         // Ls
            );

struct MaterialInfo {
    vec3 Ka; // Ambient reflectivity
    vec3 Kd; // Diffuse reflectivity
    vec3 Ks; // Specular reflectivity
    float Shininess; // Specular shininess factor
};

uniform MaterialInfo Material = MaterialInfo(
            vec3(0.1, 0.1, 0.1),    // Ka
            vec3(1.0, 1.0, 1.0),    // Kd
            vec3(1.0, 1.0, 1.0),    // Ks
            10.0                  // Shininess
            );

/****Noise functions appropriated from the noise demo in the rendering_examples directory****/
/* The following simplex noise functions have been taken from WebGL-noise
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
  const vec4 C = vec4(0.211324865405187,  
                      0.366025403784439,  
                     -0.577350269189626,  
                      0.024390243902439); 
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                + i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
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
/*********** END REFERENCE ************************/

vec3 invert(vec3 _value)
{
  _value *= -1;
  _value += 1;
  return _value;
}

vec4 invert(vec4 _value)
{
  _value *= -1;
  _value += 1;
  return _value;
}

float contrast(float _value)
{
  return _value *= texture(ramp, vec2(_value.r, 0.5)).r;
}

//Function to calculate the resulting light intensity based on the light positions and intensities
//specified in banana_scene.h
vec3 calculateLightIntensity(vec3 lightPos, vec3 lightCol, vec3 p, vec3 n, vec3 v, vec2 fragTexCoord, float noise, vec3 lookup)
{
    lightPos = (MV * vec4(lightPos, 1.f)).xyz;
    vec3 s = normalize(lightPos - p); 

    vec3 r = reflect( -s, n );

    vec3 h = normalize(v+s);

    //Setting up roughness for when it encounters speckles, it should be rougher
    vec4 roughColourCheck = texture(bananaTex, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
    float m = 0.5;
    if(roughColourCheck.g < 0.57)
    {
        m = 1.0;
    } 

    float mSquared = m*m;
    float NdotH = dot(n, h); 
    float VdotH = dot(v, h); 
    float NdotV = dot(n, v); 
    float NdotL = dot(n, s); 
    
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
    float F0 = 0.05; // Fresnel reflectance at normal incidence
    float F_r = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 0.05; // Fresnel reflectance at normal incidence
    float F_g = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 0.05; // Fresnel reflectance at normal incidence
    float F_b = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    
    vec3 spec = G * vec3(F_r, F_g, F_b) * D / NdotV;
    //Using the lookup vector from the envMap to determine the specular colour
    vec3 specColour = textureLod(envMap, lookup, m*envMaxLOD).rgb;

   
    spec *= noise * noise;
    spec = max(spec, 0.f);
    vec3 LightIntensity = (
            lightCol * max( dot(s, n), 0.0 ) +
            specColour * spec);
    
    float dist = length(lightPos - FragmentPosition.xyz);
  
    float distLess = dist / 1.6f;
    float falloff = 1.f/(distLess * distLess);
    //Calculating the falloff of the light (attentuation)
    return LightIntensity*vec3(falloff, falloff, falloff);
}


void main () {

    vec3 n = normalize( FragmentNormal );

    vec3 v = normalize(vec3(-FragmentPosition));

    //Creating the lookup vector for cube map.
    vec3 lookup = reflect(v, n);

    vec2 minusZ = vec2(FragmentTexCoord.x, -FragmentTexCoord.y);
    vec3 normalValue = normalize(texture(normal, minusZ).xyz);
    float cosAngle = dot(n, normalValue);
    float angle = acos(cosAngle);

    n = rotate(v,n,angle);

    vec4 roughColourCheck = texture(bananaTex, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
    float m = 0.2;
    if(roughColourCheck.r < 0.57)
    {
        m = 1.0;
    }
    
    vec3 p = FragmentPosition.xyz / FragmentPosition.w;

    float blurValue = texture(bananaTex, FragmentTexCoord).x * 8;
    vec4 bananaDiffuse = texture(banana, FragmentTexCoord);
    //Creating the noise values that will determine the marks on the banana
    float speckleNoise = sumOctave(FragmentTexCoord, 12, 0.5f, 20.0f, 0.0f, 1.0f); //iterations, persistence, frequency, low, high
    float maskNoise1 = sumOctave(FragmentTexCoord, 12, 0.5f, 30.0f, 0.0f, 1.0f);
    float maskNoise2 = sumOctave(FragmentTexCoord, 12, 0.5f, 2.0f, 0.0f, 1.0f);
    float maskNoise3 = sumOctave(FragmentTexCoord, 12, 0.5f, 50.0f, 0.0f, 1.0f);
    float maskNoise4 = sumOctave(FragmentTexCoord, 12, 0.5f, 20.0f, 0.0f, 1.0f);
    speckleNoise = speckleNoise * maskNoise1 * maskNoise2 * maskNoise3 * maskNoise4;

    vec4 speckleColour = vec4(0.356f, 0.149f, 0.027f, 1.0f);
    speckleNoise*= 4;

    if (speckleNoise > 1.0f)
    {
      speckleNoise = 1.0f; 
    }

    float patchNoise = sumOctave(FragmentTexCoord, 12, 0.5f, 5.0f, 0.0f, 1.0f);
    float maskNoise5 = sumOctave(FragmentTexCoord, 12, 0.5f, 7.0f, 0.0f, 1.0f);
    float maskNoise6 = sumOctave(vec2(FragmentTexCoord.x * 3, FragmentTexCoord.y), 12, 0.5f, 6.0f, 0.0f, 1.0f);
    patchNoise = patchNoise * maskNoise5 * maskNoise6;
    patchNoise*= 3;

    if (patchNoise > 1.f)
    {
      patchNoise = 1.f;
    }

    float bruiseNoise = sumOctave(FragmentTexCoord, 12, 0.5f, 6.0f, 0.0f, 1.f);
    bruiseNoise /= maskNoise6;
 
    if (bruiseNoise > 1.f)
    {
      bruiseNoise = 1.f;
    }
    bruiseNoise = (bruiseNoise * -1) + 1;

    FragColour = texture(bananaTex, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
  
    //Increase contrast of the noise
    bruiseNoise = contrast(bruiseNoise);

    //This sets bruiseNoiseColour to be black with the inverse of brown spots
    vec4 bruiseNoiseColour = (bruiseNoise * invert(vec4(0.2, 0.176, 0.075, 1.f)));
    bruiseNoiseColour*= noiseFactor*1.3;
    //This then inverts it to be white with brown spots so that it can be multiplied with the diffuse
    bruiseNoiseColour = invert(bruiseNoiseColour);
    
    vec4 patchColour = vec4(0.176, 0.086, 0.039, 1.f);
    /***********Blend function acquired from https://github.com/jamieowen/glsl-blend/blob/master/normal.glsl***/
    vec4 blend = noiseFactor * patchColour * patchNoise + FragColour * (1.0f - noiseFactor *patchNoise);
    blend = noiseFactor * speckleColour * speckleNoise + blend * (1.0f - noiseFactor *speckleNoise);
    float noiseForSpec = sumOctave(FragmentTexCoord, 12, 0.5f, 2.0f, 0.0f, 1.0f);
    vec3 totalLightIntensity;
    for(int i=0; i<16; i++)
    {
      totalLightIntensity += calculateLightIntensity(lightPositions[i]*50, lightColours[i], p, n, v, FragmentTexCoord, noiseForSpec, lookup);
    }


    totalLightIntensity*=3000;

    FragColour = blend * vec4(bruiseNoiseColour);
    FragColour*= vec4(totalLightIntensity, 1.0);
    }
    

