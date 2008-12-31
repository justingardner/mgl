#ifdef documentation
=========================================================================

     program: mglPrivateOpen.c
          by: justin gardner with modifications by jonas larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: opens an OpenGL window on Mac OS X or Linux
              See Macintosh OpenGL Programming Guide

              http://developer.apple.com/documentation/GraphicsImaging/OpenGL-date.html#//apple_ref/doc/uid/TP30000440-TP30000424-TP30000549

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

///////////////////////////////
//   function declarations   //
///////////////////////////////
void mglPrivateOpenOnExit(void);

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This is the main function, it opens up the screen. It should also return a pointer
// to the openGL context that has been cast into an unsigned long for saving in the
// mgl global variable -- this is used by mglSwitchDisplays. The screen should be opened
// with the default settings, and then screenWidth and screenHeight should be set to
// whatever the display size was after opening. For displayNumber of 0, the size
// of the window should be set to the passed in screenWidth/screenHeight. A display
// number >0 and <1 indicates to open in a window with the alpha set to the displayNumber
unsigned long openDisplay(double *displayNumber, int *screenWidth, int *screenHeight);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get input arguments: screenWidth and screenHeight. Note that the displayNumber,
  // bitDepth and frameRate will have been correctly set using mglResolution in
  // mglOpen
  int screenWidth=800, screenHeight=600;
  double displayNumber=0;
   
  // check to make sure something already isn't open
  if (mglIsGlobal("displayNumber") && (mglGetGlobalDouble("displayNumber") >= 0)) {
    mexPrintf("(mglPrivateOpen) Display number %i is already open\n",(int)mglGetGlobalDouble("displayNumber"));
    return;
  }

  // interpert the input settings
  if ((nrhs>0) && (mxGetPr(prhs[0]) != NULL))
    displayNumber = (double) *mxGetPr( prhs[0] );
  // screenWidth
  if ((nrhs>1) && (mxGetPr(prhs[1]) != NULL))
    screenWidth = (int) *mxGetPr( prhs[1] );
  // screenHeight
  if ((nrhs>2) && (mxGetPr(prhs[2]) != NULL))
    screenHeight = (int) *mxGetPr( prhs[2] );
  // usage error
  if (nrhs>3) {
    usageError("mglOpen");
    return;
  }

  // init context pointer (other than CGL contexts
  // the pointer will be set to 0 which will
  // be as sign for mglSwitchDisplay that the context
  // cannot be switched
  unsigned long contextPointer = 0;

  // open the display   
  contextPointer = openDisplay(&displayNumber,&screenWidth,&screenHeight);

  // and save the context pointer
  mglSetGlobalDouble("context",(double)contextPointer);

  // get the floor of the displayNumber because the decimal place is for alpha
  displayNumber = floor(displayNumber);

  // set lighting
  glDisable(GL_LIGHTING);

  // now set some information in the global variable
  mglSetGlobalDouble("displayNumber",(double)displayNumber);
  mglSetGlobalDouble("screenWidth",(double)screenWidth);
  mglSetGlobalDouble("screenHeight",(double)screenHeight);
  mglSetGlobalDouble("stencilBits",(double)8);
    
  // set information about device coordinates
  mglSetGlobalDouble("xPixelsToDevice",(double)2/screenWidth);
  mglSetGlobalDouble("yPixelsToDevice",(double)2/screenHeight);
  mglSetGlobalDouble("xDeviceToPixels",(double)screenWidth/2);
  mglSetGlobalDouble("yDeviceToPixels",(double)screenHeight/2);
  mglSetGlobalDouble("deviceWidth",2);
  mglSetGlobalDouble("deviceHeight",2);
  mglSetGlobalField("deviceCoords",mxCreateString("default"));
  mxArray *deviceRect = mxCreateDoubleMatrix(1,4,mxREAL);
  double *deviceRectPtr = (double*)mxGetPr(deviceRect);
  deviceRectPtr[0] = -1;deviceRectPtr[1] = -1;
  deviceRectPtr[2] = 1;deviceRectPtr[3] = 1;
  mglSetGlobalField("deviceRect",deviceRect);

  // tell matlab to call mglPrivateOpenOnExit when this
  // function is cleared (e.g. clear all is used) so 
  // that we can close open displays
  mexAtExit(mglPrivateOpenOnExit);
}

