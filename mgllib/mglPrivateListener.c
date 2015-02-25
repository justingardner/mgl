#ifdef documentation
=========================================================================

    program: mglPrivateInstallListener.c
         by: justin gardner
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       date: 06/18/08
    purpose: Installs an event-tap to get keyboard events. Event-taps are
              a low level accessibilty function that gets keyboard/mouse
              events at a very low level (before application windows). We
              intall a "listener" which is a callback that is called every
              time there is a new event. This listener is run in a separate
              thread and stores the keyboard and mouse events using an
              objective-c based NSMutableArray. Then recalling this function
              returns the events for processing with mgl.
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include <pthread.h>

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __eventtap__

////////////////////////
//   define section   //
////////////////////////
#define TRUE 1
#define FALSE 0
#define INIT 1
#define GETKEYEVENT 2
#define GETMOUSEEVENT 3
#define QUIT 0
#define GETKEYS 4
#define GETALLKEYEVENTS 5
#define GETALLMOUSEEVENTS 6
#define EATKEYS 7
#define MAXEATKEYS 256
#define MAXKEYCODES 128

/////////////////////
//   queue event   //
/////////////////////
@interface queueEvent : NSObject {
  CGEventRef event;
  CGEventType type;
}
- (id)initWithEventAndType:(CGEventRef)initEvent :(CGEventType)initType;
- (CGEventRef)event;
- (CGKeyCode)keycode;
- (int)keyboardType;
- (double)timestamp;
- (CGEventType)type;
- (CGEventFlags)eventFlags;
- (int)clickState;
- (int)buttonNumber;
- (CGPoint)mouseLocation;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* setupEventTap(void *data);
void launchSetupEventTapAsThread();
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
CGEventRef eatEvent(CGEventRef event, queueEvent *qEvent);
void mglPrivateListenerOnExit(void);

