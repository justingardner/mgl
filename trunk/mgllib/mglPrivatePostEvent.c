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
                3:LIST. Lists all pending events
                4:MOUSEMOVE. Move the mouse to the specified x,y position
                5:MOUSEDOWN. Click the specified mouse button at the specified x,y position
                6:MOUSEUP. Click the specified mouse button at the specified x,y position
 
                Note that this function relies on objective-c constructs
                like the NSMutabaleArray - it could be written without this
                since that is just that we have an easy way to implement
                a sortable expandable event queue. These structures might
                be available in openstep/GNUstep. The only really OS-specific
                call is posting the event, which is one line of code marked below
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
double isEscKeyDown();
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
#define MOUSEMOVE 4
#define MOUSEDOWN 5
#define MOUSEUP 6

/////////////////////
//   queue event   //
/////////////////////
@interface postQueueEvent : NSObject {
  double time;
  int type;
  int keyCode;
  int keyDown;
  CGEventType mouseEventType;
  CGPoint mousePoint;
  CGMouseButton mouseButton;
}
- (id)initWithTimeKeyCodeAndKeyDown:(double)initTime :(int)initKeyCode :(int)initKeyDown;
- (id)initWithTimeMouseEventXY:(double)initTime :(CGEventType)initMouseType :(CGFloat)x :(CGFloat)y;
- (id)initWithTimeMouseEvent:(double)initTime :(CGEventType)initMouseType;
- (id)initQuitEventWithTime:(double)initTime;
- (int)eventType;
- (void)postEvent;
- (double)timeInSeconds;
- (NSComparisonResult)compareByTime:(postQueueEvent *)otherQueueEvent;
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
      int keyCode = (int)(double)mxGetScalar(prhs[2])-1;
      int keyDown = (int)(double)mxGetScalar(prhs[3]);

      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);

      // create the event
      postQueueEvent *qEvent = [[postQueueEvent alloc] initWithTimeKeyCodeAndKeyDown:time :keyCode :keyDown];

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
  // MOUSEMOVE command --------------------------------------------------------------
  else if (command == MOUSEMOVE) {
    // add a key event if the 
    if (mglGetGlobalDouble("postEventEnabled")) {
      // check command line arguments
      if (nrhs != 4) {
	usageError("mglPostEvent");
	return;
      }

      // get x and y
      double time = (double)mxGetScalar(prhs[1]);
      CGFloat x = (CGFloat)(double)mxGetScalar(prhs[2]);
      CGFloat y = (CGFloat)(double)mxGetScalar(prhs[3]);

      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);

      // create the event
      postQueueEvent *qEvent = [[postQueueEvent alloc] initWithTimeMouseEventXY:time :kCGEventMouseMoved :x :y];

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
  // MOUSEUP/DOWN command --------------------------------------------------------------
  else if ((command == MOUSEUP) || (command == MOUSEDOWN)){
    // add a key event if the 
    if (mglGetGlobalDouble("postEventEnabled")) {
      // check command line arguments
      if (nrhs != 5) {
	usageError("mglPostEvent");
	return;
      }

      // get whichButton
      double time = (double)mxGetScalar(prhs[1]);
      int whichButton = (int)(double)mxGetScalar(prhs[2]);
      CGFloat x = (CGFloat)(double)mxGetScalar(prhs[3]);
      CGFloat y = (CGFloat)(double)mxGetScalar(prhs[4]);
      CGEventType mouseEventType;

      // create the right kind of event
      switch (whichButton) {
        case 0:
	  if (command == MOUSEUP)
	    mouseEventType = kCGEventLeftMouseUp;
	  else
	    mouseEventType = kCGEventLeftMouseDown;
	  break;
        case 1:
	  if (command == MOUSEUP)
	    mouseEventType = kCGEventRightMouseUp;
	  else
	    mouseEventType = kCGEventRightMouseDown;
	  break;
      }

      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);

      // create the event
      postQueueEvent *qEvent = [[postQueueEvent alloc] initWithTimeMouseEventXY:time :mouseEventType :x :y];

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
    return;
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
    postQueueEvent *qEvent = [[postQueueEvent alloc] initQuitEventWithTime:getCurrentTimeInSeconds()];
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
    // if we have the esc key down, then quit
    if (isEscKeyDown()) quitPostEvent();
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
	  //[gPool drain];
	  // destroy mutex
	  pthread_mutex_destroy(&mut);
	  return NULL;
	}
	else {
	  // post the event
	  [[gEventQueue objectAtIndex:0] postEvent];
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
#ifdef __MAC_10_8
  static const double kOneBillion = 1000 * 1000 * 1000; 
  static mach_timebase_info_data_t sTimebaseInfo;

  if (sTimebaseInfo.denom == 0) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  // This seems to work on Mac OS 10.9 with a Mac PRO. But note that sTimebaseInfo is hardware implementation
  // dependent. The mach_absolute_time is ticks since the machine started and to convert it to ms you
  // multiply by the fraction in sTimebaseInfo - worried that this could possibly overflow the
  // 64 bit int values depending on what is actually returned. Maybe that is not a problem
  return((double)((mach_absolute_time()*(uint64_t)(sTimebaseInfo.numer)/(uint64_t)(sTimebaseInfo.denom)))/kOneBillion);
#else
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
#endif
}

////////////////////////
//    isEscKeyDown    //
////////////////////////
double isEscKeyDown()
{
  // This line just checks for a shiftKey down using a Carbon call
  //  return ((GetCurrentKeyModifiers() & shiftKey) != 0) ? 1: 0;

  // This is old carbon code way of checking keys and the ESC key
  // is hardcoded to key number 53.
  KeyMap theKeys;
  GetKeys(theKeys);
  unsigned char *keybytes = (unsigned char *) theKeys;
  short k = 53;

  // get the esc key
  return ((keybytes[k>>3] & (1 << (k&7))) != 0);
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
@implementation postQueueEvent 
// init a key event
- (id)initWithTimeKeyCodeAndKeyDown:(double)initTime :(int)initKeyCode :(int)initKeyDown;
{
  // init parent
  [super init];
  // set internals
  time = initTime;
  type = KEYEVENT;
  keyCode = initKeyCode;
  keyDown = initKeyDown;
  //return self
  return self;
}
// init a quit event
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
- (id)initWithTimeMouseEventXY:(double)initTime :(CGEventType)initMouseType :(CGFloat)x :(CGFloat)y
{
  // init parent
  [super init];
  // set internals
  time = initTime;
  type = MOUSEMOVE;
  mouseEventType = initMouseType;
  mousePoint.x = x;
  mousePoint.y = y;
  //return self
  return self;
}
- (id)initWithTimeMouseEvent:(double)initTime :(CGEventType)initMouseType
{
  // init parent
  [super init];
  // set internals
  time = initTime;
  type = MOUSEMOVE;
  mouseEventType = initMouseType;
  mousePoint.x = 0;
  mousePoint.y = 0;
  //return self
  return self;
}
//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
// post the event (i.e. send it to the os. This is the only
// truly os-specific function
- (void)postEvent
{
  if (type == KEYEVENT) {
    // create the desired key event
    CGEventRef event = CGEventCreateKeyboardEvent(NULL,(CGKeyCode)keyCode,(bool)keyDown);
    // post it at the earliest location in the system event-queue that we can
    CGEventPost(kCGHIDEventTap,event);
    // and release the event
    CFRelease(event);
  }
  else if ((type == MOUSEMOVE)||(type == MOUSEDOWN)||(type == MOUSEUP)) {
    // create the desired mouse event
    CGEventRef event = CGEventCreateMouseEvent(NULL,mouseEventType,mousePoint,mouseDown);
    // post it at the earliest location in the system event-queue that we can
    CGEventPost(kCGHIDEventTap,event);
    // and release the event
    CFRelease(event);
  }
}
//-----------------------------------------------------------------------------------///
// **************************** end mac specific code  ****************************** //
//-----------------------------------------------------------------------------------///
// comparison function, used to sort the queue in time order
- (NSComparisonResult)compareByTime:(postQueueEvent*)otherQueueEvent
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
// return the time in seconds of the event
- (double)timeInSeconds
{
  return time;
}  
// return the event type
- (int)eventType
{
  return type;
}  
// a descriptive string for listing pending events
- (NSString *)description
{
  NSString *descriptionString;
  if (type == KEYEVENT) {
    if (keyDown)
      descriptionString = [NSString stringWithFormat:@"keyCode: %i down", keyCode];
    else
      descriptionString = [NSString stringWithFormat:@"keyCode: %i up", keyCode];
  }
  return descriptionString;
}
// dealloc the event
- (void)dealloc
{
  // release event
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

