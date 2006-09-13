#ifdef documentation
=========================================================================

     program: mglStencilCreateEnd.c
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
  // set the stencil function such that no stencil is selected
  glStencilFunc(GL_EQUAL,1,0);
  // and it won't draw into the stencil anymore
  glStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);
}
