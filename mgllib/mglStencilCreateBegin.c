#ifdef documentation
=========================================================================

     program: mglStencilCreate.c
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
  GLuint stencilNumber = 1;
  int invert = 0;

  // get passed in stencil Number 
  if (nrhs>=1) {
    stencilNumber = (GLuint)*mxGetPr(prhs[0]);
  }
  if (nrhs==2) {
    invert = (GLuint)*mxGetPr(prhs[1]);
  }

  // check usage
  if ((nrhs < 0) || (nrhs > 2)) {
    usageError("mglStencilSelect");
    return;
  }

  // get some info from MGL global
  int verbose = (int)mglGetGlobalDouble("verbose");
  int stencilBits = (int)mglGetGlobalDouble("stencilBits");
  int stencilAllMask = (1<<stencilBits)-1;
  int stencilMask = (1<<(stencilNumber-1));

  // print some stuff  
  if (verbose) mexPrintf("(mglStencilCreateBegin) Stencil all mask: %i\n",stencilAllMask);
  if (verbose) mexPrintf("(mglStencilCreateBegin) Stencil mask: %i\n",stencilMask);
  if (verbose) mexPrintf("(mglStencilCreateBegin) Stencil number: %i\n",stencilNumber);
  glEnable(GL_STENCIL_TEST);

  // set up which stencil bit to draw into
  glStencilMask(stencilMask);

  // clear the stencil (either to zero normally or to the stencil
  // value for inverted stencils
  glClearStencil(invert?stencilMask:0);
  glClear(GL_STENCIL_BUFFER_BIT);

  // set up stencil draw, either draw the stencilMask or zero
  // depending on whether we want inverted stencils
  glStencilFunc(GL_ALWAYS, invert?0:stencilMask, 1);
  glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
}
