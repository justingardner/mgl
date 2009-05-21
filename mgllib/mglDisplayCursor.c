#ifdef documentation
=========================================================================

     program: mglDisplayMouse.c
          by: justin gardner
        date: 02/10/07
   copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to display/hide the mouse
       usage: mglDisplayMouse(<display>)

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
  // get display number
  int displayNumber = (int)mglGetGlobalDouble("displayNumber");

  if (displayNumber > 0) {
    // if called with no arguments
    if (nrhs == 0) {
#ifdef __APPLE__
      // Restore cursor
      CGDisplayShowCursor( kCGDirectMainDisplay ) ; 
#endif
    }
    // if called with one argument
    else if (nrhs == 1) {
      int display = 1;
      if (mxGetPr(prhs[0]) != NULL)
	// get whether to display the cursor or not
	display = (int) *mxGetPr( prhs[0] );
#ifdef __APPLE__
      if (display)
	// Restore cursor
	CGDisplayShowCursor( kCGDirectMainDisplay ) ; 
      else
	// Hide cursor
	CGDisplayHideCursor( kCGDirectMainDisplay ) ; 
#endif
    }
    else {
      usageError("mglDisplayCursor");
      return;
    }
  }
}