////////////////
//   globals  //
////////////////
static CFMachPortRef gEventTap;
static pthread_mutex_t mut;
static int eventTapInstalled = FALSE;
static NSAutoreleasePool *gListenerPool;
static NSMutableArray *gKeyboardEventQueue;
static NSMutableArray *gMouseEventQueue;
static double gKeyStatus[MAXKEYCODES];
static unsigned char gEatKeys[MAXEATKEYS];
static int gavewarning = 0;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // start auto release pool - I don't _think_ I need this autorelease
  //pool, since we make a global one when we init. This one was not
  // getting cleaned up properly and causing a memory fault. So
  // commenting out.
  // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // get which command this is
  int command = mxGetScalar(prhs[0]);

  int i;
  CGKeyCode keycode;
  double timestamp;
  CGEventType type;
  CGEventFlags eventFlags;
  CGEventRef event;
  int keyboardType;

  // INIT command -----------------------------------------------------------------
  if (command == INIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;

    // start the thread that will have a callback that gets called every
    // time there is a keyboard or mouse event of interest
    if (!eventTapInstalled) {
      // init pthread_mutex
      pthread_mutex_init(&mut,NULL);
      pthread_mutex_lock(&mut);
      if (~eventTapInstalled) {
	// first check if the accessibility API is enabled, cause otherwise we are F*&%ed.
	if (!AXAPIEnabled() & !gavewarning) {
	  // give warning (got rid of all the stuff to open the panel and help the user, since
	  // this caused problems when run from a background thread
	  mexPrintf("(mglPrivateListener) !!! **WARNING** To get keyboard events, you must allow Terminal to 'control your computer' by going to System Preferences/Privacy/Accessibility and adding Terminal to the list of apps that are allowed to control your computer. See http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events\n !!!");
	  pthread_mutex_unlock(&mut);
	  return;
	}
	// init the event queue
	gListenerPool = [[NSAutoreleasePool alloc] init];
	gKeyboardEventQueue = [[NSMutableArray alloc] init];
	gMouseEventQueue = [[NSMutableArray alloc] init];
	// default to no keys to eat
	gEatKeys[0] = 0;
	// set up the event tap
	launchSetupEventTapAsThread();
	// and remember that we have an event tap thread running
	eventTapInstalled = TRUE;
	// and clear the gKeyStatus array
	for (i = 0; i < MAXKEYCODES; i++)
	  gKeyStatus[i] = 0;
	mexPrintf("(mglPrivateListener) Starting keyboard and mouse event tap. End with mglListener('quit').\n");
	// tell matlab to call this function to cleanup properly
	mexAtExit(mglPrivateListenerOnExit);
      }
      pthread_mutex_unlock(&mut);
      // started running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
    else {
      // already running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
  }
  // GETKEYEVENT command ----------------------------------------------------------
  else if (command == GETKEYEVENT) {
    if (eventTapInstalled) {
      // get the last event.
      pthread_mutex_lock(&mut);
      // see how many events we have
      unsigned count = [gKeyboardEventQueue count];
      // if we have more than one,
      if (count >= 1) {
        queueEvent *qEvent;
	// get the last event
        qEvent = [gKeyboardEventQueue objectAtIndex:0];
	// and get the keycode,flags and timestamp
        keycode = [qEvent keycode];
        timestamp = [qEvent timestamp];
        eventFlags = [qEvent eventFlags];
        keyboardType = [qEvent keyboardType];
	// remove it from the queue
        [gKeyboardEventQueue removeAllObjects];
	// release the mutex
        pthread_mutex_unlock(&mut);
	// return event as a matlab structure
        const char *fieldNames[] =  {"when","keyCode","shift","control","alt","command","capslock","keyboard"};
        int outDims[2] = {1, 1};
        plhs[0] = mxCreateStructArray(1,outDims,8,fieldNames);

        mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"when")) = timestamp;
        mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"keyCode")) = (double)keycode;
        mxSetField(plhs[0],0,"shift",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"shift")) = (double)(eventFlags&kCGEventFlagMaskShift) ? 1:0;
        mxSetField(plhs[0],0,"control",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"control")) = (double)(eventFlags&kCGEventFlagMaskControl) ? 1:0;
        mxSetField(plhs[0],0,"alt",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"alt")) = (double)(eventFlags&kCGEventFlagMaskAlternate) ? 1:0;
        mxSetField(plhs[0],0,"command",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"command")) = (double)(eventFlags&kCGEventFlagMaskCommand) ? 1:0;
        mxSetField(plhs[0],0,"capslock",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"capslock")) = (double)(eventFlags&kCGEventFlagMaskAlphaShift) ? 1:0;
        mxSetField(plhs[0],0,"keyboard",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"keyboard")) = (double)keyboardType;
      }
      else {
	// no event found, unlock mutex and return empty
        pthread_mutex_unlock(&mut);
        plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
    }
    else {
      mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting keyboard events\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    }

  }
  // GETALLKEYEVENTS command ----------------------------------------------------------
  else if (command == GETALLKEYEVENTS) {
    if (eventTapInstalled) {
      pthread_mutex_lock(&mut);
      // see how many events we have
      unsigned count = [gKeyboardEventQueue count];
      // if we have more than one,
      if (count > 0) {
        int i = 0;
	// return event as a matlab structure
        const char *fieldNames[] =  {"when","keyCode"};
        int outDims[2] = {1, 1};
        plhs[0] = mxCreateStructArray(1,outDims,2,fieldNames);

        mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
        double *timestampOut = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
        mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,count,mxREAL));
        double *keycodeOut = (double*)mxGetPr(mxGetField(plhs[0],0,"keyCode"));
        while (count--) {
          queueEvent *qEvent;
	  // get the last event
          qEvent = [gKeyboardEventQueue objectAtIndex:0];
	  // and get the keycode,flags and timestamp
          keycodeOut[i] = [qEvent keycode];
          timestampOut[i++] = [qEvent timestamp];
	  // remove it from the queue
          [gKeyboardEventQueue removeObjectAtIndex:0];
        }
	// release the mutex
        pthread_mutex_unlock(&mut);
      }
      else {
	// no event found, unlock mutex and return empty
        pthread_mutex_unlock(&mut);
        plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
    }
    else {
      mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting keyboard events\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    }

  }
  // GETMOUSEEVENT command --------------------------------------------------------
  else if (command == GETMOUSEEVENT) {
    if (eventTapInstalled) {
      // get the last event.
      pthread_mutex_lock(&mut);
      // see how many events we have
      unsigned count = [gMouseEventQueue count];
      // if we have more than one,
      if (count >= 1) {
        queueEvent *qEvent;
    // get the last event
        qEvent = [gMouseEventQueue objectAtIndex:0];
    // and get the clickState, buttonNumber, timestamp and location
        int clickState = [qEvent clickState];
        int buttonNumber = [qEvent buttonNumber];
        timestamp = [qEvent timestamp];
        CGPoint mouseLocation = [qEvent mouseLocation];
    // remove it from the queue
        [gMouseEventQueue removeObjectAtIndex:0];
    // release the mutex
        pthread_mutex_unlock(&mut);
    // return event as a matlab structure
        const char *fieldNames[] =  {"when","buttons","x","y","clickState"};
        int outDims[2] = {1, 1};
        plhs[0] = mxCreateStructArray(1,outDims,5,fieldNames);

        mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"when")) = timestamp;
        mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"buttons")) = (double)buttonNumber;
        mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"x")) = (double)mouseLocation.x;
        mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"y")) = (double)mouseLocation.y;
        mxSetField(plhs[0],0,"clickState",mxCreateDoubleMatrix(1,1,mxREAL));
        *(double*)mxGetPr(mxGetField(plhs[0],0,"clickState")) = (double)clickState;
      }
      else {
    // no event found, unlock mutex and return empty
        pthread_mutex_unlock(&mut);
        plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
    }
    else {
      mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting mouse events\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    }

  }
  // GETALLMOUSEEVENTS command --------------------------------------------------------
  else if (command == GETALLMOUSEEVENTS) {
    if (eventTapInstalled) {
      // get all pending events
      pthread_mutex_lock(&mut);
      // see how many events we have
      unsigned count = [gMouseEventQueue count];
      // if we have more than one,
      if (count > 0) {
        int i = 0;
    // return event as a matlab structure
        const char *fieldNames[] =  {"when","buttons","x","y","clickState"};
        int outDims[2] = {1, 1};
        plhs[0] = mxCreateStructArray(1,outDims,5,fieldNames);

        mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
        double *when = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
        mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,count,mxREAL));
        double *buttonNumber = (double*)mxGetPr(mxGetField(plhs[0],0,"buttons"));
        mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,count,mxREAL));
        double *x = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
        mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,count,mxREAL));
        double *y = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
        mxSetField(plhs[0],0,"clickState",mxCreateDoubleMatrix(1,count,mxREAL));
        double *clickState = (double*)mxGetPr(mxGetField(plhs[0],0,"clickState"));
    // if we have more than one,
        while (count--) {
          queueEvent *qEvent;
      // get the last event
          qEvent = [gMouseEventQueue objectAtIndex:0];
      // and get the clickState, buttonNumber, timestamp and location
          clickState[i] = [qEvent clickState];
          buttonNumber[i] = [qEvent buttonNumber];
          when[i] = [qEvent timestamp];
          CGPoint mouseLocation = [qEvent mouseLocation];
          x[i] = mouseLocation.x;
          y[i++] = mouseLocation.y;
      // remove it from the queue
          [gMouseEventQueue removeObjectAtIndex:0];
        }
    // release the mutex
        pthread_mutex_unlock(&mut);
      }
      else {
    // no event found, unlock mutex and return empty
        pthread_mutex_unlock(&mut);
        plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
    }
    else {
      mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting mouse events\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    }

  }
  // GETKEYS command --------------------------------------------------------
  else if (command == GETKEYS) {
    plhs[0] = mxCreateDoubleMatrix(1,MAXKEYCODES,mxREAL);
    double *outptr = mxGetPr(plhs[0]);
    for (i = 0; i < MAXKEYCODES; i++)
      outptr[i] = gKeyStatus[i];
  }
  // EATKEYS command ----------------------------------------------------------
  else if (command == EATKEYS) {
    // return argument
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    // check if eventTap is installed
    if (eventTapInstalled) {
      // get the keycodes that are to be eaten
      int nkeys = MIN(mxGetNumberOfElements(prhs[1]),MAXEATKEYS);
      double *keyCodesToEat = (double*)mxGetPr(prhs[1]);
      // get the mutex
      pthread_mutex_lock(&mut);
      int i;
      mexPrintf("(mglPrivateListener) Eating all keypresses with keycodes: ");
      for (i = 0;i < nkeys;i++) {
        mexPrintf("%i ",(int)keyCodesToEat[i]);
        gEatKeys[i] = (unsigned char)(int)keyCodesToEat[i];
      }
      mexPrintf("\n");
      gEatKeys[nkeys] = 0;
      // release the mutex
      pthread_mutex_unlock(&mut);
      // return argument set to 1
      *mxGetPr(plhs[0]) = 1;
    }
    else {
      mexPrintf("(mglPrivateListener) Cannot eat keys if listener is not installed\n");
      // return argument set to 0
      *mxGetPr(plhs[0]) = 0;
    }
  }
  // QUIT command -----------------------------------------------------------------
  else if (command == QUIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;

    // disable the event tap
    if (eventTapInstalled) {
      // Disable the event tap.
      CGEventTapEnable(gEventTap, false);

      // shut down event loop
      CFRunLoopStop(CFRunLoopGetCurrent());

      // release the event queue
      //      mexPrintf("(mglPrivateListener) FIX FIX FIX: Free event queue here not working\n");
      [gListenerPool drain];

      // set flag to not installed
      eventTapInstalled = FALSE;

      // destroy mutex
      pthread_mutex_destroy(&mut);

      // message to user
      mexPrintf("(mglPrivateListener) Ending keyboard and mouse event tap\n");
    }
  }
}

