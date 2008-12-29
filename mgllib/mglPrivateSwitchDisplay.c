#ifdef documentation
=========================================================================

     program: mglPrivateSwitchDisplay.c
          by: Christopher Broussard
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Switches witch display/window is active.

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
  int displayNumber;
  WindowRef wr;
	
  if (nrhs != 0) {
    usageError("mglSwitchDisplay");
    return;
  }
	
  displayNumber = (int)mglGetGlobalDouble("displayNumber");

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  // If displayNumber > 0, then it's a CGL window.
  if (displayNumber >= 0) {
    if (mglGetGlobalDouble("isCocoaWindow")) {
      // switch the cocoa openGLContext
      NSOpenGLContext *myOpenGLContext = (NSOpenGLContext*)(unsigned long)mglGetGlobalDouble("context");
      [myOpenGLContext makeCurrentContext];
    }
    else {
      // switch the CGL context
      CGLContextObj contextObj;
      contextObj = (CGLContextObj)(unsigned long)mglGetGlobalDouble("context");
      CGLSetCurrentContext(contextObj);
    }
  }
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else //__cocoa__
	
  // If displayNumber > 0, then it's a CGL window.
  if (displayNumber > 0) {
    CGLContextObj contextObj;
    contextObj = (CGLContextObj)(unsigned long)mglGetGlobalDouble("context");
    CGLSetCurrentContext(contextObj);
  }
  else {
    AGLContext contextObj;
    contextObj = (AGLContext)(unsigned int)mglGetGlobalDouble("context");
    aglSetCurrentContext(contextObj);
  }
#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  mexPrintf("(mglPrivateSwitchDisplay) Not implemented\n");
#endif //__linux__
}