//////////////////////////////
//   mglPrivateOpenOnExit   //
//////////////////////////////
void mglPrivateOpenOnExit()
{
  // call mglSwitchDisplay with -1 to close all open screens
  mxArray *callInput =  mxCreateDoubleMatrix(1,1,mxREAL);
  *(double*)mxGetPr(callInput) = -1;
  mexCallMATLAB(0,NULL,1,&callInput,"mglSwitchDisplay");
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
///////////////////////////////
//   function declarations   //
///////////////////////////////
unsigned long cglOpen(double *displayNumber, int *screenWidth, int *screenHeight);
unsigned long aglOpen(double *displayNumber, int *screenWidth, int *screenHeight);
unsigned long cocoaOpen(double *displayNumber, int *screenWidth, int *screenHeight);

#ifdef __cocoa__
////////////////////
//   openDisplay  //
////////////////////
unsigned long openDisplay(double *displayNumber, int *screenWidth, int *screenHeight)
{
  unsigned long contextPointer;

  if ((*displayNumber >= 1) || (*displayNumber < 0))
    // for full screen displays, use cocoa only if the desktop is *not* running
    if (mglGetGlobalDouble("matlabDesktop"))
      contextPointer = cglOpen(displayNumber,screenWidth,screenHeight);
    else
      contextPointer = cocoaOpen(displayNumber,screenWidth,screenHeight);
  // always use cocoa for windowed contexts
  else 
    contextPointer = cocoaOpen(displayNumber,screenWidth,screenHeight);

  return(contextPointer);
}

////////////////////
//   openWindow   //
////////////////////
unsigned long cocoaOpen(double *displayNumber, int *screenWidth, int *screenHeight)
{
  // NOte that this function can open either a windowed or a full-screen display. It
  // is currently only being used for a windowed context, because the full-screen
  // context conflicts somehow with the matlab desktop (works fine with -nodesktop
  // or -nojvm).
  NSOpenGLView *myOpenGLView;
  NSWindow *myWindow;
  NSOpenGLContext *myOpenGLContext;

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // see if there is an existing window
  myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("window");

  // if there isn't we need to set everything up
  if (myWindow == 0) {

    if (verbose) mexPrintf("(mglPrivateOpen) Initializing cocoa window\n");

    // start the application -- i.e. connect our code to the window server
    NSApplicationLoad();

    // set up a pixel format for the openGL context
    NSOpenGLPixelFormatAttribute attrs[] = {
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFADepthSize, 32,
      NSOpenGLPFAStencilSize, 8,
      0
    };
    NSOpenGLPixelFormat* myPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (myPixelFormat==nil) {mexPrintf("(mglPrivateOpen) Could not create pixel format\n");return;}

    // Create the openGLview, note that we set it to open with a 0,0,0,0 sized rect
    // because it will later get resized to the size of the window
    myOpenGLView = [[NSOpenGLView alloc] initWithFrame:NSMakeRect(0,0,0,0) pixelFormat:myPixelFormat];
    if (myOpenGLView==nil){mexPrintf("(mglPrivateOpen) Could not create openGLView\n");return;}
    [myPixelFormat release];
    if (verbose) mexPrintf("(mglPrivateOpen) Created openGLView: %x\n",(unsigned long)myOpenGLView);

    // set initial size and location
    NSRect contentRect = NSMakeRect(100,100+*screenHeight,*screenWidth,*screenHeight);

    // create the window, if we are running desktop, then open a borderless non backing
    // store window because anything else causes problems
    if (mglGetGlobalDouble("matlabDesktop"))
      myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:false];
    else
      myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:false];
    if (myWindow==nil){mexPrintf("(mglPrivateOpen) Could not create window\n");return;}
    if (verbose) mexPrintf("(mglPrivateOpen) Created window: %x\n",(unsigned long)myWindow);

    // attach the openGL view
    [myWindow setContentView:myOpenGLView];

    // release the openGLView
    [myOpenGLView release];
  } 

  // set the openGL context as current
  myOpenGLContext = [[myWindow contentView] openGLContext];
  [myOpenGLContext makeCurrentContext];
  [[myWindow contentView] prepareOpenGL];
  if (verbose) mexPrintf("(mglPrivateOpen) Setting openGLContext: %x\n",(unsigned long)myOpenGLContext);

  // make sure that the window won't show until we want it to.
  [myWindow setAlphaValue:0];

  // show window
  if (verbose) mexPrintf("(mglPrivateOpen) Show window\n");
  [myWindow makeKeyAndOrderFront: nil];
  [myWindow display];

  // set the swap interval so that flush waits for vertical refresh
  const GLint swapInterval = 1;
  [myOpenGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

  // Set a full screen context
  if ((*displayNumber >= 1) || (*displayNumber < 0)){
    // display message
    if (verbose) mexPrintf("(mglPrivateOpen) Going full screen\n");

    //  Set some options for going full screen
    NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithBool:NO],[NSNumber numberWithInt:0],nil];
    NSArray *keys = [NSArray arrayWithObjects:NSFullScreenModeAllScreens,NSFullScreenModeWindowLevel,nil];

    NSDictionary *fullScreenOptions = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    // get all the screens
    NSArray *screens = [NSScreen screens];

    // now enter full screen mode
    [[myWindow contentView] enterFullScreenMode:[screens objectAtIndex:(*displayNumber-1)] withOptions:fullScreenOptions];

    // get the size of the relevant screen
    NSRect screenRect = [[screens objectAtIndex:(*displayNumber-1)] frame];
    *screenWidth = screenRect.size.width;
    *screenHeight = screenRect.size.height;
  } 
  else {
    if (verbose) mexPrintf("(mglPrivateOpen) Setting window alpha\n");
    // for a windowed context, we don't have to go full screen, just set alpha
    if (*displayNumber > 0)
      // set alpha, if displayNumber is not == 0
      [myWindow setAlphaValue:*displayNumber];
    else
      [myWindow setAlphaValue:1];
  }

  // remember the window
  mglSetGlobalDouble("window",(unsigned long)myWindow);
  // and that this is a cocoa window
  mglSetGlobalDouble("isCocoaWindow",1);

  // drain the pool
  [pool drain];
  if (verbose) mexPrintf("(mglPrivateOpen) pool is drained\n");

  // return openGL context
  return((unsigned long)myOpenGLContext);
}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else // __cocoa__
///////////////////////////////
//   function declarations   //
///////////////////////////////
unsigned long cglOpen(double *displayNumber, int *screenWidth, int *screenHeight);
unsigned long aglOpen(double *displayNumber, int *screenWidth, int *screenHeight);

