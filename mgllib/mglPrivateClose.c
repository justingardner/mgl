#ifdef documentation
=========================================================================

     program: mglPrivateClose.c
          by: justin gardner
        date: 04/03/06
     purpose: close OpenGL screen

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
  if (nrhs!=0) {
    usageError("mglPrivateClose");
    return;
  }
  
  // get verbose
  int verbose = (int)mglGetGlobalDouble("verbose");

  // if display number does not exist, then there is nothing to close
  if (!mglIsGlobal("displayNumber")) {
    if (verbose) mexPrintf("(mglPrivateClose) No Context open to close\n");
    return;
  }

  // get what display number we have
  int displayNumber = (int)mglGetGlobalDouble("displayNumber");
  if (displayNumber<0) {
    if (verbose) mexPrintf("(mglPrivateClose) No Context open to close\n");
    return;
  }

#ifdef __linux__
  
  if (displayNumber>=0) {
    if (verbose) mexPrintf("(mglPrivateClose) Closing GLX context\n");
    int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");  
    Display * dpy=(Display *)dpyptr;
    int winptr=(int)mglGetGlobalDouble("XWindowPointer");  
    Window * win=(Window *)winptr;
    XUnmapWindow( dpy, *win );
    XDestroyWindow( dpy, *win );
    GLXContext ctx=glXGetCurrentContext();
    glXDestroyContext( dpy, ctx );
    mglSetGlobalDouble("XDisplayPointer",0);
    mglSetGlobalDouble("XWindowPointer",0);
  }
#endif // #ifdef __linux__

#ifdef __APPLE__    
  // if display number is set to -1, then the display is closed
  if (displayNumber>0) {
    // if it is greater than 0, then it is a full screen CGL context
    if (verbose) mexPrintf("(mglPrivateClose) Closing CGL context\n");
    // get the current drawing context
    CGLContextObj contextObj = CGLGetCurrentContext();
    
    // close the context and clean up
    CGLSetCurrentContext( NULL ) ;
    CGLClearDrawable( contextObj ) ;
    CGLDestroyContext( contextObj ) ;
    
    // Release the captured display
    CGReleaseAllDisplays();
    
    // Restore cursor
    CGDisplayShowCursor( kCGDirectMainDisplay ) ; 
  }
  // if displayNumber is 0, then it is a window AGL contex 
  else if (displayNumber==0) {
    if (verbose) mexPrintf("(mglPrivateClose) Closing AGL context\n");
    
    // run in a window: get agl context
    AGLContext contextObj = aglGetCurrentContext();
    
    if (!contextObj) {
      mexPrintf("(mglPrivateClose) warning: no drawable context found\n");
    }
    
    AGLDrawable drawableObj = aglGetDrawable(contextObj);
    
    // clear context and close window
    if (!aglDestroyContext(contextObj)) {
      mexPrintf("(mglPrivateClose) UHOH: aglDestroyContext returned error\n");
    }
    
    // close window
    DisposeWindow(GetWindowFromPort(drawableObj));
  }
#endif // ifdef __APPLE__

  // set display number to -1
  mglSetGlobalDouble("displayNumber",-1);
}
