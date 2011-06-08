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
  GLuint fboID, fboTextureID, depthTex;
  GLuint textureId;
  GLenum status;
  char **fieldNames;

  // check input arguments
  if (nrhs != 2) {
    usageError("mglCreateFrameBufferObject");
    return;
  }

  // Grab the width and height.
  width = (int)mxGetScalar(prhs[0]);
  height = (int)mxGetScalar(prhs[1]);
  
  // Create the frame buffer object.
  glGenFramebuffersEXT(1, &fboID);

  // Bind the framebuffer object and create an empty texture which is where
  // we'll draw to.
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
  glGenTextures(1, &fboTextureID);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, fboTextureID);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, fboTextureID, 0);
  
  // Add a depth texture for 3D.
  glGenTextures(1, &depthTex);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, depthTex);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_DEPTH_TEXTURE_MODE, GL_INTENSITY);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
  glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_DEPTH_COMPONENT24, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);

  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_RECTANGLE_ARB, depthTex, 0);

  // Check for errors.
  status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
  if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
	mexPrintf("(mglCreateFrameBufferObject) UHOH: Failed to create a framebuffer object\n");
	return;
  }

  // Unbind the framebuffer object for later use.
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  
  // Create the fieldNames string for the return struct.
  fieldNames = (char**)mxMalloc(sizeof(char*)*4);
  fieldNames[0] = (char*)mxMalloc(sizeof(char)*3);
  strcpy(fieldNames[0], "id");
  fieldNames[1] = (char*)mxMalloc(sizeof(char)*8);
  strcpy(fieldNames[1], "texture");
  fieldNames[2] = (char*)mxMalloc(sizeof(char)*6);
  strcpy(fieldNames[2], "width");
  fieldNames[3] = (char*)mxMalloc(sizeof(char)*7);
  strcpy(fieldNames[3], "height");
  
  // Return the frame buffer object and texture IDs.
  plhs[0] = mxCreateStructMatrix(1, 1, 4, (const char**)fieldNames);
  mxSetFieldByNumber(plhs[0], 0, 0, mxCreateDoubleScalar((double)fboID));
  mxSetFieldByNumber(plhs[0], 0, 1, mxCreateDoubleScalar((double)fboTextureID));
  mxSetFieldByNumber(plhs[0], 0, 2, mxCreateDoubleScalar((double)width));
  mxSetFieldByNumber(plhs[0], 0, 3, mxCreateDoubleScalar((double)height));
}