////////////////////
//   openDisplay  //
////////////////////
unsigned long openDisplay(double *displayNumber, int *screenWidth, int *screenHeight)
{
  unsigned long contextPointer;

  if ((*displayNumber >= 1) || (*displayNumber < 0)){
    contextPointer = cglOpen(displayNumber,screenWidth,screenHeight);
  } 
  else {
    contextPointer = aglOpen(displayNumber,screenWidth,screenHeight);
  } 
  return(contextPointer);
}

/////////////////
//   aglOpen   //
/////////////////
unsigned long aglOpen(double *displayNumber, int *screenWidth, int *screenHeight)
{
  // get rid of any decimal part
  *displayNumber = floor(*displayNumber);

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // Holds the pointer to the AGL window if opened.
  WindowRef         theWindow; 

  // Open a Carbon window and set up an AGL rendering context
  WindowAttributes  windowAttrs;
  Rect              contentRect; 
  CFStringRef       titleKey;
  CFStringRef       windowTitle; 
  OSStatus          result;
	   
  //windowAttrs = kWindowInWindowMenuAttribute | kWindowAsyncDragAttribute | kWindowNoUpdatesAttribute | kWindowStandardHandlerAttribute;
  windowAttrs = kWindowNoUpdatesAttribute | kWindowAsyncDragAttribute;
  SetRect (&contentRect, 0, 0, *screenWidth, *screenHeight );
	   
  //check to see if we are running within the matlab desktop
  mxArray *thislhs[1];
  mxArray *thisrhs = mxCreateString("desktop");
  mexCallMATLAB(1, thislhs, 1, &thisrhs, "usejava");

  // create a new window
  if (verbose>1) mexPrintf("(mglPrivateOpen) Creating new window\n");
  if ((int)mxGetScalar(thislhs[0]) == 1) {
    if (verbose>1) mexPrintf("(mglPrivateOpen) Desktop. Using kOverlayWindowClass\n");
    // desktop. Use kOVerlayWindowClass
    result = CreateNewWindow(kOverlayWindowClass, windowAttrs, &contentRect, &theWindow);
  }
  else {
    if (verbose>1) mexPrintf("(mglPrivateOpen) No desktop. Using kDocumentWindowClass\n");
    // nojvm, nodesktop
    result = CreateNewWindow(kDocumentWindowClass, windowAttrs, &contentRect, &theWindow);
  }

  if (result != noErr) {
    mexPrintf("(mglPrivateOpen) Could not CreateNewWindow\n");
    return;
  }
	   
  // don't ever activate window
  SetWindowActivationScope(theWindow,kWindowActivationScopeNone);
	   
  // get an event (don't know if this is necessary, but the thought
  // was to give back control to the OS for some ticks so that it
  // could do whatever processing it needs to do)-
  EventRef theEvent;
  EventTargetRef theTarget;
  theTarget = GetEventDispatcherTarget();
  if (verbose>1) mexPrintf("(mglPrivateOpen) ReceiveNextEvent\n");
  InstallStandardEventHandler(theTarget);
  if (ReceiveNextEvent(0,NULL,1,true,&theEvent) == noErr) {
    SendEventToEventTarget(theEvent,theTarget);
    ReleaseEvent(theEvent);
  }
       
  // get a proxy icon for the window
  if (verbose>1) mexPrintf("(mglPrivateOpen) Setting window proxy and creator\n");
  result = SetWindowProxyCreatorAndType(theWindow,0,'TEXT',kOnSystemDisk);
  if (result != noErr) {
    mexPrintf("(mglPrivateOpen) Could not SetWindowProxyCreatorAndType\n");
    return;
  }
       
  // setting the title: This crashes on the SetWindowTitleWithCFString call
  if (verbose) mexPrintf("(mglPrivateOpen) Setting the title\n");
  titleKey = CFSTR("Matlab OpenGL Viewport"); 
  windowTitle = CFCopyLocalizedString(titleKey, NULL); 
  result = SetWindowTitleWithCFString (theWindow, windowTitle); 
  CFRelease (titleKey); 
  CFRelease (windowTitle); 
       
       
  /// get the agl PixelFormat
  if (verbose>1) mexPrintf("(mglPrivateOpen) Getting AGL pixel format\n");
  GLint attrib[] = {AGL_RGBA, AGL_DOUBLEBUFFER, AGL_STENCIL_SIZE, 8, AGL_ACCELERATED, AGL_NO_RECOVERY, AGL_NONE };
  AGLPixelFormat aglPixFmt = aglChoosePixelFormat (NULL, 0, attrib);
  if (aglPixFmt == NULL) {
    mexPrintf("(mglPrivateOpeen) Could not get AGLPixelFormat\n");
    return;
  }
       
  // set up drawing context
  if (verbose>1) mexPrintf("(mglPrivateOpen) Getting AGL Context\n");
  AGLContext aglContextObj = aglCreateContext (aglPixFmt, NULL);
  if (aglContextObj == NULL) {
    mexPrintf("(mglPrivateOpen) Could not create agl context\n");
    return;
  }
       
  // clean up pixel format
  result = aglGetError();
  aglDestroyPixelFormat(aglPixFmt);
       
  // insure that we wait for vertical blank on flush
  if (verbose>1) mexPrintf("(mglPrivateOpen) Setting AGL swap interval\n");
  GLint sync = 1;
  aglSetInteger(aglContextObj, AGL_SWAP_INTERVAL, &sync);
       
  // attach window to context
  if (verbose>1) mexPrintf("(mglPrivateOpen) Attaching window\n");
  CGrafPtr winPtr=GetWindowPort ( theWindow );
  if (!aglSetDrawable( aglContextObj, winPtr)) {
    mexPrintf("(mglPrivateOpen) Warning: failed to set drawable\n");
  }
  if (! aglSetCurrentContext ( aglContextObj )) {
    mexPrintf("(mglPrivateOpen) warning: failed to set drawable context found\n");
  }
  // display the window
  if (verbose>1) mexPrintf("(mglPrivateOpen) Displaying the window\n");
  result = TransitionWindow(theWindow,kWindowZoomTransitionEffect,kWindowShowTransitionAction,nil);
  if (result != noErr) {
    mexPrintf("(mglPrivateOpen) Could not TransitionWindow\n");
    return;
  }
  if (verbose>1) mexPrintf("(mglPrivateOpen) Repositioning window\n");
  RepositionWindow (theWindow, NULL, kWindowCascadeOnMainScreen); 
  return((unsigned long)aglContextObj);
}
#endif //__cocoa__
/////////////////
//   cglOpen   //
/////////////////
unsigned long cglOpen(double *displayNumber, int *screenWidth, int *screenHeight)
{
  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // get rid of decimal place
  *displayNumber = floor(*displayNumber);

  CGLError errorNum;CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglPrivateOpen) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }
  if (verbose)
    mexPrintf("(mglPrivateOpen) Found %i displays\n",numDisplays);

  // capture the main display
  //  CGDisplayCapture(kCGDirectMainDisplay);
  // capture the last display in the list
  // which screen of -1 sets to last in display
  if (*displayNumber == -1) {
    whichDisplay = displays[numDisplays-1];
    *displayNumber = (int)numDisplays;
  }
  else if (*displayNumber > numDisplays) {
    mexPrintf("UHOH (mglPrivateOpen): Display %i out of range (0:%i)\n",*displayNumber,numDisplays);
    return;
  }
  else
    whichDisplay = displays[(int)*displayNumber-1];
  CGDisplayCapture(whichDisplay);

  // get what the display driver says the settings are
  *screenWidth=CGDisplayPixelsWide( whichDisplay );
  *screenHeight=CGDisplayPixelsHigh( whichDisplay );

  if (verbose)
    mexPrintf("(mglPrivateOpen) Current display parameters: screenWidth=%i, screenHeight=%i\n",*screenWidth,*screenHeight); 

  // choose the pixel format
  CGOpenGLDisplayMask displayMask = CGDisplayIDToOpenGLDisplayMask( whichDisplay ) ;
  // make this a full screen, double buffered pixel format
  CGLPixelFormatAttribute attribs[] =
    {
      kCGLPFAFullScreen,kCGLPFADoubleBuffer,
      kCGLPFAStencilSize,(CGLPixelFormatAttribute)8,
      kCGLPFADisplayMask,(CGLPixelFormatAttribute)displayMask,
      (CGLPixelFormatAttribute)NULL
    } ;
  CGLPixelFormatObj pixelFormatObj ;
  GLint numPixelFormats ;
  errorNum = CGLChoosePixelFormat( attribs, &pixelFormatObj, &numPixelFormats );
  if (errorNum) {
    mexPrintf("(mglPrivateOpen) UHOH: CGLChoosePixelFormat returned %i (%s)\n",errorNum,CGLErrorString(errorNum));
    return;
  }

  // Set up the full screen context
  CGLContextObj contextObj;
  errorNum = CGLCreateContext(pixelFormatObj, NULL, &contextObj ) ;
  if (errorNum) {
    mexPrintf("(mglPrivateOpen) UHOH: CGLCreateContext returned %i (%s)\n",errorNum,CGLErrorString(errorNum));
    return;
  }

  // clear the pixel format
  CGLDestroyPixelFormat( pixelFormatObj ) ;

  // swap interval controls how many vertical blanks have to 
  // occur before we can flip the buffer
  GLint swapInterval;swapInterval=1;
  CGLSetParameter(contextObj, kCGLCPSwapInterval, &swapInterval);

  // set the drawing context
  CGLSetCurrentContext( contextObj ) ;
  CGLSetFullScreen( contextObj ) ;

  // Hide cursor
  CGDisplayHideCursor( kCGDirectMainDisplay ) ; 

  // we only keep a pointer to the window for AGL
  mglSetGlobalDouble("windowPointer", 0.0);

  return((unsigned long)contextObj);
}

