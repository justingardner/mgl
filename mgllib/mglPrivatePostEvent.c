#ifdef documentation
=========================================================================

       program: mglprivatePostEvent.c
            by: justin gardner
     copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
          date: 01/10/08
       purpose: This uses the low level accessibility functions to create
                keyboard mouse events. It is useful for testing programs.
                In a separate thread a while loop checks a desired event
                queue and issues keyboard events at appropriate times.
                This can be used to generate periodic backticks or simulated
                subject responses. It takes a numbered command:

                1:INIT. Starts the thread that posts events
                0:QUIT. Shuts down the thread that posts events
                2:KEYEVENT. Post a queue event (INIT should have already been
  		  called). In this case, 3 arguments are expected. The time
    	          to generate the event in seconds. The keyCode and a boolean
                  as to whether it is a keyDown event.
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

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* eventDispatcher(void *data);
void launchEventDispatcherAsThread();
double getCurrentTimeInSeconds();
void quitPostEvent(void);
 
////////////////////////
//   define section   //
////////////////////////
#define TRUE 1
#define FALSE 0

#define QUIT 0
#define INIT 1
#define KEYEVENT 2
#define LIST 3

/////////////////////
//   queue event   //
/////////////////////
@interface queueEvent : NSObject {
  double time;
  int type;
  CGEventRef event;
}
- (id)initWithTimeKeyCodeAndKeyDown:(double)initTime :(CGKeyCode)keyCode :(bool)keyDown;
- (id)initQuitEventWithTime:(double)initTime;
- (CGEventRef)event;
- (int)eventType;
- (double)timeInSeconds;
- (NSComparisonResult)compareByTime:(queueEvent *)otherQueueEvent;
- (NSString *)description;
- (void)dealloc;
@end

////////////////
//   globals  //
////////////////
static pthread_mutex_t mut;
static NSAutoreleasePool *gPool;
static NSMutableArray *gEventQueue;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // check command line arguments
  if (nrhs < 1) {
    usageError("mglPostEvent");
    return;
  }

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // get which command this is
  int command = mxGetScalar(prhs[0]);

  // INIT command -----------------------------------------------------------------
  if (command == INIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;

    // start the thread that will have a callback that gets called every
    // time there is a keyboard or mouse event of interest
    if (!mglGetGlobalDouble("postEventEnabled")) {
      // first check if the accessibility API is enabled, cause otherwise we are F*&%ed.
      if (!AXAPIEnabled()) {
	int ret = NSRunAlertPanel (@"To get keyboard events, you must have the Accessibility API enabled.  Would you like to launch System Preferences so that you can turn on \"Enable access for assistive devices\".", @"", @"OK",@"", @"Cancel");
	switch (ret) {
	case NSAlertDefaultReturn:
	  [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
	  // busy wait until accessibility is activated
	  while (!AXAPIEnabled());
	  break;
	default:
	  [pool drain];
	  return;
	  break;
	}
      }
      // init pthread_mutex
      pthread_mutex_init(&mut,NULL);
      // init the event queue
      gPool = [[NSAutoreleasePool alloc] init];
      gEventQueue = [[NSMutableArray alloc] init];
      // set up the event tap
      launchEventDispatcherAsThread();
      // and remember that we have an event tap thread running
      mglSetGlobalDouble("postEventEnabled",TRUE);
      // tell mex to call the quit function if we get cleared
      mexAtExit(quitPostEvent);
      // started running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
    else {
      // already running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
  }
  // KEYEVENT command --------------------------------------------------------------
  else if (command == KEYEVENT) {
    // add a key event if the 
    if (mglGetGlobalDouble("postEventEnabled")) {
      // check command line arguments
      if (nrhs != 4) {
	usageError("mglPostEvent");
	return;
      }

      // get time, keyCode and keyDown
      double time = (double)mxGetScalar(prhs[1]);
      CGKeyCode keyCode = (CGKeyCode)(double)mxGetScalar(prhs[2])-1;
      bool keyDown = (bool)(double)mxGetScalar(prhs[3]);

      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);

      // create the event
      queueEvent *qEvent = [[queueEvent alloc] initWithTimeKeyCodeAndKeyDown:time :keyCode :keyDown];

      // add the event to the event queue
      [gEventQueue addObject:qEvent];
      [qEvent release];

      // sort the event queue by time
      SEL compareByTime = @selector(compareByTime:);
      [gEventQueue sortUsingSelector:compareByTime];

      // release mutex
      pthread_mutex_unlock(&mut);
    }
  }
  // LIST command -----------------------------------------------------------------
  else if (command == LIST) {
    if (mglGetGlobalDouble("postEventEnabled")) {
      int i;
      if ([gEventQueue count] == 0) {
	mexPrintf("(mglPostEvent) No events pending.\n");
      }
      else {
	for(i = 0; i < [gEventQueue count]; i++) {
	  mexPrintf("(mglPostEvent) Event %s pending in %f seconds.\n",[[[gEventQueue objectAtIndex:i] description] cStringUsingEncoding:NSASCIIStringEncoding],[[gEventQueue objectAtIndex:i] timeInSeconds] - getCurrentTimeInSeconds());
	}
      }
    }
    else {
      mexPrintf("(mglPostEvent) Post event has not been enabled.\n");
    }
  }
  // QUIT command -----------------------------------------------------------------
  else if (command == QUIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;
    // quit
    quitPostEvent();
  }
  [pool drain];

}

///////////////////////
//   quitPostEvent   //
///////////////////////
void quitPostEvent(void)
{
  // disable the event tap
  if (mglGetGlobalDouble("postEventEnabled")) {
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&mut);
    
    // add a quit event
    queueEvent *qEvent = [[queueEvent alloc] initQuitEventWithTime:getCurrentTimeInSeconds()];
    [gEventQueue insertObject:qEvent atIndex:0];
    [qEvent release];

    // release mutex
    pthread_mutex_unlock(&mut);

    // set flag to not installed
    mglSetGlobalDouble("postEventEnabled",FALSE);
      
    // message to user
    mexPrintf("(mglPrivatePostEvent) Ending post event thread\n");
  }
}

