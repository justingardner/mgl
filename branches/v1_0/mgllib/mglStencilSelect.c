#ifdef documentation
=========================================================================

     program: mglStencilSelect.c
          by: justin gardner
        date: 05/26/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  GLuint stencilNumber = 0;
  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");

  // get passed in value
  if (nrhs==1) {
    stencilNumber = (GLuint)*mxGetPr(prhs[0]);
    if (stencilNumber > 0)
      stencilNumber = (1<<(stencilNumber-1));
    else
      stencilNumber = 0;
  }
  else if (nrhs != 0) {
    usageError("mglStencilSelect");
    return;
  }

  // get stencil all mask
  int stencilBits = (int)mglGetGlobalDouble("stencilBits");
  int stencilAllMask = (1<<stencilBits)-1;

  if (verbose) mexPrintf("(mglStencilSelect) stencilNumber = %i\n",stencilNumber);

  // set the stencil function appropriately
  glStencilFunc(GL_EQUAL,stencilAllMask,stencilNumber);
}
