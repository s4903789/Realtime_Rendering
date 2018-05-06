#include "envscene.h"

#include <glm/gtc/type_ptr.hpp>
#include <ngl/Obj.h>
#include <ngl/NGLInit.h>
#include <ngl/VAOPrimitives.h>
#include <ngl/ShaderLib.h>
#include <ngl/Image.h>
#include "glm/ext.hpp"
#include <ngl/NGLStream.h>


EnvScene::EnvScene() : Scene() {}

void EnvScene::initGL() noexcept
{
    // Fire up the NGL machinary (not doing this will make it crash)
    ngl::NGLInit::instance();
    glDepthRange(0.01f, 1000.f);
    // Set background colour
    glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
    // enable depth testing for drawing
    glEnable(GL_DEPTH_TEST);
    // enable multisampling for smoother drawing
    glEnable(GL_MULTISAMPLE);
    //initialising the default displacement factor
    m_displacementFactor = 1.f;
    //initialising the default noise factor
    m_noiseFactor = 0.f;

    //Set up parameters for rendering shadows
    m_lightPosition = glm::vec3(2.f, 2.f, -2.f);
    m_lightPOVMatrix = glm::lookAt(m_lightPosition, glm::vec3(0.f, 0.f, 0.f), glm::vec3(0.f, 1.f, 0.f));
    m_lightProj = glm::perspective(30.f, float(m_width)/float(m_height), 0.01f, 1000.f);
    initFBO();
    glViewport(0, 0, m_width, m_height);


    //Load in shaders
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();

    shader->loadShader("BananaProgram",
                       "shaders/banana_vert.glsl",
                       "shaders/banana_frag.glsl");
    shader->use("BananaProgram");
    initTexture(2, m_bananaTex, "textures/banana_hi_poly.png");
    shader->setUniform("bananaTex", 2);
    initTexture(3, m_bananaNormal, "images/NormalMap(1).jpg");
    shader->setUniform("normal",3);
    initTexture(5, m_noiseMap, "textures/noise_map.png");
    shader->setUniform("noiseMap", 5);
    initTexture(4, m_ramp, "textures/ramp.tif");
    shader->setUniform("ramp", 4);
    

    shader->loadShader("PlateProgram",
                       "shaders/plate_vert.glsl",
                       "shaders/plate_frag.glsl");
    shader->use("PlateProgram");
    initTexture(6, m_woodNormal, "textures/walnut.jpg");
    shader->setUniform("woodNormal",6);
    initTexture(7, m_woodPerturb, "textures/wood_perturb.jpg");
    shader->setUniform("perturbMap", 7);


    shader->loadShader("CubeProgram",
                       "shaders/cube_vert.glsl",
                       "shaders/cube_frag.glsl");

    initEnvironment();

    //Initialising the obj for the banana along with its texture
    m_mesh.reset(new ngl::Obj("models/small_banana_obj.obj"));//, "textures/banana_hi_poly.png"));
    std::cout<<"attempting to assign mesh \n";
    m_mesh->createVAO();
    std::cout<<"Vao made \n";
    //initialising the mesh for the bowl
    m_bowlMesh.reset(new ngl::Obj("models/Bowl_Super_Hi_Poly.obj"));
    std::cout<<"bowl loaded \n";
    m_bowlMesh->createVAO();
}

void EnvScene::loadToBananaShader()
{
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    (*shader)["BananaProgram"]->use();
    GLint pid = shader->getProgramID("BananaProgram");

    glUniform1f(glGetUniformLocation(pid, "noiseFactor"),
                                     m_noiseFactor);
    glUniform1f(glGetUniformLocation(pid, "displacementFactor"),
                                     m_displacementFactor);
    // Our MVP matrices
    glm::mat4 MVP, MV;
    glm::mat3 N;

    m_model = glm::mat4();
    m_model = glm::translate(m_model, glm::vec3(0.f, 0.2f, 0.f));

    // Note the matrix multiplication order as we are in COLUMN MAJOR storage
    MV = m_V * m_model;
    N = glm::inverse(glm::mat3(MV));
    MVP = m_P * MV;

    // Set this MVP on the GPU
    glUniform3fv(glGetUniformLocation(pid, "aimedEye"),
                                      1,
                                      glm::value_ptr(glm::vec3(m_aimedEye)));
    glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"), //location of uniform
                       1, // how many matrices to transfer
                       false, // whether to transpose matrix
                       glm::value_ptr(MVP)); // a raw pointer to the data
    glUniformMatrix4fv(glGetUniformLocation(pid, "MV"), //location of uniform
                       1, // how many matrices to transfer
                       false, // whether to transpose matrix
                       glm::value_ptr(MV)); // a raw pointer to the data
    glUniformMatrix3fv(glGetUniformLocation(pid, "N"), //location of uniform
                       1, // how many matrices to transfer
                       true, // whether to transpose matrix
                       glm::value_ptr(N)); // a raw pointer to the data
    glUniformMatrix4fv(glGetUniformLocation(pid, "invV"), //location of uniform
                       1, // how many matrices to transfer
                       false, // whether to transpose matrix
                       glm::value_ptr(glm::inverse(m_V))); // a raw pointer to the data

    for(int i = 0; i < 18; i++)
    {
        glUniform3fv(glGetUniformLocation(pid, ("lightPositions[" + std::to_string(i) + "]").c_str() ),
                     3,
                     glm::value_ptr(m_lightPositions[i]));
        glUniform3fv(glGetUniformLocation(pid, ("lightColours[" + std::to_string(i) + "]").c_str() ),
                     3,
                     glm::value_ptr(m_lightColours[i]));
    } 
}

