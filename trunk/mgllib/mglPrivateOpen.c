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

#ifdef __linux__
   static Bool WaitForNotify(Display *d, XEvent *e, char *arg) {
     return (e->type == MapNotify) && (e->xmap.window == (Window)arg);
   }
#endif

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get input arguments: xres, yres, framerate, bit depth
  // set defaults
   int screenWidth=800;
   int screenHeight=600;
   double frameRate=60; // Hz
   int bitDepth=32;
   int displayNumber=-1;
   int defaultSettings = 0;

   // check to make sure something already isn't open
   if (mglIsGlobal("displayNumber") && (mglGetGlobalDouble("displayNumber") >= 0)) {
     mexPrintf("(mglPrivateOpen) Display number %i is already open\n",(int)mglGetGlobalDouble("displayNumber"));
     return;
   }

   // get status of global variable that sets wether to display
   // verbose information
   int verbose = (int)mglGetGlobalDouble("verbose");

   // if no arguments passed in then use current monitor settings
   if (nrhs == 0)
     defaultSettings = 1;

   // otherwise interpert the input settings
   if (nrhs>0) {
     // get display number
     if (mxGetPr(prhs[0]) != NULL)
       displayNumber = (int) *mxGetPr( prhs[0] );
     // if this is the only argument passed in then we 
     // should use default settings
     if (nrhs==1) defaultSettings = 1;
   }
   // screenWidth
   if (nrhs>1) {
     if (mxGetPr(prhs[1]) != NULL)
       screenWidth = (int) *mxGetPr( prhs[1] );
   }
   // screenHeight
   if (nrhs>2) {
     if (mxGetPr(prhs[2]) != NULL)
       screenHeight = (int) *mxGetPr( prhs[2] );
   }
   // frameRate
   if (nrhs>3) {
     if (mxGetPr(prhs[3]) != NULL)
       frameRate = (double) *mxGetPr( prhs[3] );
   }
   // bitDepth
   if (nrhs>4) {
     if (mxGetPr(prhs[4]) != NULL)
       bitDepth = (int) *mxGetPr( prhs[4] );
   }
   if (nrhs>5) {
     usageError("mglPrivateOpen");
     return;
   }

