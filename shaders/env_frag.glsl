#version 420 core

// Attributes passed on from the vertex shader
smooth in vec4 FragmentPosition;
smooth in vec3 FragmentNormal;
smooth in vec2 FragmentTexCoord;

/// @brief our output fragment colour
layout (location=0) out vec4 FragColour;

// A texture unit for storing the 3D texture
uniform samplerCube envMap;
uniform sampler2D glossMap;
uniform sampler2D banana;
uniform sampler2D normal;
uniform sampler2D ramp;
uniform sampler2D tex;

//Setting the light colour and positions for all the lights corresponding to the env cube
uniform vec3 lightPositions[13];
uniform vec3 lightColours[13];
// Set the maximum environment level of detail (cannot be queried from GLSL apparently)
// The mipmap level is determined by log_2(resolution), so if the texture was 4x4,
// there would be 8 mipmap levels (128x128,64x64,32x32,16x16,8x8,4x4,2x2,1x1).
// The LOD parameter can be anything inbetween 0.0 and 8.0 for the purposes of
// trilinear interpolation.
uniform int envMaxLOD = 8;

// The inverse View matrix
uniform mat4 invV;

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
/*****************************************************/
//Lights, materials and stuff from Realtime_Rendering/myshader_frag.glsl
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
            vec3(1.0, 1.0, 1.0),        // La
            vec3(1.0, 1.0, 1.0),        // Ld
            //vec3(1.0, 1.0, 1.0)         // Ls
            vec3(0.1, 0.1, 0.1)
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
/*****************************************************************************/
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


vec3 calculateLightIntensity(vec3 lightPos, vec3 lightCol, vec3 p, vec3 n, vec3 v, vec2 fragTexCoord)
{
    vec3 s = normalize(vec3(lightPos) - p); //this is s for the h equation

    // Reflect the light about the surface normal
    vec3 r = reflect( -s, n );

    //creating a roughness value
    vec3 h = normalize(v+s);

    //Creating the lookup vector for cube map.
    vec3 lookup = reflect(v, n);

    // Distribution function
    
    /***********************************************************************/
    //setting up roughness for when it encounters speckles, it should be rougher
    //using the roughness calculations worked out in Realtime_Rendering/myshader_frag.glsl
        vec4 roughColourCheck = texture(glossMap, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
        float m = 0.2;
        if(roughColourCheck.r < 0.57)
        {
            m = 1.0;
        }

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
    float F0 = 1.0; // Fresnel reflectance at normal incidence
    float F_r = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 1.0; // Fresnel reflectance at normal incidence
    float F_g = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 1.0; // Fresnel reflectance at normal incidence
    float F_b = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    
    // Compute the light from the ambient, diffuse and specular components
    
    vec3 spec = G * vec3(F_r, F_g, F_b) * D / NdotV;
    ///////////////////////////////////////////////////
    //float noise = sumOctave(FragmentTexCoord, 12, 0.5f, 10.0f, 0.0f, 1.0f);
    float noise = sumOctave(FragmentTexCoord, 12, 0.5f, 2.0f, 0.0f, 1.0f);
    //float spec = G * F * D / NdotV;
    spec *= noise * noise;
    spec = max(spec, 0.f);
    vec3 LightIntensity = (
            lightCol * max( dot(s, n), 0.0 ) +
            lightCol * spec);
    
    float dist = length(lightPos - FragmentPosition.xyz);
    
    float falloff = 1/pow(dist, 2);

    return LightIntensity*vec3(falloff, falloff, falloff);
}


void main () {
    // Calculate the normal (this is the expensive bit in Phong)
    vec3 n = normalize( FragmentNormal );

    // Calculate the eye vector
    vec3 v = normalize(vec3(-FragmentPosition));

    vec2 minusZ = vec2(FragmentTexCoord.x, -FragmentTexCoord.y);
    vec3 normalValue = normalize(texture(normal, minusZ).xyz);
    float cosAngle = dot(n, normalValue);
    float angle = acos(cosAngle);
    n = rotate(v,n,angle);
    //using the roughness calculations worked out in Realtime_Rendering/myshader_frag.glsl
    vec4 roughColourCheck = texture(glossMap, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
    float m = 0.2;
    if(roughColourCheck.r < 0.57)
    {
        m = 1.0;
    }
    
    /*******************************************************************************/
    vec3 p = normalize(FragmentPosition.xyz / FragmentPosition.w);
      // Calculate the light vector

  

    /************************************************************************/

    // Here you will need to use the environment map and with a lookup vector
    // which you've determined to get a colour to display.
    
    //vec4 mapColour = texture(envMap, lookup);
    // Next you will need to use the LOD value to "smudge" the incoming light
    // from the environment.

    //vec4 lodMapColour = textureLod(envMap, lookup, blurValue);
    //lodMapColour = lodMapColour * texture(banana, FragmentTexCoord);
    //lodMapColour = lodMapColour + texture(banana, FragmentTexCoord);
    // Next you will need to used a gloss map to determine the level of "smudge"

    //FragColour = vec4(lodMapColour.xyz*LightIntensity,1.0); //colour;

    float blurValue = texture(glossMap, FragmentTexCoord).x * 8;
    vec4 bananaDiffuse = texture(banana, FragmentTexCoord);
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

    float bruiseNoise = sumOctave(FragmentTexCoord, 12, 0.5f, 6.0f, 0.0f, 1.0f);
    bruiseNoise /= maskNoise6;
   // bruiseNoise*= 3;
    if (bruiseNoise > 1.f)
    {
      bruiseNoise = 1.f;
    }
    bruiseNoise = (bruiseNoise * -1) + 1;

    if (speckleNoise > 1.f)
    {
      speckleNoise = 1.0f;
    }
    FragColour = texture(glossMap, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
  
    //Increase contrast of the noise
    bruiseNoise = contrast(bruiseNoise);

    //This sets bruiseNoiseColour to be black with the inverse of brown spots
    vec4 bruiseNoiseColour = (bruiseNoise * invert(vec4(0.2, 0.176, 0.075, 1.f)));

    //This then inverts it to be white with brown spots so that it can be multiplied with the diffuse
    bruiseNoiseColour = invert(bruiseNoiseColour);
    
    vec4 patchColour = vec4(0.176, 0.086, 0.039, 1.f);
    vec4 blend = patchColour * patchNoise + FragColour * (1.0f - patchNoise);
    blend = speckleColour * speckleNoise + blend * (1.0f - speckleNoise);

  //////////////////////LIGHTS/////////////////////////////////////////////
  vec3 totalLightIntensity;
  for(int i=0; i<13; i++)
  {
    totalLightIntensity += calculateLightIntensity(lightPositions[i], lightColours[i], p, n, v, FragmentTexCoord);
  }


    totalLightIntensity*=2;
    FragColour = blend * vec4(bruiseNoiseColour);
    FragColour*= vec4(totalLightIntensity, 1.0);

    
}

