#ifdef documentation
=========================================================================

     program: mglGetMouse.c
          by: justin gardner
        date: 09/12/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Return state of mouse buttons and its position.  Position is
              in global screen coordinates unless a target screen is
              specified.
       usage: mglGetMouse([targetScreen])
          
              % Get mouse info in global screen coordinates.
              mouseInfo = mglGetMouse;

              % Get mouse info in screen 2 coordinates.
              mouseInfo = mglGetMouse(2);


$Id$
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
  size_t targetScreen = 0;

  if (nrhs > 1) {
    usageError("mglGetMouse");
    return;
  }

  // Get the target screen if specified.
  if (nrhs == 1) {
    targetScreen = (size_t)mxGetScalar(prhs[0]) - 1;
  }

  // create the output structure
  const char *fieldNames[] =  {"buttons","x","y" };
  const mwSize outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);

  // and the field for X
  double *outptrX,*outptrY,*outptrButton;
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrX = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));

  // and the field for Y
  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrY = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));

  // and the field for buttons
  mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrButton = (double*)mxGetPr(mxGetField(plhs[0],0,"buttons"));


#ifdef __APPLE__

  CGError errorCode, displayErrorNum;
	uint32_t numDisplays;
	CGDirectDisplayID displays[kMaxDisplays];

	// Get a list of displays.
	displayErrorNum = CGGetActiveDisplayList(kMaxDisplays, displays, &numDisplays);
	if (displayErrorNum) {
		mexPrintf("(mglGetMouse) Cannot get display list (%d)\n", displayErrorNum);
		return;
	}

	// Make sure the target screen is in bounds.
        if (targetScreen >= numDisplays) {
		mexPrintf("(mglGetMouse) targetScreen is out of bounds (%d)\n", targetScreen+1);
		return;
	}

  // Get the height of the main display.
  size_t mainHeightPx = CGDisplayPixelsHigh(kCGDirectMainDisplay);

  // Get the bounds of the target display.
  CGRect r = CGDisplayBounds(displays[targetScreen]);

#ifdef __cocoa__
  NSPoint mouseLocation = [NSEvent mouseLocation];

  // set the button state
  *outptrButton = (double)GetCurrentButtonState();
  *outptrX = mouseLocation.x;
  *outptrY = mouseLocation.y;

//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else// __cocoa__
  // The following code does not work on 64bit since it relies on events
  // get next event on queue
  EventRecord theEvent;
  EventMask theMask = mDownMask;

  // get the mouse position
  GetNextEvent(theMask,&theEvent);

  // set the position of the mouse
  *outptrX = theEvent.where.h;
  *outptrY = theEvent.where.v;

#endif//__cocoa__

  // Adjust the results based on the location of the display relative to the main display.
  *outptrX = *outptrX - r.origin.x;
  *outptrY = *outptrY - mainHeightPx + r.size.height + r.origin.y;

#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  *outptrButton = -1;
  *outptrX = -1;
  *outptrY = -1;
  mexPrintf("(mglGetMouse) Not supported yet on linux\n");
  return;
#endif //__linux__
  
//-----------------------------------------------------------------------------------///
// ****************** Windows specific code  *********************  ///
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
	POINT mousePos;
	USHORT mouseState;

	// Grab the mouse position.
	if (GetCursorPos(&mousePos) == FALSE) {
		mexPrintf("(mglGetMouse) Failed to get the mouse position.\n");
		return;
	}

	mouseState =(USHORT) GetKeyState(VK_LBUTTON);
	mouseState = mouseState >> (sizeof(USHORT)*8 - 1);

	*outptrButton = (double)mouseState;
	*outptrX = (double)mousePos.x;
	*outptrY = (double)mousePos.y;
#endif
}

