#include "banana_scene.h"

#include <glm/gtc/type_ptr.hpp>
#include <ngl/Obj.h>
#include <ngl/NGLInit.h>
#include <ngl/VAOPrimitives.h>
#include <ngl/ShaderLib.h>
#include <ngl/Image.h>
#include "glm/ext.hpp"
#include <ngl/NGLStream.h>


BananaScene::BananaScene() : Scene() {}

void BananaScene::initGL() noexcept
{
    ngl::NGLInit::instance();
    glDepthRange(0.01f, 1000.f);
    glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_MULTISAMPLE);
    //Initialising the default displacement factor
    m_displacementFactor = 1.f;
    //Initialising the default noise factor
    m_noiseFactor = 0.f;

    glViewport(0, 0, m_width, m_height);

    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    //Loading shader for banana
    shader->loadShader("BananaProgram",
                       "shaders/banana_vert.glsl",
                       "shaders/banana_frag.glsl");
    shader->use("BananaProgram");
    /****Texture for banana based off https://cdna.artstation.com/p/assets/images/images/004/035/678/large/zaczphere-zac-goh-banana.jpg?1479710308 ***/
    /****Edited by myself in ZBrush polypaint to add small details and to fit the banana geometry properly***/
    initTexture(2, m_bananaTex, "textures/banana_hi_poly.png");
    shader->setUniform("bananaTex", 2);
    initTexture(3, m_bananaNormal, "textures/NormalMap(1).jpg");
    shader->setUniform("normal",3);
    initTexture(5, m_noiseMap, "textures/banana_noise.jpg");
    shader->setUniform("noiseMap", 5);
    initTexture(4, m_ramp, "textures/ramp.tif"); //Ramp texture used for contrast function
    shader->setUniform("ramp", 4);
    

    shader->loadShader("BowlProgram",
                       "shaders/bowl_vert.glsl",
                       "shaders/bowl_frag.glsl");
    shader->use("BowlProgram");
    initTexture(6, m_woodNormal, "textures/walnut.jpg");
    shader->setUniform("woodNormal",6);
    initTexture(7, m_woodPerturb, "textures/wood_perturb.jpg");
    shader->setUniform("perturbMap", 7); //Loading shaders and files for bowl


    shader->loadShader("CubeProgram",
                       "shaders/cube_vert.glsl",
                       "shaders/cube_frag.glsl"); //Shader loaded for environment

    initEnvironment();

    //Initialising the obj for the banana along with its texture
    m_mesh.reset(new ngl::Obj("models/small_banana_obj.obj"));
    m_mesh->createVAO();
    //Initialising the mesh for the bowl
    m_bowlMesh.reset(new ngl::Obj("models/Bowl_Super_Hi_Poly.obj"));
    m_bowlMesh->createVAO();
}

void BananaScene::loadToBananaShader()
{
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    (*shader)["BananaProgram"]->use();
    GLint pid = shader->getProgramID("BananaProgram");

    glUniform1f(glGetUniformLocation(pid, "noiseFactor"),
                                     m_noiseFactor);
    glUniform1f(glGetUniformLocation(pid, "displacementFactor"),
                                     m_displacementFactor);
    glm::mat4 MVP, MV;
    glm::mat3 N;

    m_model = glm::mat4();
    m_model = glm::translate(m_model, glm::vec3(0.f, 0.2f, 0.f));

    MV = m_V * m_model;
    N = glm::inverse(glm::mat3(MV));
    MVP = m_P * MV;

    glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"), 
                       1, 
                       false, 
                       glm::value_ptr(MVP)); 
    glUniformMatrix4fv(glGetUniformLocation(pid, "MV"), 
                       1, 
                       false, 
                       glm::value_ptr(MV)); 
    glUniformMatrix3fv(glGetUniformLocation(pid, "N"), 
                       1, 
                       true, 
                       glm::value_ptr(N)); 
    glUniformMatrix4fv(glGetUniformLocation(pid, "invV"), 
                       1, 
                       false, 
                       glm::value_ptr(glm::inverse(m_V))); 

    for(int i = 0; i < 18; i++)
    {
        glUniform3fv(glGetUniformLocation(pid, ("lightPositions[" + std::to_string(i) + "]").c_str() ),
                     1,
                     glm::value_ptr(m_lightPositions[i]));
        glUniform3fv(glGetUniformLocation(pid, ("lightColours[" + std::to_string(i) + "]").c_str() ),
                     1,
                     glm::value_ptr(m_lightColours[i]));
    } 
}