/////////////////////////
//   eventDispatcher   //
/////////////////////////
void* eventDispatcher(void *data)
{
  double currentTimeInSeconds;

  while(1) {
    // get the current time in seconds
    currentTimeInSeconds = getCurrentTimeInSeconds();
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&mut);
    // if no more events then stop processing.
    if ([gEventQueue count] > 0) {
      // see if we need to post the top element on the queue
      if (currentTimeInSeconds > [[gEventQueue objectAtIndex:0] timeInSeconds]) {
	// handle a quit event
	if ([[gEventQueue objectAtIndex:0] eventType] == QUIT) {
	  // remove all pending events
	  [gEventQueue removeAllObjects];
	  // release the event queue
	  [gEventQueue release];
	  [gPool drain];
	  // destroy mutex
	  pthread_mutex_destroy(&mut);
	  return NULL;
	}
	else {
	  // post the event
	  CGEventPost(kCGHIDEventTap,[[gEventQueue objectAtIndex:0] event]);
	}
	// and remove it from the queue
	[gEventQueue removeObjectAtIndex:0];
      }
    }
    // release mutex
    pthread_mutex_unlock(&mut);
  }

  return NULL;
}

////////////////////////
//   getCurrentTime   //
////////////////////////
double getCurrentTimeInSeconds()
{
  // get current time
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  // convert microseconds to double
  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)currentTime.hi; 
  double lowerHalf = (double)currentTime.lo; 
  doubleValue = (upperHalf * twoPower32) + lowerHalf; 
  return(0.000001*doubleValue);
}

/////////////////////////////////////
//   launchEventDispatcherAsThread //
/////////////////////////////////////
void launchEventDispatcherAsThread()
{
  // Create the thread using POSIX routines.
  pthread_attr_t  attr;
  pthread_t       posixThreadID;
 
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
 
  int threadError = pthread_create(&posixThreadID, &attr, &eventDispatcher, NULL);
 
  pthread_attr_destroy(&attr);
  if (threadError != 0)
      mexPrintf("(mglprivatePostEvent) Error could not setup event maker thread: error %i\n",threadError);
}

///////////////////////////////////
//   queue event implementation  //
///////////////////////////////////
@implementation queueEvent 
- (id)initWithTimeKeyCodeAndKeyDown:(double)initTime :(CGKeyCode)keyCode :(bool)keyDown;
{
  // init parent
  [super init];
  // set internals
  time = initTime;
  type = KEYEVENT;
  event = CGEventCreateKeyboardEvent(NULL,keyCode,keyDown);
  //return self
  return self;
}
- (id)initQuitEventWithTime:(double)initTime
{
  // init parent
  [super init];
  // set internals
  time = initTime;
  type = QUIT;
  //return self
  return self;
}
- (CGEventRef)event
{
  return event;
}
- (NSComparisonResult)compareByTime:(queueEvent*)otherQueueEvent
{
  if ([self timeInSeconds] > [otherQueueEvent timeInSeconds])  {
    return NSOrderedDescending;
  }
  else if ([self timeInSeconds] == [otherQueueEvent timeInSeconds]) {
    return NSOrderedSame;
  }
  else {
    return NSOrderedAscending;
  }
}
- (double)timeInSeconds
{
  return time;
}  
- (int)eventType
{
  return type;
}  
- (NSString *)description
{
  NSString *descriptionString;
  if (type == KEYEVENT) {
    int keyCode = (int)(CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)+1;
    CGEventType eventType = CGEventGetType(event);
    if (eventType == kCGEventKeyDown)
      descriptionString = [NSString stringWithFormat:@"keyCode: %i down", keyCode];
    else
      descriptionString = [NSString stringWithFormat:@"keyCode: %i up", keyCode];
  }
}
- (void)dealloc
{
  // release event
  if (type != QUIT) CFRelease(event);
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

