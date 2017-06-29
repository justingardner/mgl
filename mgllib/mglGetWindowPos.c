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
  
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSWindow *myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("cocoaWindowPointer");
  // get frame
  NSRect frame = [myWindow frame];
  // init return
  plhs[0] = mxCreateDoubleMatrix(1,4,mxREAL);
  double *output = (double*)mxGetPr(plhs[0]);
  // return frame position
  output[0] = frame.origin.x;
  output[1] = frame.origin.y;
  output[2] = frame.size.width;
  output[3] = frame.size.height;
  [pool drain];
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  mexPrintf("(mglPrivateMoveWindow) Not implemented\n");
#endif//__linux__

//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __WINDOWS__
  mexPrintf("(mglPrivateMoveWindow) Not implemented\n");
#endif // __WINDOWS__
}

