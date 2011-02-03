#ifdef documentation
=========================================================================
     program: mglSetMousePosition.c
          by: Christopher Broussard
        date: 02/03/11
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       purpose: Sets the position of the mouse cursor.  The position is in
                absolute screen pixel coordinates.
       usage: mglSetMousePosition(xPos, yPos)

$Id: mglGetMouse.c 894 2011-02-02 18:44:20Z chrg $
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
	int xPos, yPos, i;
	
	// Check the number of input arguments.
	if (nrhs != 2) {
		usageError("mglSetMousePosition");
		return;
	}
	
	// Make sure that both inputs are scalars.  Also make sure that passed 
	// values are non negative.
	for (i = 0; i < nrhs; i++) {
		if (mxGetM(prhs[i]) != 1 || mxGetN(prhs[i]) != 1 || !mxIsNumeric(prhs[i])) {
			mexPrintf("(mglSetMousePosition) Coordinate inputs must be scalar numeric values.\n");
			return;
		}
		
		xPos = (int)mxGetScalar(prhs[0]);
		if (xPos < 0) {
			mexPrintf("(mglSetMousePosition) X coordinate must be >= 0.\n");
			return;
		}
		
		yPos = (int)mxGetScalar(prhs[1]);
		if (yPos < 0) {
			mexPrintf("(mglSetMousePosition) Y coordinate must be >= 0.\n");
			return;
		}
	}
	
#ifdef __APPLE__
	CGPoint cursorPos;
	CGError errorCode;

	cursorPos.x = (CGFloat)xPos;
	cursorPos.y = (CGFloat)yPos;
	
	errorCode = CGWarpMouseCursorPosition(cursorPos);
	
	if (errorCode != kCGErrorSuccess) {
		mexPrintf("(mglSetMousePosition) Setting mouse position failed with error code %d.\n", errorCode);
		return;
	}
#endif
}
