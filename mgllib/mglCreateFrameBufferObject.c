#ifdef documentation
=========================================================================

     program: mglCreateFrameBufferObject.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Creates a OpenGL frame buffer object.
       usage: fboObject = mglCreateFrameBufferObject(width, height)

$Id: mglCreateFrameBufferObject.c 18 2010-09-07 15:41:18Z cgb $
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int width, height;
  GLuint fboID, mfboID, fboTextureID, depthBuffer, colorBuffer;
  GLuint textureId;
  GLsizei samples = 4;
  GLenum status;
  char **fieldNames;

  // check input arguments
  if (nrhs != 2) {
    usageError("mglCreateFrameBufferObject");
    return;
  }
  
  // Determine if we have multisampling enabled.
  int enableMultisampling = (int)mglGetGlobalDouble("multisampling");

  // Grab the width and height.
  width = (int)mxGetScalar(prhs[0]);
  height = (int)mxGetScalar(prhs[1]);
  
  // Create the frame buffer object.
  glGenFramebuffersEXT(1, &fboID);

  // Create multisample buffers if multisampling enabled.
  if (enableMultisampling) {
    if ((int)mglGetGlobalDouble("verbose")) {
      mexPrintf("(mglCreateFrameBufferObject) Creating multisampled framebuffer object.\n");
    }

    // Multisampled color buffer.
    glGenRenderbuffersEXT(1, &colorBuffer);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, colorBuffer);
    glRenderbufferStorageMultisampleEXT(GL_RENDERBUFFER_EXT, samples, GL_RGBA8, width, height);

    // Multisampled depth buffer.
    glGenRenderbuffersEXT(1, &depthBuffer);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, depthBuffer);
    glRenderbufferStorageMultisampleEXT(GL_RENDERBUFFER_EXT, samples, GL_DEPTH_COMPONENT, width, height);

    // Create fbo for multi sampled content and attach depth and color buffers to it.
    glGenFramebuffersEXT(1, &mfboID);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, mfboID);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_RENDERBUFFER_EXT, colorBuffer);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, depthBuffer);
  }
  else {
    // Create a depth buffer and bind it to the framebuffer object.
    glGenRenderbuffersEXT(1, &depthBuffer);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, depthBuffer);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, width, height);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, depthBuffer);
  }

  // Create the color texture and attach it to the framebuffer object.
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
  glGenTextures(1, &fboTextureID);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, fboTextureID);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, fboTextureID, 0);

  // Check for errors.
  status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
  if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
	  mexPrintf("(mglCreateFrameBufferObject) UHOH: Failed to create a framebuffer object\n");
	  return;
  }

  // Unbind the framebuffer object for later use.
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  
  // Create the fieldNames string for the return struct.
  fieldNames = (char**)mxMalloc(sizeof(char*)*6);
  fieldNames[0] = (char*)mxMalloc(sizeof(char)*3);
  strcpy(fieldNames[0], "id");
  fieldNames[1] = (char*)mxMalloc(sizeof(char)*8);
  strcpy(fieldNames[1], "texture");
  fieldNames[2] = (char*)mxMalloc(sizeof(char)*6);
  strcpy(fieldNames[2], "width");
  fieldNames[3] = (char*)mxMalloc(sizeof(char)*7);
  strcpy(fieldNames[3], "height");
  fieldNames[4] = (char*)mxMalloc(sizeof(char)*14);
  strcpy(fieldNames[4], "multisampling");
  fieldNames[5] = (char*)mxMalloc(sizeof(char)*7);
  strcpy(fieldNames[5], "mid");
  
  // Return the frame buffer object and texture IDs.
  plhs[0] = mxCreateStructMatrix(1, 1, 6, (const char**)fieldNames);
  mxSetFieldByNumber(plhs[0], 0, 0, mxCreateDoubleScalar((double)fboID));
  mxSetFieldByNumber(plhs[0], 0, 1, mxCreateDoubleScalar((double)fboTextureID));
  mxSetFieldByNumber(plhs[0], 0, 2, mxCreateDoubleScalar((double)width));
  mxSetFieldByNumber(plhs[0], 0, 3, mxCreateDoubleScalar((double)height));
  mxSetFieldByNumber(plhs[0], 0, 4, mxCreateDoubleScalar((double)enableMultisampling));
  mxSetFieldByNumber(plhs[0], 0, 5, mxCreateDoubleScalar((double)mfboID));
}