//////////////////////////////////
//   mglPrivateListenerOnExit   //
//////////////////////////////////
void mglPrivateListenerOnExit()
{
  // call mglSwitchDisplay with -1 to close all open screens
  mxArray *callInput =  mxCreateDoubleMatrix(1,1,mxREAL);
  *(double*)mxGetPr(callInput) = 0;
  mexCallMATLAB(0,NULL,1,&callInput,"mglListener");
}

///////////////////////
//   setupEventTap   //
///////////////////////
void* setupEventTap(void *data)
{
  CGEventMask        eventMask;
  CFRunLoopSourceRef runLoopSource;

  // Create an event tap. We are interested in key presses and mouse presses
  eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp) | (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown));
  gEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, myCGEventCallback, NULL);

  // see if it was created properly
  if (!gEventTap) {
    mexPrintf("(mglPrivateListener) Failed to create event tap\n");
    return NULL;
  }

  // Create a run loop source.
  runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gEventTap, 0);

  // Add to the current run loop.
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

  // Enable the event tap.
  CGEventTapEnable(gEventTap, true);

  // see if it is enable
  if (!CGEventTapIsEnabled(gEventTap)) {
    mexPrintf("(mglPrivateListener) Failed to enable event tap\n");
    return NULL;
  }


  // set up run loop
  CFRunLoopRun();

  return NULL;
}

