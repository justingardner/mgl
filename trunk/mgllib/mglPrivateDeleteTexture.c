#ifdef documentation
=========================================================================

     program: mglPrivateDeleteTexture.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to delete a texture
       usage: mglDeleteTexture(texnum)

$Id$
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
  GLuint texNum;
  GLubyte *liveBuffer;
// should be called with texture number
  if (nrhs == 2) {
    texNum = (GLuint) *mxGetPr( prhs[0] );    
    glDeleteTextures(1,&texNum);
    // free the live buffer if it is there
    liveBuffer = (GLubyte *)(unsigned long) *mxGetPr( prhs[1] );    
    if (liveBuffer)
      free(liveBuffer);
  }
  else {
    usageError("mglDeleteTexture");
    return;
  }
}

