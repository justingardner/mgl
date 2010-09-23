#ifdef documentation
=========================================================================

     program: mglUnbindFrameBufferObject.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Unbinds a frame buffer object from the current OpenGL context
			  to allow rendering to the standard frame buffer.
       usage: mglUnbindFrameBufferObject

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
	glPopAttrib();
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}