#ifdef __APPLE__
   if (displayNumber) {

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
     if (displayNumber == -1) {
       whichDisplay = displays[numDisplays-1];
       displayNumber = (int)numDisplays;
     }
     else if (displayNumber > numDisplays) {
       mexPrintf("UHOH (mglPrivateOpen): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
       return;
     }
     else
       whichDisplay = displays[displayNumber-1];
     CGDisplayCapture(whichDisplay);

     // Switch the display mode
     boolean_t success=false;
     // but only if we aren't using the default settings
     if (!defaultSettings)
       CGDisplaySwitchToMode(whichDisplay,CGDisplayBestModeForParametersAndRefreshRate(whichDisplay,bitDepth,screenWidth,screenHeight,frameRate,&success));
     else
       success=true;
     // get what the display driver says the settings are
     screenWidth=CGDisplayPixelsWide( whichDisplay );
     screenHeight=CGDisplayPixelsHigh( whichDisplay );
     bitDepth=CGDisplayBitsPerPixel( whichDisplay );

     // check to see if it found the right setting
     if (!success) {
       mexPrintf("(mglPrivateOpen) Warning: failed to set requested display parameters.\n");
       mexPrintf("(mglPrivateOpen) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",screenWidth,screenHeight,frameRate,bitDepth); 
     }

     if (verbose)
       mexPrintf("(mglPrivateOpen) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",screenWidth,screenHeight,frameRate,bitDepth); 

     // choose the pixel format
     CGOpenGLDisplayMask displayMask = CGDisplayIDToOpenGLDisplayMask( whichDisplay ) ;
     // make this a full screen, double buffered pixel format
     CGLPixelFormatAttribute attribs[] =
     {
       kCGLPFAFullScreen,
       kCGLPFADoubleBuffer,
       kCGLPFAStencilSize,8,
       kCGLPFADisplayMask,
       displayMask,
       (CGLPixelFormatAttribute)NULL
     } ;
     CGLPixelFormatObj pixelFormatObj ;
     long numPixelFormats ;
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
     long swapInterval;swapInterval=1;
     CGLSetParameter(contextObj, kCGLCPSwapInterval, &swapInterval);

     // set the drawing context
     CGLSetCurrentContext( contextObj ) ;
     CGLSetFullScreen( contextObj ) ;

    // Hide cursor
    CGDisplayHideCursor( kCGDirectMainDisplay ) ; 

   } else {
     
     // run in a window: get agl context
     AGLContext contextObj = aglGetCurrentContext();
     
     if (contextObj != NULL) {
       if (verbose > 1)
	 mexPrintf("(mglPrivateOpen) Using previously created context\n");
       AGLDrawable drawableObj = aglGetDrawable(contextObj);
       // show window, using the desktop it is apparently in this
       // call that mglPrivateOpen fails.
       ShowWindow(GetWindowFromPort(drawableObj));
       
       // get an event (don't know if this is necessary, but the thought
       // was to give back control to the OS for some ticks so that it
       // could do whatever processing it needs to do)-
       EventRecord theEvent;
       EventMask theMask = keyDownMask;
       // either return immediately or wait till we get an event
       WaitNextEvent(theMask,&theEvent,6,nil);
     } else {
       
       
       // Open a Carbon window and set up an AGL rendering context
       WindowRef         theWindow; 
       WindowAttributes  windowAttrs;
       Rect              contentRect; 
       CFStringRef       titleKey;
       CFStringRef       windowTitle; 
       OSStatus          result; 
       
       windowAttrs = kWindowInWindowMenuAttribute | kWindowAsyncDragAttribute | kWindowNoUpdatesAttribute | kWindowStandardHandlerAttribute; 
       SetRect (&contentRect, 0, 0, screenWidth, screenHeight );
       
       // create a new window
       if (verbose>1) mexPrintf("(mglPrivateOpen) Creating new window\n");
       result = CreateNewWindow (kDocumentWindowClass, windowAttrs, &contentRect, &theWindow);
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
     }
   }
   
#endif //#ifdef __APPLE__

#ifdef __linux__

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
   if (displayNumber>-1) {
     // try to use chosen display
     if (displayNumber>XScreenCount(dpy))
       displayNumber=DefaultScreen(dpy); {
       if (verbose) 
	 mexPrintf("Selected screen not found, using default screen instead, displayNumber=%i\n",displayNumber);
     }
   } else {
     displayNumber=DefaultScreen(dpy);
     if (verbose) 
       mexPrintf("Using full size default screen, displayNumber=%i\n",displayNumber);
     fullscreen=true;
   }   
   vi = glXChooseVisual(dpy, displayNumber, attributeList);
   if (!vi) {
     mexPrintf("(mglPrivateOpen) Error: could not open display.");
     return;
   }

   // get vertical refresh rate. should eventually implement video mode switching here.
   XF86VidModeModeLine modeline;
   int pixelclock;
   XF86VidModeGetModeLine( dpy, displayNumber, &pixelclock, &modeline );
   frameRate=(double) pixelclock*1000/modeline.htotal/modeline.vtotal;
   if (verbose) 
     mexPrintf("Vertical Refresh rate:%f Hz\n",frameRate);

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
     screenWidth=w;
     screenHeight=h;
   }
   if (w==screenWidth && h==screenHeight)
     swa.override_redirect=true;
   swa.save_under=true;
   static Window win;
   win = XCreateWindow(dpy, RootWindow(dpy, vi->screen), 0, 0, screenWidth, screenHeight,
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
   hints->min_width=screenWidth;
   hints->max_width=screenWidth;
   hints->min_height=screenHeight;
   hints->max_height=screenHeight;
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

#endif // #ifdef __linux__

   // clear the back buffer
   glClearColor(0,0,0,0);
   glClear(GL_COLOR_BUFFER_BIT); 

#ifdef __APPLE__
   if (displayNumber) {
     // get the current context
     CGLContextObj contextObj = CGLGetCurrentContext();
     // and flip the double buffered screen
     // this call waits for vertical blanking
     CGLFlushDrawable(contextObj); 
   }
   else {
    // run in a window: get agl context
    AGLContext contextObj=aglGetCurrentContext ();

    if (!contextObj) {
      printf("warning: no drawable context found\n");
    }
     
    // swap buffers
    aglSwapBuffers (contextObj);
   }
#endif

#ifdef __linux__
  glXSwapBuffers( dpy, glXGetCurrentDrawable() );
#endif
  
  // 
  glDisable(GL_LIGHTING);
  
  // now set some information in the global variable
  mglSetGlobalDouble("displayNumber",(double)displayNumber);
  mglSetGlobalDouble("screenWidth",(double)screenWidth);
  mglSetGlobalDouble("screenHeight",(double)screenHeight);
  mglSetGlobalDouble("frameRate",(double)frameRate);
  mglSetGlobalDouble("bitDepth",(double)bitDepth);
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
}


