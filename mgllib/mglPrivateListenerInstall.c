#ifdef documentation
=========================================================================

       program: mglPrivateInstallListener.c
            by: justin gardner
          date: 06/18/08

 modified from:

   alterkeys.c
   http://osxbook.com
 
   Complile using the following command line:
     gcc -Wall -o alterkeys alterkeys.c -framework ApplicationServices

    You need superuser privileges to create the event tap, unless accessibility
    is enabled. To do so, select the "Enable access for assistive devices"
    checkbox in the Universal Access system preference pane.

     http://www.osxbook.com/book/bonus/chapter2/alterkeys/
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include <ApplicationServices/ApplicationServices.h>
#include <pthread.h>

////////////////
//   globals  //
////////////////
CFMachPortRef gEventTap;
char gCallbackName[1024];

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* setupEventTap(void *data);
void launchSetupEventTapAsThread();
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
 
//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // check command line arguments
  if (nrhs == 0) {
    usageError("mglInstallListener");
    return;
  }

  // get input string which contains name of callback function
  int buflen = mxGetN(prhs[0])*mxGetM( prhs[0] )+1;
  mxGetString( prhs[0], gCallbackName, buflen);
  printf("Callback name: %s\n",gCallbackName);

  // start the thread that will have a callback that gets called every
  // time there is a keyboard or mouse event of interest
  launchSetupEventTapAsThread();

  // clear memory


  // return the pointers
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(plhs[0]) = (double)(unsigned long)gEventTap;
}

///////////////////////
//   setupEventTap   //
///////////////////////
void* setupEventTap(void *data)
{
  CGEventMask        eventMask;
  CFRunLoopSourceRef runLoopSource;

  // Create an event tap. We are interested in key presses and mouse presses
  eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown));
  gEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);

  // see if it was created properly
  if (!gEventTap) {
    mexPrintf("(mglPrivateInstallListener) Failed to create event tap\n");
    return NULL;
  }

  // Create a run loop source.
  runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gEventTap, 0);

  // Add to the current run loop.
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

  // Enable the event tap.
  CGEventTapEnable(gEventTap, true);

  // tell user what is going on
  mexPrintf("Hit Esc to quit\n");

  // set up run loop
  CFRunLoopRun();

  return NULL;
}
 
////////////////////////
//   event callback   //
////////////////////////
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
  // Get the time that the event happened
  CGEventTimestamp timeStamp = CGEventGetTimestamp(event);

  // check for keyboard event
  if (type == kCGEventKeyDown) {
    // The incoming keycode.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    // call callback
    if (keycode != 53) {
      // create the output structure
      const char *fieldNames[] =  {"keyCode","timeStamp"};
      int outDims[2] = {1, 1};
      mxArray *mEvent = mxCreateStructArray(1,outDims,2,fieldNames);

      // set the fields
      double *outptr;
      mxSetField(mEvent,0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
      outptr = (double*)mxGetPr(mxGetField(mEvent,0,"keyCode"));
      *outptr = (double)(keycode);

      mxSetField(mEvent,0,"timeStamp",mxCreateDoubleMatrix(1,1,mxREAL));
      outptr = (double*)mxGetPr(mxGetField(mEvent,0,"timeStamp"));
      *outptr = (double)(timeStamp);

      // call the callback function
      mexCallMATLAB(0,NULL,1,&mEvent,gCallbackName);
    }
    // esc
    else if (keycode == 53) {
      // Disable the event tap.
      CGEventTapEnable(gEventTap, false);
      // shut down event loop
      CFRunLoopStop(CFRunLoopGetCurrent());
      mexPrintf("(mglGetKeyEvent) Stopping keyboard event tap\n");
    }
    else {
      mglSetGlobalDouble("lastKeypressKeycode",(double)keycode);
      mglSetGlobalDouble("lastKeypressTimestamp",(double)timeStamp);
    }
  }
  else if (type == kCGEventLeftMouseDown) {
    mglSetGlobalDouble("lastLeftMouseDownTimestamp",(double)timeStamp);
  }
  else if (type == kCGEventRightMouseDown) {
    mexPrintf("Right mouse down at %0.0f nanoseconds after system start\n",(double)timeStamp);
  }
  
  // event can be returned modified if you want to change the event into something else
  return event;
}

/////////////////////////////////////
//   launchSetupEventTapAsThread   //
/////////////////////////////////////
void launchSetupEventTapAsThread()
{
  // Create the thread using POSIX routines.
  pthread_attr_t  attr;
  pthread_t       posixThreadID;
 
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
 
  int threadError = pthread_create(&posixThreadID, &attr, &setupEventTap, NULL);
 
  pthread_attr_destroy(&attr);
  if (threadError != 0)
      mexPrintf("(MglGetKeyEventNew) Error could not setup event tap thread: error %i\n",threadError);
}

