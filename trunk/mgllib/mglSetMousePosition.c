#ifdef documentation
=========================================================================
     program: mglSetMousePosition.c
          by: Christopher Broussard
        date: 02/03/11
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       purpose: Sets the position of the mouse cursor.  The position is in
                absolute screen pixel coordinates where (0,0) is the  
				is bottom left corner of the screen.  If targetScreen
				specified, then the coordinates are relative to that screen.
				Otherwise, coordinates are relative to the main screen.
       usage: mglSetMousePosition(xPos, yPos, targetScreen)
	     
		      % Move the mouse on the main screen.
			  mglSetMousePosition(512, 512);

			  % Move the mouse on the secondary screen.
			  mglSetMousePosition(512, 512, 2);

$Id: mglSetMousePosition.c 894 2011-02-02 18:44:20Z chrg $
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

////////////////////////
//   define section   //
////////////////////////
#define kMaxDisplays 8

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	float xPos, yPos;
	int i;
	size_t targetScreen = 0;
	
	// Check the number of input arguments.
	if (nrhs < 2 || nrhs > 3) {
		usageError("mglSetMousePosition");
		return;
	}

	// Grab the target screen if specified.
	if (nrhs == 3) {
		targetScreen = (size_t)mxGetScalar(prhs[2]) - 1;
	}
	
	// Make sure that both inputs are scalars.  Also make sure that passed 
	// values are non negative.
	for (i = 0; i < nrhs; i++) {
		if (mxGetM(prhs[i]) != 1 || mxGetN(prhs[i]) != 1 || !mxIsNumeric(prhs[i])) {
			mexPrintf("(mglSetMousePosition) Coordinate inputs must be scalar numeric values.\n");
			return;
		}
		
		// Grab the desired cursor coordinates.
		xPos = (float)mxGetScalar(prhs[0]);
		yPos = (float)mxGetScalar(prhs[1]);
	}
	
#ifdef __APPLE__
	size_t pxHeight;
	CGPoint cursorPos;
	CGError errorCode, displayErrorNum;
	uint32_t numDisplays;
	CGDirectDisplayID displays[kMaxDisplays];

	// Get a list of displays.
	displayErrorNum = CGGetActiveDisplayList(kMaxDisplays, displays, &numDisplays);
	if (displayErrorNum) {
		mexPrintf("(mglSetMousePosition) Cannot get display list (%d)\n", displayErrorNum);
		return;
	}

	// Make sure the target screen is in bounds.
	if (targetScreen >= numDisplays) {
		mexPrintf("(mglSetMousePosition) targetScreen is out of bounds (%d)\n", targetScreen+1);
		return;
	}

	// Get the pixel height of the target screen.
	pxHeight = CGDisplayPixelsHigh(displays[targetScreen]);

	cursorPos.x = (CGFloat)xPos;

	// We flip the y-coordinate to make it consistent with the Cocoa coordinate system
	// where (0,0) is the lower left corner of the main screen.
	cursorPos.y = (CGFloat)pxHeight - (CGFloat)yPos;

	errorCode = CGDisplayMoveCursorToPoint(displays[targetScreen], cursorPos);

	if (errorCode != kCGErrorSuccess) {
		mexPrintf("(mglSetMousePosition) Setting mouse position failed with error code %d.\n", errorCode);
		return;
	}
#endif
}

