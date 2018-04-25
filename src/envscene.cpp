#include "envscene.h"

#include <glm/gtc/type_ptr.hpp>
#include <ngl/Obj.h>
#include <ngl/NGLInit.h>
#include <ngl/VAOPrimitives.h>
#include <ngl/ShaderLib.h>
#include <ngl/Image.h>

EnvScene::EnvScene() : Scene() {}

void EnvScene::initGL() noexcept {
    // Fire up the NGL machinary (not doing this will make it crash)
    ngl::NGLInit::instance();

    // Set background colour
    glClearColor(0.4f, 0.4f, 0.4f, 1.0f);

    // enable depth testing for drawing
    glEnable(GL_DEPTH_TEST);

    // enable multisampling for smoother drawing
    glEnable(GL_MULTISAMPLE);

    // Create and compile the vertex and fragment shader
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    shader->loadShader("EnvironmentProgram",
                       "shaders/env_vert.glsl",
                       "shaders/env_frag.glsl");
    shader->use("EnvironmentProgram");
    shader->loadShader("PlateProgram", "shaders/plate_vert.glsl", "shaders/plate_frag.glsl", "shaders/plate_geo.glsl");
    // Initialise our environment map here
    initEnvironment();
    initTexture(1, m_glossMapTex, "textures/banana_hi_poly.png");
    shader->setUniform("glossMap", 1);
    /*initTexture(2,m_bananaTex, "/home/lfreeman/rendering_workshops/environment/images/une_banane.jpg");
    shader->setUniform("banana",2);*/
    initTexture(3, m_bananaNormal, "images/NormalMap(1).jpg");
    shader->setUniform("normal",3);
    initTexture(5, m_noiseMap, "textures/noise_map.png");
    shader->setUniform("noiseMap", 5);

    initTexture(4, m_ramp, "textures/ramp.tif");
    shader->setUniform("ramp", 4);

    //Initialising the obj for the banana along with its texture
    
    m_mesh.reset(new ngl::Obj("models/small_banana_obj.obj", "textures/banana_hi_poly.png"));
    std::cout<<"attempting to assign mesh \n";
    m_mesh->createVAO();
    std::cout<<"Vao made \n";

    //initialising the obj for the vertex
    m_vertexMesh.reset(new ngl::Obj("models/bob.obj"));
    std::cout<<"vertex loaded \n";
    m_vertexMesh->createVAO();
    std::cout<<"Vao made for vertex \n";
}

void EnvScene::paintGL() noexcept {
    // Clear the screen (fill with our glClearColor)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    std::cout<<"clear\n";

    // Set up the viewport
    glViewport(0,0,m_width,m_height);

    // Use our shader for this draw
    ngl::ShaderLib *shader=ngl::ShaderLib::instance();
    (*shader)["EnvironmentProgram"]->use();
    GLint pid = shader->getProgramID("EnvironmentProgram");

    std::cout<<"shader got\n";

    // Our MVP matrices
    glm::mat4 M = glm::mat4(1.0f);
    glm::mat4 MVP, MV;
   // M = glm::scale(M, glm::vec3(5.0f, 5.0f, 5.0f)); //can change this to 2.5 l8r
    glm::mat3 N;

    std::cout<<"matrices got \n";

    // Note the matrix multiplication order as we are in COLUMN MAJOR storage
    MV = m_V * M;
    N = glm::inverse(glm::mat3(MV));
    MVP = m_P * MV;
    std::cout<<"matrix multiplication \n";
    // Set this MVP on the GPU
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
    ngl::VAOPrimitives *prim=ngl::VAOPrimitives::instance();
    //prim->draw("teapot");
    //m_mesh->draw();
    std::cout<<"draw \n";

    (*shader)["PlateProgram"]->use();
    pid = shader->getProgramID("PlateProgram");
    glUniformMatrix4fv(glGetUniformLocation(pid, "MVP"), //location of uniform
                    1, // how many matrices to transfer
                    false, // whether to transpose matrix
                    glm::value_ptr(MVP)); // a raw pointer to the data
    glUniformMatrix3fv(glGetUniformLocation(pid, "N"), //location of uniform
                       1, // how many matrices to transfer
                       true, // whether to transpose matrix
                       glm::value_ptr(N)); // a raw pointer to the data
    m_vertexMesh->draw();
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
                GL_RGB,          // Format of the pixel data
                GL_UNSIGNED_BYTE, // Data type of pixel data
                img.getPixels()); // Pointer to image data in memory

    // Set up parameters for our texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
}

/**
 * @brief Scene::initEnvironment in texture unit 0
 */
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
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "images/sky_zneg.png");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "images/sky_zpos.png");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "images/sky_ypos.png");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "images/sky_yneg.png");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "images/sky_xneg.png");
    initEnvironmentSide(GL_TEXTURE_CUBE_MAP_POSITIVE_X, "images/sky_xpos.png");

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
    shader->use("EnvironmentProgram");
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
      GL_RGBA,          // Format of the pixel data
      GL_UNSIGNED_BYTE, // Data type of pixel data
      img.getPixels()   // Pointer to image data in memory
    );
}
