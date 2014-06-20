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
  if (displayNumber>=0) {
    // otherwise see if it is a cocoa or a cgl window
    if (mglGetGlobalDouble("isCocoaWindow")) {
      cocoaClose(displayNumber,verbose);
    }
    else {
      cglClose(displayNumber,verbose);
    }
  }
}

////////////////////
//   cocoaClose   //
////////////////////
void cocoaClose(displayNumber,verbose)
{
  if (verbose) mexPrintf("(mglPrivateClose) Closing cocoa window\n");

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // get pointers
  NSWindow *myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("cocoaWindowPointer");
  NSOpenGLContext *myOpenGLContext = (NSOpenGLContext*)(unsigned long)mglGetGlobalDouble("GLContext");

  if (verbose) mexPrintf("(mglPrivateClose) Closing window: %x with openGLContext: %x\n",(unsigned long)myWindow,(unsigned long)myOpenGLContext);

  // exit full screen mode
  if (displayNumber >= 1) {
    if (verbose) mexPrintf("(mglPrivateClose) Closing full screen mode\n");
    [[myWindow contentView] exitFullScreenModeWithOptions:nil];
    usleep(1000000);
  }

  // display retain counts
  if (verbose)
    mexPrintf("(mglPrivateClose) Retain counts are window: %i view: %i openGLContext: %i\n",[myWindow retainCount],[[myWindow contentView] retainCount],[myOpenGLContext retainCount]);

  // bring back task and menu bar if hidden
  if (mglGetGlobalDouble("hideTaskAndMenu")) {
    if (verbose) mexPrintf("(mglPrivateClose) Hiding task and menu bar\n");
    OSStatus setSystemUIModeStatus = SetSystemUIMode(kUIModeNormal,0);
  }

  // close the window. Note that we just orderOut (or make invisible) for now,
  // since there is some problem with actually closing and reopening
  if (mglGetGlobalDouble("hideNotClose")) {
    if (verbose) mexPrintf("(mglPrivateClose) Hiding cocoa window\n");
    [myWindow orderOut:nil];
  }
  else {
    if (verbose) mexPrintf("(mglPrivateClose) Releasing cocoa window\n");
    [[myWindow contentView] clearGLContext];
    [myWindow close];
    mglSetGlobalDouble("cocoaWindowPointer",0);
    mglSetGlobalDouble("GLContext",0);
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
  if (displayNumber>0) {
    // if it is greater than 0, then it is a full screen CGL context
    cglClose(displayNumber, verbose);
  }
 // if displayNumber is 0, then it is a window AGL contex 
  else if (displayNumber==0) {
    aglClose(displayNumber,verbose);
  }
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

  // set context to empty
  mglSetGlobalDouble("GLContext",0);
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

//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32

// Close the window.
void closeDisplay(int displayNumber, int verbose)
{
  // Get window parameters.
  MGL_CONTEXT_PTR v;
  v = (MGL_CONTEXT_PTR)mglGetGlobalDouble("GLContext");
  HGLRC hRC = (HGLRC)v;
  v = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winWindowPointer");
  HWND hWnd = (HWND)v;
  v = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winDeviceContext");
  HDC hDC = (HDC)v;
  v = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winAppInstance");
  HINSTANCE hInstance = (HINSTANCE)v;
  
  if (hRC) {											// Do We Have A Rendering Context?
    if (!wglMakeCurrent(NULL, NULL)) {				// Are We Able To Release The DC And RC Contexts?
      mexPrintf("(mglPrivateClose) Release Of DC And RC Failed.\n");
    }

    if (!wglDeleteContext(hRC))	{					// Are We Able To Delete The RC?
      mexPrintf("(mglPrivateClose) Release Rendering Context Failed.\n");
    }
    hRC = NULL;										// Set RC To NULL
  }

  if (hDC && !ReleaseDC(hWnd, hDC)) {					// Are We Able To Release The DC
    mexPrintf("(mglPrivateClose) Release Device Context Failed.\n");
    hDC = NULL;										// Set DC To NULL
  }

  if (hWnd && !DestroyWindow(hWnd)) {					// Are We Able To Destroy The Window?
    mexPrintf("(mglPrivateClose) Could Not Release hWnd.\n");
    hWnd = NULL;									// Set hWnd To NULL
  }

  if (!UnregisterClass("MGL", hInstance)) {		// Are We Able To Unregister Class
    mexPrintf("(mglPrivateClose) Could Not Unregister Class.\n");
    hInstance = NULL;									// Set hInstance To NULL
  }
}

#endif // _WIN32
