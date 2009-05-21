#ifdef documentation
=========================================================================

     program: mglPrivateMoveWindow.c
          by: Christopher Broussard
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Moves the current AGL window.

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
  Rect bounds;
  unsigned int r;
  WindowRef winRef;
	
  if (nrhs != 2) {
    usageError("mglMoveWindow");
    return;
  }
	
  bounds.left = (int)mxGetScalar(prhs[0]);
  bounds.top = (int)mxGetScalar(prhs[1]);
  r = (unsigned int)mglGetGlobalDouble("windowPointer");
  winRef = (WindowRef)r;
	
  if (IsValidWindowPtr(winRef)) {
    MoveWindowStructure(winRef, (short)bounds.left, (short)bounds.top);
    SelectWindow(winRef);
  }
  else {
    mexPrintf("(mglPrivateMoveWindow) error: invalid window pointer");
  }
}