#endif //__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////
//   WaitForNotfiy   //
///////////////////////
static Bool WaitForNotify(Display *d, XEvent *e, char *arg) {
  return (e->type == MapNotify) && (e->xmap.window == (Window)arg);
}

/////////////////////////
//   linuxOpenWindow   //
/////////////////////////
unsigned long openDisplay(double *displayNumber, int *screenWidth, int *screenHeight)
{
  *displayNumber = floor(*displayNumber);

  // This environment variable is necessary to get OpenGL to sync with vertical blank for Radeon cards.
  // Not optimal, of course! should be made system-independent.
  setenv("LIBGL_SYNC_REFRESH", "t", 1);

  XVisualInfo *vi;
  XSetWindowAttributes swa;
  XEvent event;
  // get a connection 
  static Display *dpy;
  dpy = XOpenDisplay(0);
  // get an appropriate visual 
  int attributeList[] = { GLX_DOUBLEBUFFER, GLX_RGBA, GLX_BUFFER_SIZE, 32, \
			  GLX_RED_SIZE,8, GLX_GREEN_SIZE,8, GLX_BLUE_SIZE,8, GLX_ALPHA_SIZE, 8, \
			  GLX_STENCIL_SIZE, 8, None };

  bool fullscreen=false;
  if (*displayNumber>-1) {
    // try to use chosen display
    if (*displayNumber>XScreenCount(dpy))
      *displayNumber=DefaultScreen(dpy); {
      if (verbose) 
	mexPrintf("Selected screen not found, using default screen instead, displayNumber=%i\n",*displayNumber);
    }
  } else {
    *displayNumber=DefaultScreen(dpy);
    if (verbose) 
      mexPrintf("Using full size default screen, displayNumber=%i\n",*displayNumber);
    fullscreen=true;
  }   
  vi = glXChooseVisual(dpy, *displayNumber, attributeList);
  if (!vi) {
    mexPrintf("(mglPrivateOpen) Error: could not open display.");
    return;
  }

  // get vertical refresh rate. should eventually implement video mode switching here.
  XF86VidModeModeLine modeline;
  int pixelclock;
  XF86VidModeGetModeLine( dpy, *displayNumber, &pixelclock, &modeline );
  frameRate=(double) pixelclock*1000/modeline.htotal/modeline.vtotal;
  if (verbose) 
    mexPrintf("Vertical Refresh rate:%f Hz\n",*frameRate);

  int value[2];
  int event_base_return, error_base_return;
  if (XSyncQueryExtension ( dpy , &event_base_return , &error_base_return )) {
    if (verbose) 
      mexPrintf("X Synchronization supported.\n");
    int n_counters_return, n;
    XSyncSystemCounter * syscounts=XSyncListSystemCounters (dpy, &n_counters_return);
    if (verbose) {
      mexPrintf("%i\n",n_counters_return);
      mexPrintf("%s %i %i\n",syscounts[n].name, (int) syscounts[n].counter, (int) XSyncValueLow32(syscounts[n].resolution) );
    }
  } else if (verbose)
    mexPrintf("X Synchronization not supported.\n");
   
  glXGetConfig( dpy, vi, GLX_BUFFER_SIZE, value );
  int alphaBits=*value;
  if (verbose)
    mexPrintf("GLX_BUFFER_SIZE:%i\n", *value);
  glXGetConfig( dpy, vi, GLX_RED_SIZE, value );
  if (verbose)
    mexPrintf("GLX_RED_SIZE:%i\n", *value);
  alphaBits-=*value;
  glXGetConfig( dpy, vi, GLX_GREEN_SIZE, value );
  if (verbose)
    mexPrintf("GLX_GREEN_SIZE:%i\n", *value);
  alphaBits-=*value;
  glXGetConfig( dpy, vi, GLX_BLUE_SIZE, value );
  if (verbose)
    mexPrintf("GLX_BLUE_SIZE:%i\n", *value);
  alphaBits-=*value;
  glXGetConfig( dpy, vi, GLX_ALPHA_SIZE, value );
  if (verbose)
    mexPrintf("GLX_ALPHA_SIZE:%i\n", *value);
  glXGetConfig(dpy,vi,GL_ALPHA_BITS, value);
  if (verbose)
    mexPrintf("GL_ALPHA_BITS:%i\n", *value);
  if (verbose)
    mexPrintf("Computed ALPHA_BITS:%i\n", alphaBits);

  //   mglSetGlobalDouble("alphaBits",(double)alphaBits);

  if (verbose)
    mexPrintf("Depth:%i\n", vi->depth);
     
  // create a GLX context 
  static GLXContext cx;
  cx = glXCreateContext(dpy, vi, 0, GL_TRUE);
  // create a color map 
  static Colormap cmap; 
  cmap = XCreateColormap(dpy, RootWindow(dpy, vi->screen), vi->visual, AllocNone);
  // create a window 
  swa.colormap = cmap;
  swa.border_pixel = 0;
  swa.event_mask = StructureNotifyMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask;
  //swa.backing_store=Always;
  //swa.save_under=True;
  // if fullscreen, bypass window manager
  int w,h;
  w=XDisplayWidth(dpy, vi->screen);
  h=XDisplayHeight(dpy, vi->screen);
  if (fullscreen) {
    *screenWidth=w;
    *screenHeight=h;
  }
  if (w==*screenWidth && h==*screenHeight)
    swa.override_redirect=true;
  swa.save_under=true;
  static Window win;
  win = XCreateWindow(dpy, RootWindow(dpy, vi->screen), 0, 0, *screenWidth, *screenHeight,
		      0, vi->depth, InputOutput, vi->visual,
		      CWBorderPixel|CWColormap|CWEventMask|CWOverrideRedirect, &swa);

  // Hide cursor if fullscreen
  if (fullscreen) {
    Pixmap bm_no;
    Cursor no_ptr;
    XColor black, dummy;
    static char bm_no_data[] = {0, 0, 0, 0, 0, 0, 0, 0};
    XAllocNamedColor(dpy, cmap, "black", &black, &dummy);
    bm_no = XCreateBitmapFromData(dpy, win, bm_no_data, 8, 8);
    no_ptr = XCreatePixmapCursor(dpy, bm_no, bm_no, &black, &black, 0, 0);
    XDefineCursor(dpy, win, no_ptr);
    XFreeCursor(dpy, no_ptr);
    if (bm_no != None)
      XFreePixmap(dpy, bm_no);
    XFreeColors(dpy, cmap, &black.pixel, 1, 0);
  }

  // set hints
  XSizeHints * hints=XAllocSizeHints();
  hints->x=0;
  hints->y=0;
  hints->min_width=*screenWidth;
  hints->max_width=*screenWidth;
  hints->min_height=*screenHeight;
  hints->max_height=*screenHeight;
  XSetWMNormalHints(dpy, win, hints);
  XMapWindow(dpy, win);
  XIfEvent(dpy, &event, WaitForNotify, (char*)win);
  // connect the context to the window 
  glXMakeCurrent(dpy, win, cx);
  glXWaitGL();
  //   glEnable(GL_TEXTURE_2D);
  // glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
  glEnable(GL_LINE_SMOOTH);
  GLboolean antialias;
  glGetBooleanv(GL_LINE_SMOOTH,&antialias);
  if (~antialias && verbose)
    mexPrintf("Antialiased lines not supported on this platform.\n");

  // save screen as display number
  int winPtr=(int) &win;
  mglSetGlobalDouble("XWindowPointer",(double)winPtr);
  int dpyPtr=(int) dpy;
  mglSetGlobalDouble("XDisplayPointer",(double)dpyPtr);

  return(0);
}

#endif//__linux__






