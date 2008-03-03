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
  // should be called with texture number
  if (nrhs == 1) {
    texNum = (GLuint) *mxGetPr( prhs[0] );    
    glDeleteTextures(1,&texNum);
  }
  else {
    usageError("mglDeleteTexture");
    return;
  }
}

