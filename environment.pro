######################################################################
# Automatically generated by qmake (3.0) Thu Jan 26 16:35:29 2017
######################################################################

include(../workshops/rendering_examples/common/common.pri)
TARGET = environment

# Input
INCLUDEPATH += ./include
HEADERS += src/envscene.h \
           include/camera.h \
           include/fixedcamera.h \
           include/scene.h \
           include/trackballcamera.h
SOURCES += src/main.cpp src/envscene.cpp \
           src/camera.cpp \
           src/fixedcamera.cpp \
           src/scene.cpp \
           src/trackballcamera.cpp

OTHER_FILES += shaders/env_vert.glsl \
               shaders/env_frag.glsl \
               README.md

DISTFILES += $OTHER_FILES
