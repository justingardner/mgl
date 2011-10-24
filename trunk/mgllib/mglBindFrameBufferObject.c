#ifdef documentation
=========================================================================

     program: mglBindFrameBufferObject.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Binds a frame buffer object to the current OpenGL context and
			  directs all subsequent OpenGL calls to the frame buffer object.
       usage: mglBindFrameBufferObject(fbObject)

$Id: mglBindFrameBufferObject.c 18 2010-09-07 15:41:18Z cgb $
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
  mxArray *field;
  GLuint fboID, mfboID;
  int width, height, enableMultisampling;
  
  if (nrhs != 1) {
	  usageError("mglBindFrameBufferObject");
    return;
  }
  
  // Make sure the input was a struct.
  if (!mxIsStruct(prhs[0])) {
	  usageError("mglBindFrameBufferObject");
    return;
  }
  
  // Get the frame buffer object ID and its dimensions.
  field = mxGetField(prhs[0], 0, "id");
  fboID = (GLuint)mxGetScalar(field);
  field = mxGetField(prhs[0], 0, "width");
  width = (GLuint)mxGetScalar(field);
  field = mxGetField(prhs[0], 0, "height");
  height = (GLuint)mxGetScalar(field);
  field = mxGetField(prhs[0], 0, "multisampling");
  enableMultisampling = (int)mxGetScalar(field);
  field = mxGetField(prhs[0], 0, "mid");
  mfboID = (GLuint)mxGetScalar(field);
  
  // If multisampling is enabled, we need to bind our multisampled
  // framebuffer object.  We'll copy to the normal framebuffer object
  // later in the mglUnbindFrameBufferObject function.
  if (enableMultisampling) {
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, mfboID);
  }
  else {
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
  }

  // Save the view port and set it to the size of the texture
  glPushAttrib(GL_VIEWPORT_BIT);
  glViewport(0, 0, width, height);
}

