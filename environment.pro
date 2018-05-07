######################################################################
# Automatically generated by qmake (3.0) Thu Jan 26 16:35:29 2017
######################################################################

include(/home/s4903789/workshops/rendering_examples/common/common.pri)
#include(common.pri)
TARGET = environment

# Input
INCLUDEPATH += ./include
HEADERS += include/envscene.h \
           include/camera.h \
           include/fixedcamera.h \
           include/scene.h \
           include/trackballcamera.h
SOURCES += src/main.cpp src/envscene.cpp \
           src/camera.cpp \
           src/fixedcamera.cpp \
           src/scene.cpp \
           src/trackballcamera.cpp \

OTHER_FILES += shaders/env_vert.glsl \
               shaders/env_frag.glsl \
               shaders/plate_geo.glsl \
               shaders/plate_frag.glsl \
               shaders/plate_vert.glsl \
               shaders/cube_frag.glsl \
               shaders/cube_vert.glsl \
               README.md

DISTFILES += $OTHER_FILES
