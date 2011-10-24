#ifdef documentation
=========================================================================

     program: mglUnbindFrameBufferObject.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Unbinds a frame buffer object from the current OpenGL context
			  to allow rendering to the standard frame buffer.
       usage: mglUnbindFrameBufferObject(fbObject)

$Id: mglUnbindFrameBufferObject.c 18 2010-09-07 15:41:18Z cgb $
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
	  usageError("mglUnbindFrameBufferObject");
    return;
  }
  
  // Make sure the input was a struct.
  if (!mxIsStruct(prhs[0])) {
	  usageError("mglUnbindFrameBufferObject");
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

	glPopAttrib();

  // If multisampling is enabled, we need to copy the multisampled framebuffer
  // object to the regular one.  Apparently, this is needed for the graphics card
  // to downsample the scene properly.  I don't know all the details behind this.
  if (enableMultisampling) {
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, mfboID);
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, fboID);
    glBlitFramebufferEXT(0, 0, width, height, 0, 0, width, height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
  }

  // Unbind all framebuffer objects.
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}