////////////////////////
//   event callback   //
////////////////////////
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
  // record the event in the globals, first lock the mutex
  // to avoid concurrent access to the global variables
  pthread_mutex_lock(&mut);
  // check for keyboard event
  if (type == kCGEventKeyDown) {
    // save the event in the queue
    queueEvent *qEvent;
    qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
    [gKeyboardEventQueue addObject:qEvent];
    // also save the keystatus
    if ([qEvent keycode] <= MAXKEYCODES)
      gKeyStatus[[qEvent keycode]-1] = [qEvent timestamp];
    // check for edible keycode (i.e. one that we don't want to return)
    event = eatEvent(event,qEvent);
    // release qEvent as it is now in the keyboard event queue
    [qEvent release];
  }
  else if (type == kCGEventKeyUp) {
    // convert to a queueEvent to get fields easier
    queueEvent *qEvent;
    qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
    // set the gKeyStatus back to 0
    if ([qEvent keycode] <= MAXKEYCODES)
      gKeyStatus[[qEvent keycode]-1] = 0;
    // check for edible keycode (i.e. one that we don't want to return)
    event = eatEvent(event,qEvent);
    // release qEvent
    [qEvent release];
  }
  else if ((type == kCGEventLeftMouseDown) || (type == kCGEventRightMouseDown)){
    // save the event in the queue
    queueEvent *qEvent;
    qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
    [gMouseEventQueue addObject:qEvent];
  }

  // unlock mutex
  pthread_mutex_unlock(&mut);
  // return the event for normal OS processing
  return event;
}