void BananaScene::loadToBowlShader()
{
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    (*shader)["BowlProgram"]->use();
    GLint pid = shader->getProgramID("BowlProgram");

    m_model = glm::mat4();
    glm::mat4 MVP, MV;
    glm::mat3 N;

    MV = m_V * m_model;
    N = glm::inverse(glm::mat3(MV));
    MVP = m_P * MV;

    glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"), 
                    1, 
                    false, 
                    glm::value_ptr(MVP)); 
    glUniformMatrix4fv(glGetUniformLocation(pid, "MV"), 
                    1, 
                    false, 
                    glm::value_ptr(MV)); 
    glUniformMatrix3fv(glGetUniformLocation(pid, "N"), 
                       1, 
                       true, 
                       glm::value_ptr(N)); 

    for(int i = 0; i < 18; i++)
    {
        glUniform3fv(glGetUniformLocation(pid, ("lightPositions[" + std::to_string(i) + "]").c_str() ),
                     1,
                     glm::value_ptr(m_lightPositions[i]));
        glUniform3fv(glGetUniformLocation(pid, ("lightColours[" + std::to_string(i) + "]").c_str() ),
                     1,
                     glm::value_ptr(m_lightColours[i]));
    } 
}

void BananaScene::loadToEnvironment() //Loads uniforms to environment
{
  ngl::ShaderLib *shader=ngl::ShaderLib::instance();
  (*shader)["CubeProgram"]->use();
  GLint pid = shader->getProgramID("CubeProgram");

  glm::mat4 M, MV, MVP;

  M = glm::scale(M, glm::vec3(80.f, 80.f, 80.f));
  MV = m_cubeMatrix * M;
  MVP = m_P * MV;

  glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"),
                     1,
                     false,
                     glm::value_ptr(MVP));
  glUniformMatrix4fv(glGetUniformLocation(pid, "MV"),
                     1,
                     false,
                     glm::value_ptr(MV));
}

void BananaScene::paintGL() noexcept
{
    glBindFramebuffer(GL_FRAMEBUFFER,0);
  
    glViewport(0, 0, m_width, m_height);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glViewport(0,0,m_width,m_height);

    loadToBananaShader();
    m_model = glm::mat4();
    m_model = glm::translate(m_model, glm::vec3(0.f, 0.2f, 0.f));
    m_mesh->draw();

    loadToBowlShader();
    m_model = glm::mat4();
    m_bowlMesh->draw();

    loadToEnvironment();
    ngl::VAOPrimitives *prim = ngl::VAOPrimitives::instance();
    prim->draw("cube");
    
}

void BananaScene::initTexture(const GLuint& texUnit, GLuint &texId, const char *filename) {

    glActiveTexture(GL_TEXTURE0 + texUnit);

    ngl::Image img(filename);

    glGenTextures(1, &texId);

    glBindTexture(GL_TEXTURE_2D, texId);

    glTexImage2D (
                GL_TEXTURE_2D,    
                0,                
                img.format(),     
                img.width(),     
                img.height(),     
                0,                
                img.format(),         
                GL_UNSIGNED_BYTE, 
                img.getPixels()); 

    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
}

void BananaScene::initEnvironment() {
    
    glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

    
    glActiveTexture (GL_TEXTURE0);

    //Storing the depth of field blurred environment in texture unit 1
    glGenTextures (1, &m_envTexBlurred);

    glBindTexture(GL_TEXTURE_CUBE_MAP, m_envTexBlurred);

    /***HDRI acquired from https://i.pinimg.com/originals/c8/da/6e/c8da6e88f6da56e3affe74b3d645e675.jpg ***/
    //These textures have been blurred to achieve a depth of field effect

    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "textures/blur/nz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "textures/blur/pz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "textures/blur/ny.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "textures/blur/py.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "textures/blur/nx.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_X, "textures/blur/px.jpg");

    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_GENERATE_MIPMAP, GL_TRUE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GLfloat anisotropy;
    glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &anisotropy);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropy);

    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    shader->use("CubeProgram");
    shader->setUniform("envMap", 0);
    
    glActiveTexture (GL_TEXTURE1);

    glGenTextures (1, &m_envTex);

    glBindTexture(GL_TEXTURE_CUBE_MAP, m_envTex);
    //These are the sharp cube textures used to generate the spec on the banana
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "textures/nz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "textures/pz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "textures/ny.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "textures/py.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "textures/nx.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_X, "textures/px.jpg");

    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_GENERATE_MIPMAP, GL_TRUE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &anisotropy);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropy);
    shader->use("BananaProgram");
    shader->setUniform("envMap", 1);
}


void BananaScene::initEnvironmentSide(GLenum target, const char *filename) {

    ngl::Image img(filename);

    glTexImage2D (
      target,           
      0,                
      img.format(),     
      img.width(),     
      img.height(),     
      0,              
      img.format(),          
      GL_UNSIGNED_BYTE, 
      img.getPixels()   
    );
}
