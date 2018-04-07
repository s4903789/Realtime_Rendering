#version 420 core

// Attributes passed on from the vertex shader
smooth in vec3 FragmentPosition;
smooth in vec3 FragmentNormal;
smooth in vec2 FragmentTexCoord;

/// @brief our output fragment colour
layout (location=0) out vec4 FragColour;

// A texture unit for storing the 3D texture
uniform samplerCube envMap;
uniform sampler2D glossMap;
uniform sampler2D banana;
uniform sampler2D normal;
uniform sampler2D tex;
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
            vec3(0.05, 0.05, 0.05)
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

void main () {
    // Calculate the normal (this is the expensive bit in Phong)
    vec3 n = normalize( FragmentNormal );

    // Calculate the eye vector
    vec3 v = normalize(vec3(-FragmentPosition));

    /*vec3 normalValue = normalize(texture(normal, FragmentTexCoord).xyz);
    float cosAngle = dot(n, normalValue);
    float angle = acos(cosAngle);
    n = rotate(v,n,angle);*/
    //using the roughness calculations worked out in Realtime_Rendering/myshader_frag.glsl
    
    /*******************************************************************************/
    vec3 p = FragmentPosition.xyz; /// FragmentPosition.w;
      // Calculate the light vector
    vec3 s = normalize( vec3(Light.Position) - p); //this is s for the h equation

    // Reflect the light about the surface normal
    vec3 r = reflect( -s, n );

    //creating a roughness value
    vec3 h = normalize(v+s);

    // Distribution function
    float m = 0.2;
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
    float F0 = 0.9; // Fresnel reflectance at normal incidence
    float F_r = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 0.9; // Fresnel reflectance at normal incidence
    float F_g = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    F0 = 0.9; // Fresnel reflectance at normal incidence
    float F_b = pow(1.0 - VdotH, 5.0) * (1.0 - F0) + F0;    
    
    // Compute the light from the ambient, diffuse and specular components
    
    vec3 spec = G * vec3(F_r, F_g, F_b) * D / NdotV;
    //float spec = G * F * D / NdotV;
    vec3 LightIntensity = (
            Light.La * Material.Ka +
            Light.Ld * Material.Kd * max( dot(s, n), 0.0 ) +
            Light.Ls * Material.Ks * spec);  

    /************************************************************************/

    // Here you will need to use the environment map and with a lookup vector
    // which you've determined to get a colour to display.
    vec3 lookup = reflect(v, n);
    vec4 mapColour = texture(envMap, lookup);
    // Next you will need to use the LOD value to "smudge" the incoming light
    // from the environment.
    float blurValue = texture(glossMap, FragmentTexCoord).x * 8;
    vec4 bananaDiffuse = texture(banana, FragmentTexCoord);
    vec4 lodMapColour = textureLod(envMap, lookup, blurValue);
    lodMapColour = lodMapColour * texture(banana, FragmentTexCoord);
    //lodMapColour = lodMapColour + texture(banana, FragmentTexCoord);
    // Next you will need to used a gloss map to determine the level of "smudge"
    //FragColour = vec4(lodMapColour.xyz*LightIntensity,1.0); //colour;
    
    //FragColour = vec4(bananaDiffuse.xyz * LightIntensity,1.0);

    FragColour = texture(glossMap, vec2(FragmentTexCoord.x, -FragmentTexCoord.y));
    FragColour *= vec4(LightIntensity,1.0);
}

