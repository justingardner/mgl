#ifdef documentation
=========================================================================

     program: mglClearScreen.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to clear the screen
       usage: mglClearScreen(<color>)

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
  int i, n;

  // if called with no arguments
  if (nrhs == 0) {
    // use the previous color
  }
  // if called with one argument
  else if (nrhs == 1) {
    double color[4];
    if (mglGetColor(prhs[0],color) == 0) 
      usageError("mglClearScreen");
    else
      glClearColor(color[0],color[1],color[2],color[3]);    
  }
  else {
    usageError("mglClearScreen");
    return;
  }

  // now clear to the set color
  glClear(GL_COLOR_BUFFER_BIT); 
}