//////////////////
//   eatEvent   //
//////////////////
CGEventRef eatEvent(CGEventRef event, queueEvent *qEvent)
{
  int i = 0;
  // check if keyup or keydown event
  if (([qEvent type] == kCGEventKeyDown) || ([qEvent type] == kCGEventKeyDown)) {
    // now check to make sure there is no modifier flag (i.e. always
    // let key events when a modifier key is down through)
    if (!([qEvent eventFlags] & (kCGEventFlagMaskShift | kCGEventFlagMaskControl | kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand | kCGEventFlagMaskAlphaShift))) {
      // now check to see if the keyCode matches one that we are
      // supposed to eat.
      while (gEatKeys[i] && (i < MAXEATKEYS)) {
        if (gEatKeys[i++] == (unsigned char)[qEvent keycode]){
      // then eat the event (i.e. it will not be sent to any application)
          event = NULL;
        }
      }
    }
    // if we are not going to eat the key event, then we should stop eating keys
    if (event != NULL) gEatKeys[0] = 0;
  }
  // return the event (this may be NULL if we have decided to eat the event)
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
    mexPrintf("(mglPrivateListener) Error could not setup event tap thread: error %i\n",threadError);
}

///////////////////////////////////
//   queue event implementation  //
///////////////////////////////////
@implementation queueEvent 
- (id)initWithEventAndType:(CGEventRef)initEvent :(CGEventType)initType
{
  // init parent
  [super init];
  // set internals
  event = CGEventCreateCopy(initEvent);
  type = initType;
  //return self
  return self;
}
- (CGEventRef)event
{
  return event;
}
- (CGEventType)type
{
  return type;
}
- (CGKeyCode)keycode
{
  return (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)+1;
}
- (int)keyboardType
{
  return (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
}
- (double)timestamp
{
  return (double)CGEventGetTimestamp(event)/1e9;
}
- (CGEventFlags)eventFlags
{
  return (double)CGEventGetFlags(event);
}
- (int)clickState
{
  return CGEventGetIntegerValueField(event, kCGMouseEventClickState);
}
- (int)buttonNumber
{
  return CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber)+1;
}
- (CGPoint)mouseLocation
{
  return CGEventGetLocation(event);
}
- (void)dealloc
{
  CFRelease(event);
  [super dealloc];
}
@end

#else// __eventtap__
//-----------------------------------------------------------------------------------///
// ***************************** other-os specific code  **************************** //
//-----------------------------------------------------------------------------------///
// THIS FUNCTION IS ONLY FOR MAC COCOA
//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *(double*)mxGetPr(plhs[0]) = 0;
}
#endif

