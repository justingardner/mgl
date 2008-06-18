#ifdef documentation
=========================================================================

       program: mglGetKeyEventNew.c
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

#include <pthread.h>
 
// The thread entry point routine.
void* PosixThreadMainRoutine(void *data)
{
    // Do some work here.
  mexPrintf("In thread\n"); 
  mglSetGlobalDouble("huh",34);
    return NULL;
}
 
void LaunchThread()
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
 
    assert(!pthread_attr_init(&attr));
    assert(!pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED));
 
    int threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);
 
    assert(!pthread_attr_destroy(&attr));
    if (threadError != 0)
    {
      mexPrintf("(LaunchThread) Error %i\n",threadError);
    }
  mexPrintf("Launch Thread\n"); 
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
    // backtick
    if (keycode == 50) {
      mexPrintf("Setting time of backtick in MGL.backtick\n");
      //      CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (int64_t)keycode);
      CGEventSetType(event,kCGEventNull);
      mglSetGlobalDouble("backtick",(double)timeStamp);
    }
    // esc
    else if (keycode == 53) {
      // Disable the event tap.
      CGEventTapEnable(gEventTap, false);
      // shut down event loop
      CFRunLoopStop(CFRunLoopGetCurrent());
    }
    else
      mexPrintf("Key: %i was hit %0.0f nanoseconds after system start\n",(unsigned int)keycode,(double)timeStamp);
  }
  else if (type == kCGEventLeftMouseDown) {
    mexPrintf("Left mouse down: %0.0f nanoseconds after system start\n",(double)timeStamp);
  }
  else if (type == kCGEventRightMouseDown) {
    mexPrintf("Right mouse down at %0.0f nanoseconds after system start\n",(double)timeStamp);
  }
  
  // event can be returned modified if you want to change the event into something else
  return event;
}

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  CGEventMask        eventMask;
  CFRunLoopSourceRef runLoopSource;

  // This doesn't work 
  LaunchThread();

  // Create an event tap. We are interested in key presses and mouse presses
  eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown));
  gEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);

  // see if it was created properly
  if (!gEventTap) {
    mexPrintf("(mglGetKeyEventNew) Failed to create event tap\n");
    return;
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

}
