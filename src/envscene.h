#ifndef ENVSCENE_H
#define ENVSCENE_H
#include <memory>

#include <ngl/Obj.h>
#include "scene.h"


class EnvScene : public Scene
{
public:
    EnvScene();

    /// Called when the scene needs to be painted
    void paintGL() noexcept;

    /// Called when the scene is to be initialised
    void initGL() noexcept;

private:
    /// The ID of our environment texture
    GLuint m_envTex, m_glossMapTex, m_bananaTex,m_bananaNormal, m_ramp, m_noiseMap, m_woodNormal, m_woodPerturb;

    /// Initialise the entire environment map
    void initEnvironment();

    /*************SHADOWS************/
    void loadToLightPOVShader();
    void loadMatricesToShadowShader();
    ngl::Mat4 m_mouseGlobalTX;
    ngl::Camera m_cam;



    /********************************/

    /// Utility function for loading up a 2D texture
    void initTexture(const GLuint&, GLuint &, const char *);

    /// Initialise a single side of the environment map
    void initEnvironmentSide(GLenum /*target*/, const char* /*filename*/);

    std::unique_ptr<ngl::Obj> m_mesh;
    std::unique_ptr<ngl::Obj> m_vertexMesh;
    std::unique_ptr<ngl::Obj> m_bowlMesh;

};

#endif // MYSCENE_H
