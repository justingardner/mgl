#ifdef documentation
=========================================================================

     program: mglPrivateMoveWindow.c
          by: Christopher Broussard
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Moves/Resizes the current AGL window.

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
		mexErrMsgTxt("(mglPrivateMoveWindow) error: invalid number of args");
	}
	
	bounds.left = (int)mxGetScalar(prhs[0]);
	bounds.top = (int)mxGetScalar(prhs[1]);
	r = (unsigned int)mglGetGlobalDouble("windowPointer");
	winRef = (WindowRef)r;
	
	MoveWindowStructure(winRef, (short)bounds.left, (short)bounds.top);
	//SetWindowBounds(winRef, kWindowStructureRgn, &bounds);
	SelectWindow(winRef);
}
