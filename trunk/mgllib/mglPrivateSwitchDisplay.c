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
      NSOpenGLContext *myOpenGLContext = (NSOpenGLContext*)(unsigned long)mglGetGlobalDouble("GLContext");
      [myOpenGLContext makeCurrentContext];
    }
    else {
      // switch the CGL context
      CGLContextObj contextObj;
      contextObj = (CGLContextObj)(unsigned long)mglGetGlobalDouble("GLContext");
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
    contextObj = (CGLContextObj)(unsigned long)mglGetGlobalDouble("GLContext");
    CGLSetCurrentContext(contextObj);
  }
  else {
    AGLContext contextObj;
    contextObj = (AGLContext)(unsigned int)mglGetGlobalDouble("GLContext");
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

//-----------------------------------------------------------------------------------///
// ****************************** Windows specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
MGL_CONTEXT_PTR ref;
HGLRC hRC;
HDC hDC;

// Grab the rendering and device contexts.
ref = (MGL_CONTEXT_PTR)mglGetGlobalDouble("GLContext");
hRC = (HGLRC)ref;
ref = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winDeviceContext");
hDC = (HDC)ref;

// Make the rendering context current.
if (wglMakeCurrent(hDC, hRC) == FALSE) {
  mexPrintf("(mglPrivateSwithDisplay) Failed to make the rendering context current.\n");
}
#endif // _WIN32
}
