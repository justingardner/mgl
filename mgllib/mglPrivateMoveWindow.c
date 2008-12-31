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
  if (nrhs != 2) {
    usageError("mglMoveWindow");
    return;
  }
  
  // get where to move to
  int left = (int)*mxGetPr(prhs[0]);
  int top =  (int)*mxGetPr(prhs[1]);
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  NSWindow *myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("window");
  [myWindow setFrameTopLeftPoint:NSMakePoint((float)left,(float)top)];
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__cocoa__

  Rect bounds;
  unsigned int r;
  WindowRef winRef;
	
  r = (unsigned int)mglGetGlobalDouble("windowPointer");
  winRef = (WindowRef)r;
	
  if (IsValidWindowPtr(winRef)) {
    MoveWindowStructure(winRef, (short)left, (short)top);
    SelectWindow(winRef);
  }
  else {
    mexPrintf("(mglPrivateMoveWindow) error: invalid window pointer");
  }
#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  mexPrintf("(mglPrivateMoveWindow) Not implemented\n");
#endif//__linux__
}

