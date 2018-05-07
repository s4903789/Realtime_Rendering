#ifndef BANANA_SCENE_H
#define BANANA_SCENE_H
#include <memory>

#include <ngl/Obj.h>
#include "scene.h"
#include <ngl/Mat4.h>
#include <ngl/Camera.h>
#include <ngl/Transformation.h>


class BananaScene : public Scene
{
public:
    BananaScene();

    /// Called when the scene needs to be painted
    void paintGL() noexcept;

    /// Called when the scene is to be initialised
    void initGL() noexcept;

    float m_displacementFactor;
    float m_noiseFactor;

private:
    /// The ID of our environment texture
    GLuint m_envTex,
           m_envTexBlurred,
           m_bananaTex,
           m_bananaNormal,
           m_ramp,
           m_noiseMap,
           m_woodNormal,
           m_woodPerturb,
           
           m_fboId,
           m_fboTextureId,
           m_fboDepthId;

    /// Initialise the entire environment map
    void initEnvironment();

    glm::mat4 m_model;

    /*************SHADOWS************/
    void loadToLightPOVShader();
    void loadMatricesToShadowShader();
    void loadToEnvironment();
    glm::vec3 m_lightPosition;
    glm::mat4 m_lightPOVMatrix;
    glm::mat4 m_lightProj;
    /********************************/

    /***********LIGHTS FOR ENV MAP************/
    std::array<glm::vec3, 18> m_lightPositions = {glm::vec3(2.271f, 0.955f, -4.715f),
                                                glm::vec3(2.849f, 0.955f, -2.152f),
                                                glm::vec3(2.849f, 0.955f, -1.087f),
                                                glm::vec3(3.722f, -0.726f, -2.983f),
                                                glm::vec3(2.849f, -0.726f, -1.141f),
                                                glm::vec3(4.086f, 0.231f, 2.872f), //main light for shadow mapping
                                                glm::vec3(4.259f, 0.231f, 4.766f),
                                                glm::vec3(-2.702f, 0.996f, 3.003f),
                                                glm::vec3(-2.702f, 0.996f, 1.880f),
                                                glm::vec3(-2.702f, 0.312f, -2.919f),
                                                glm::vec3(-2.702f, 0.774f, -4.108),
                                                glm::vec3(2.466f, -1.139f, -3.864f),
                                                glm::vec3(2.442f, -1.176f, 2.554f),
                                                glm::vec3(0.296f, 2.024f, 0.119f),
                                                glm::vec3(-1.777f, 0.678f, -0.149f),
                                                glm::vec3(-0.743f, 1.530f, -0.149f),
                                                glm::vec3(0.114f, -1.595f, -0.001f),
                                                glm::vec3(-2.179, -0.327, -3.417)};
    
    std::array<glm::vec3, 18> m_lightColours = {glm::vec3(0.959f, 0.946f, 0.680f), //0
                                              glm::vec3(0.454f, 0.442f, 0.374f), //1
                                              glm::vec3(0.982f, 0.982f, 0.965f), //2
                                              glm::vec3(0.412f, 0.430f, 0.468f), //3
                                              glm::vec3(0.f, 0.f, 0.f), //4
                                              glm::vec3(0.807f, 0.738f, 0.527f), //main light for shadow mapping 5
                                              glm::vec3(0.982f, 0.999f, 0.990f), //6
                                              glm::vec3(0.794f, 0.713f, 0.211f), //7
                                              glm::vec3(0.804f, 0.854f, 0.286f), //8
                                              glm::vec3(0.761f, 0.728f, 0.513f), //9
                                              glm::vec3(0.334f, 0.251f, 0.148f), //10
                                              glm::vec3(0.476f, 0.228f, 0.105f), //11
                                              glm::vec3(0.680f, 0.457f, 0.314f), //12
                                              glm::vec3(0.997f, 0.979f, 0.835f), //13
                                              glm::vec3(0.216f, 0.216f, 0.175f), //14
                                              glm::vec3(0.109f, 0.073f, 0.046f),
                                              glm::vec3(0.307f, 0.169f, 0.057f),
                                              glm::vec3(0.316f, 0.215f, 0.083f)}; //15






    void loadToBananaShader();
    void loadToBowlShader();

    /// Utility function for loading up a 2D texture
    void initTexture(const GLuint&, GLuint &, const char *);

    /// Initialise a single side of the environment map
    void initEnvironmentSide(GLenum /*target*/, const char* /*filename*/);

    void initFBO();

    std::unique_ptr<ngl::Obj> m_mesh;
    std::unique_ptr<ngl::Obj> m_vertexMesh;
    std::unique_ptr<ngl::Obj> m_bowlMesh;

};

#endif // MYSCENE_H
