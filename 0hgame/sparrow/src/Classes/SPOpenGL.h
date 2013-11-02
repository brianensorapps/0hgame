//
//  SPOpenGL.h
//  Sparrow
//
//  Created by Robert Carone on 10/8/13.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "SPMacros.h"

#define SP_ENABLE_GL_STATE_CACHE        1

/// Returns a string representing an OpenGL error code.
SP_EXTERN const GLchar*                 sglGetErrorString(GLenum error);

// GL_OES_vertex_array_object

#if GL_OES_vertex_array_object
    #define GL_VERTEX_ARRAY_BINDING     GL_VERTEX_ARRAY_BINDING_OES
    #define glBindVertexArray           glBindVertexArrayOES
    #define glGenVertexArrays           glGenVertexArraysOES
    #define glDeleteVertexArrays        glDeleteVertexArraysOES
    #define glIsVertexArray             glIsVertexArrayOES
#endif

// OpenGL state cache

#if SP_ENABLE_GL_STATE_CACHE

    #undef  glBindVertexArray
    #undef  glDeleteVertexArrays

    // shims

    #define glActiveTexture             sglActiveTexture
    #define glBindBuffer                sglBindBuffer
    #define glBindFramebuffer           sglBindFramebuffer
    #define glBindRenderbuffer          sglBindRenderbuffer
    #define glBindTexture               sglBindTexture
    #define glBindVertexArray           sglBindVertexArray
    #define glBlendFunc                 sglBlendFunc
    #define glDeleteBuffers             sglDeleteBuffers
    #define glDeleteFramebuffers        sglDeleteFramebuffers
    #define glDeleteProgram             sglDeleteProgram
    #define glDeleteRenderbuffers       sglDeleteRenderbuffers
    #define glDeleteTextures            sglDeleteTextures
    #define glDeleteVertexArrays        sglDeleteVertexArrays
    #define glDisable                   sglDisable
    #define glEnable                    sglEnable
    #define glGetIntegerv               sglGetIntegerv
    #define glScissor                   sglScissor
    #define glUseProgram                sglUseProgram
    #define glViewport                  sglViewport

    // prototypes

    SP_EXTERN void                      sglActiveTexture(GLenum texture);
    SP_EXTERN void                      sglBindBuffer(GLenum target, GLuint buffer);
    SP_EXTERN void                      sglBindFramebuffer(GLenum target, GLuint framebuffer);
    SP_EXTERN void                      sglBindRenderbuffer(GLenum target, GLuint renderbuffer);
    SP_EXTERN void                      sglBindTexture(GLenum target, GLuint texture);
    SP_EXTERN void                      sglBindVertexArray(GLuint array);
    SP_EXTERN void                      sglBlendFunc(GLenum sfactor, GLenum dfactor);
    SP_EXTERN void                      sglDeleteBuffers(GLsizei n, const GLuint* buffers);
    SP_EXTERN void                      sglDeleteFramebuffers(GLsizei n, const GLuint* framebuffers);
    SP_EXTERN void                      sglDeleteProgram(GLuint program);
    SP_EXTERN void                      sglDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers);
    SP_EXTERN void                      sglDeleteTextures(GLsizei n, const GLuint* textures);
    SP_EXTERN void                      sglDeleteVertexArrays(GLsizei n, const GLuint* arrays);
    SP_EXTERN void                      sglDisable(GLenum cap);
    SP_EXTERN void                      sglEnable(GLenum cap);
    SP_EXTERN void                      sglGetIntegerv(GLenum pname, GLint* params);
    SP_EXTERN void                      sglScissor(GLint x, GLint y, GLsizei width, GLsizei height);
    SP_EXTERN void                      sglUseProgram(GLuint program);
    SP_EXTERN void                      sglViewport(GLint x, GLint y, GLsizei width, GLsizei height);

#endif //!SP_ENABLE_GL_STATE_CACHE