void EnvScene::loadToBowlShader()
{
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    (*shader)["PlateProgram"]->use();
    GLint pid = shader->getProgramID("PlateProgram");

    m_model = glm::mat4();
    glm::mat4 MVP, MV;
    glm::mat3 N;

    MV = m_V * m_model;
    N = glm::inverse(glm::mat3(MV));
    MVP = m_P * MV;

    glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"), //location of uniform
                    1, // how many matrices to transfer
                    false, // whether to transpose matrix
                    glm::value_ptr(MVP)); // a raw pointer to the data
    glUniformMatrix4fv(glGetUniformLocation(pid, "MV"), //location of uniform
                    1, // how many matrices to transfer
                    false, // whether to transpose matrix
                    glm::value_ptr(MV)); // a raw pointer to the data
    glUniformMatrix3fv(glGetUniformLocation(pid, "N"), //location of uniform
                       1, // how many matrices to transfer
                       true, // whether to transpose matrix
                       glm::value_ptr(N)); // a raw pointer to the data

    for(int i = 0; i < 18; i++)
    {
        glUniform3fv(glGetUniformLocation(pid, ("lightPositions[" + std::to_string(i) + "]").c_str() ),
                     3,
                     glm::value_ptr(m_lightPositions[i]));
        glUniform3fv(glGetUniformLocation(pid, ("lightColours[" + std::to_string(i) + "]").c_str() ),
                     3,
                     glm::value_ptr(m_lightColours[i]));
    } 
}

void EnvScene::loadToEnvironment()
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

void EnvScene::paintGL() noexcept
{
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    // set the viewport to the screen dimensions
    glViewport(0, 0, m_width, m_height);
    // enable colour rendering again (as we turned it off earlier)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    // Clear the screen (fill with our glClearColor)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Set up the viewport
    glViewport(0,0,m_width,m_height);
    glDisable(GL_CULL_FACE);
    glCullFace(GL_BACK);

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

void EnvScene::initTexture(const GLuint& texUnit, GLuint &texId, const char *filename) {
    // Set our active texture unit
    glActiveTexture(GL_TEXTURE0 + texUnit);

    // Load up the image using NGL routine
    ngl::Image img(filename);

    // Create storage for our new texture
    glGenTextures(1, &texId);

    // Bind the current texture
    glBindTexture(GL_TEXTURE_2D, texId);

    // Transfer image data onto the GPU using the teximage2D call
    glTexImage2D (
                GL_TEXTURE_2D,    // The target (in this case, which side of the cube)
                0,                // Level of mipmap to load
                img.format(),     // Internal format (number of colour components)
                img.width(),      // Width in pixels
                img.height(),     // Height in pixels
                0,                // Border
                img.format(),          // Format of the pixel data
                GL_UNSIGNED_BYTE, // Data type of pixel data
                img.getPixels()); // Pointer to image data in memory

    // Set up parameters for our texture
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
}

/**
 * @brief Scene::initEnvironment in texture unit 0
 */

void EnvScene::initFBO()
{
  // Try to use a texture depth component
  glGenTextures(1, &m_fboTextureId);
  glBindTexture(GL_TEXTURE_2D, m_fboTextureId);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);


  glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
  glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

  glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, 1024, 1024, 0, GL_DEPTH_COMPONENT, GL_FLOAT, 0);

  glBindTexture(GL_TEXTURE_2D, 0);

  // create our FBO
  glGenFramebuffers(1, &m_fboId);
  glBindFramebuffer(GL_FRAMEBUFFER, m_fboId);
  // disable the colour and read buffers as we only want depth
  glDrawBuffer(GL_NONE);
  glReadBuffer(GL_NONE);

  // attach our texture to the FBO

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,GL_TEXTURE_2D, m_fboTextureId, 0);

  // switch back to window-system-provided framebuffer
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void EnvScene::initEnvironment() {
    // Enable seamless cube mapping
    glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

    // Placing our environment map texture in texture unit 0
    glActiveTexture (GL_TEXTURE0);

    // Generate storage and a reference for our environment map texture
    glGenTextures (1, &m_envTex);

    // Bind this texture to the active texture unit
    glBindTexture(GL_TEXTURE_CUBE_MAP, m_envTex);

    // Now load up the sides of the cube
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "textures/nz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "textures/pz.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "textures/ny.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "textures/py.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "textures/nx.jpg");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_X, "textures/px.jpg");

    // Generate mipmap levels
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    // Set the texture parameters for the cube map
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_GENERATE_MIPMAP, GL_TRUE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GLfloat anisotropy;
    glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &anisotropy);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropy);

    // Set our cube map texture to on the shader so we can use it
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    shader->use("BananaProgram");
    shader->setUniform("envMap", 0);
    shader->use("CubeProgram");
    shader->setUniform("envMap", 0);
}

/**
 * @brief Scene::initEnvironmentSide
 * @param texture
 * @param target
 * @param filename
 * This function should only be called when we have the environment texture bound already
 * copy image data into 'target' side of cube map
 */
void EnvScene::initEnvironmentSide(GLenum target, const char *filename) {
    // Load up the image using NGL routine
    ngl::Image img(filename);

    // Transfer image data onto the GPU using the teximage2D call
    glTexImage2D (
      target,           // The target (in this case, which side of the cube)
      0,                // Level of mipmap to load
      img.format(),     // Internal format (number of colour components)
      img.width(),      // Width in pixels
      img.height(),     // Height in pixels
      0,                // Border
      img.format(),          // Format of the pixel data
      GL_UNSIGNED_BYTE, // Data type of pixel data
      img.getPixels()   // Pointer to image data in memory
    );
}
