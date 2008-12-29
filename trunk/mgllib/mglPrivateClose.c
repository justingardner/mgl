#ifdef documentation
=========================================================================

     program: mglPrivateClose.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: close OpenGL screen

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

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This is the main function, it closes the screen
void closeDisplay(int displayNumber,int verbose);

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

  // close the display
  closeDisplay(displayNumber,verbose);

  // set display number to -1
  mglSetGlobalDouble("displayNumber",-1);
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
///////////////////////////////
//   function declarations   //
///////////////////////////////
void cocoaClose(int displayNumber, int verbose);
void cglClose(int displayNumber, int verbose);
void aglClose(int displayNumber, int verbose);
#ifdef __cocoa__
//////////////////////
//   closeDisplay   //
//////////////////////
void closeDisplay(int displayNumber,int verbose)
{
  // if display number is set to -1, then the display is closed
  if (displayNumber>0)
    cglClose(displayNumber,verbose);
 // if displayNumber is 0, then it is a cocoa window
  else if (displayNumber==0)
    cocoaClose(displayNumber,verbose);
}

////////////////////
//   cocoaClose   //
////////////////////
void cocoaClose(displayNumber,verbose)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSWindowController *myWindowController = (NSWindowController*)(unsigned long)mglGetGlobalDouble("windowController");
  NSOpenGLContext *myOpenGLContext = (NSOpenGLContext*)(unsigned long)mglGetGlobalDouble("context");
  // exit full screen mode
  if (displayNumber >= 1)
    [[[myWindowController window] contentView] exitFullScreenModeWithOptions:nil];
  // orderOut (i.e. hide the window) -- subsequent mglOpen's will just unhide
  [[myWindowController window] orderOut:nil];

  if (verbose){
    mexPrintf("(mglPrivateClose) Retain counts are controller: %i window: %i view: %i openGLContext: %i\n",[myWindowController retainCount],[[myWindowController window] retainCount],[[[myWindowController window] contentView] retainCount],[myOpenGLContext retainCount]);
  }

  // drain the pool
  [pool drain];
}

//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else// __cocoa__
//////////////////////
//   closeDisplay   //
//////////////////////
void closeDisplay(int displayNumber,int verbose)
{
  // if display number is set to -1, then the display is closed
  if (displayNumber>0)
    // if it is greater than 0, then it is a full screen CGL context
    cglClose(displayNumber, verbose);
 // if displayNumber is 0, then it is a window AGL contex 
  else if (displayNumber==0)
    aglClose(displayNumber,verbose);
}
//////////////////
//   aglClose   //
//////////////////
void aglClose(int displayNumber, int verbose)
{
  WindowRef winRef;
  if (verbose) mexPrintf("(mglPrivateClose) Closing AGL context\n");
    
  // run in a window: get agl context
  AGLContext contextObj = aglGetCurrentContext();
    
  if (!contextObj) {
    mexPrintf("(mglPrivateClose) warning: no drawable context found\n");
  }
    
  AGLDrawable drawableObj = aglGetDrawable(contextObj);
    
  // Note, rather than destroying the window here, we just
  // hide it now. This was done in a (failed) effort to improve
  // stability when running with the Matlab desktop.  The only
  // thing that apparently helps is not closing the window.
  //aglSetCurrentContext(NULL);
  //QDFlushPortBuffer(drawableObj,NULL);
  // destroy the context
  //if (QDDone(drawableObj))
  // clear context and close window
  //  if (!aglDestroyContext(contextObj)) {
  //  mexPrintf("(mglPrivateClose) UHOH: aglDestroyContext returned error\n");
  //  }
  //else 
  //  mexPrintf("(mglPrivateClose) Quick draw is blocking close. Try again\n");

  //check to see if we are running within the matlab desktop
  mxArray *thislhs[1];
  mxArray *thisrhs = mxCreateString("desktop");
  mexCallMATLAB(1, thislhs, 1, &thisrhs, "usejava");

  if ((int)mxGetScalar(thislhs[0]) == 1) {
    if (verbose>1) mexPrintf("(mglPrivateClose) Desktop. Hiding window\n");
    // desktop. just hide window
    HideWindow(GetWindowFromPort(drawableObj));
  }
  else {
    if (verbose>1) mexPrintf("(mglPrivateClose) No desktop. Destroying window\n");
    // otherwise destroy the context
    winRef = GetWindowFromPort(drawableObj);
    if (IsValidWindowPtr(winRef)) {
      DisposeWindow(winRef);
    }
    else {
      mexPrintf("(mglPrivateClose) error: invalid window pointer\n");
    }
  }
}
#endif//__cocoa__
//////////////////
//   cglClose   //
//////////////////
void cglClose(int displayNumber,int verbose)
{
  if (verbose) mexPrintf("(mglPrivateClose) Closing CGL context\n");
  // get the current drawing context
  CGLContextObj contextObj = CGLGetCurrentContext();
    
  // Release the captured display.  We recapture the display before releasing it
  // so that if it's already released the screen won't go black from
  // releasing it twice.  This bug may be unique to my machine, have yet to
  // test it on other boxes.
  CGDirectDisplayID displays[kMaxDisplays];
  CGDisplayCount numDisplays;
  CGGetActiveDisplayList(kMaxDisplays, displays, &numDisplays);
  CGDisplayCapture(displays[displayNumber-1]);
  CGDisplayRelease(displays[displayNumber-1]);

  // close the context and clean up
  CGLSetCurrentContext( NULL ) ;
  CGLClearDrawable( contextObj ) ;
  CGLDestroyContext( contextObj ) ;
    
  // Release the captured display
  CGReleaseAllDisplays();
    
  // Restore cursor
  CGDisplayShowCursor( kCGDirectMainDisplay ) ; 
}
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
//////////////////////
//   closeDisplay   //
//////////////////////
void closeDisplay(int displayNumber,int verbose)
{
  if (displayNumber>=0) {
    if (verbose) mexPrintf("(mglPrivateClose) Closing GLX context\n");
    int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");  
    Display * dpy=(Display *)dpyptr;
    int winptr=(int)mglGetGlobalDouble("XWindowPointer");  
    Window * win=(Window *)winptr;
    GLXContext ctx=glXGetCurrentContext();
    glXDestroyContext( dpy, ctx );
    XUnmapWindow( dpy, *win );
    XDestroyWindow( dpy, *win );
    XFlush(dpy);
    mglSetGlobalDouble("XDisplayPointer",0);
    mglSetGlobalDouble("XWindowPointer",0);
    XCloseDisplay(dpy);
  }
}
#endif//__linux__
