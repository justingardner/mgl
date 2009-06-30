#ifdef documentation
=========================================================================

       program: mglPrivateDigIO.c
            by: justin gardner
     copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
          date: 06/30/09
       purpose: Based on the mglPrivateListener.c code. This installs a 
                background process that reads and writes a NI digital
                IO device (based on NI-DAQmx Base -- you will need to install
                NI-DAQmx Base to compile and use. I have been using this on
                an NI USB device (NI USB-6501 24-line Digital I/O). See the
                MGL wiki for info on how to install the NI driver and use
                this code.
			   
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include <stdio.h>
#include <pthread.h>
#include "/Applications/National Instruments/NI-DAQmx Base/includes/NIDAQmxBase.h"
#import <Foundation/Foundation.h>
#include <mex.h>

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__

////////////////////////
//   define section   //
////////////////////////
#define INIT 1
#define DIGIN 2
#define DIGOUT 3
#define LIST 4
#define QUIT 0
// NIDAQ error checking macro
#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { goto Error; } }
// event types
#define DIGDOWN_EVENT 0
#define DIGUP_EVENT 1
#define DIGOUT_EVENT 2
#define QUIT_EVENT 3

/////////////////////
//   queue event   //
/////////////////////
@interface queueEvent : NSObject {
  int type;
  double time;
  uInt32 val;
}
- (id)initWithTypeTimeAndValue:(int)initType :(double)initTime :(uInt32)initVal;
- (id)initWithTypeAndValue:(int)initType :(uInt32)initVal;
- (id)initWithType:(int)initType;
- (double)time;
- (uInt32)val;
- (int)eventType;
- (void)doEvent;
- (NSComparisonResult)compareByTime:(queueEvent *)otherQueueEvent;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* nidaqThread(void *data);
void launchNidaqThread();
double getCurrentTimeInSeconds();
void quitNidaqThread(void);
// NIDAQ start/stop port reading/writing
int nidaqStartTask(int nidaqInputPortNum, int nidaqOutputPortNum);
void nidaqStopTask();
 
////////////////
//   globals  //
////////////////
static CFMachPortRef gEventTap;
static pthread_mutex_t mut;
static nidaqThreadInstalled = FALSE;
static NSAutoreleasePool *gPool;
static NSMutableArray *gDiginEventQueue;
static NSMutableArray *gDigoutEventQueue;
// NIDAQ specific globals
static TaskHandle nidaqInputTaskHandle = 0,nidaqOutputTaskHandle = 0;
static int nidaqInputPortNum = 1,nidaqOutputPortNum = 2;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
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
    if (!nidaqThreadInstalled) {
      // init pthread_mutex
      pthread_mutex_init(&mut,NULL);
      // init the event queue
      gPool = [[NSAutoreleasePool alloc] init];
      gDiginEventQueue = [[NSMutableArray alloc] init];
      gDigoutEventQueue = [[NSMutableArray alloc] init];
      // set up the event tap
      launchNidaqThread();
      // set up the nidaq ports
      if (nrhs >=2) nidaqInputPortNum = mxGetScalar(prhs[1]);
      if (nrhs >=3) nidaqOutputPortNum = mxGetScalar(prhs[2]);
      if (nidaqStartTask(nidaqInputPortNum,nidaqOutputPortNum) == 0) {
	quitNidaqThread();
	nidaqThreadInstalled = FALSE;
	mexPrintf("(mglPrivateDigIO) Could not start NIDAQ ports digin: %i and digout: %i\n",nidaqInputPortNum,nidaqOutputPortNum);
	*mxGetPr(plhs[0]) = 0;
	return;
      }
      // and remember that we have an event tap thread running
      nidaqThreadInstalled = TRUE;
      mexPrintf("(mglPrivateDigIO) Starting digIO thread digin port: Dev1/port%i digout port: Dev1/port%i. End with mglDigIO('quit').\n",nidaqInputPortNum,nidaqOutputPortNum);
      // started running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
    else {
      // already running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
  }
  // DIGIN command --------------------------------------------------------------
  else if (command == DIGIN) {
    if (nidaqThreadInstalled) {
      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);
      // see how many events we have
      unsigned count = [gDiginEventQueue count];
      // if we have more than one,
      if (count > 0) {
	int i = 0;
	// return event as a matlab structure
	const char *fieldNames[] =  {"type","val","when"};
	int outDims[2] = {1, 1};
	plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);
      
	mxSetField(plhs[0],0,"type",mxCreateDoubleMatrix(1,count,mxREAL));
	double *typeOut = (double*)mxGetPr(mxGetField(plhs[0],0,"type"));
	mxSetField(plhs[0],0,"val",mxCreateDoubleMatrix(1,count,mxREAL));
	double *valOut = (double*)mxGetPr(mxGetField(plhs[0],0,"val"));
	mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
	double *whenOut = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
	while (count--) {
	  queueEvent *qEvent;
	  // get the last event
	  qEvent = [gDiginEventQueue objectAtIndex:0];
	  // and get the value and time
	  typeOut[i] = [qEvent eventType];
	  valOut[i] = [qEvent val];
	  whenOut[i++] = [qEvent time];
	  // remove it from the queue
	  [gDiginEventQueue removeObjectAtIndex:0];
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
  }
  // DIGOUT command --------------------------------------------------------------
  else if (command == DIGOUT) {
    if (nidaqThreadInstalled) {
      // get value and time
      double time = (double)mxGetScalar(prhs[1]);
      uInt32 val = (uInt32)(double)mxGetScalar(prhs[2]);

      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);

      // create the event
      queueEvent *qEvent = [[queueEvent alloc] initWithTypeTimeAndValue:DIGOUT_EVENT :time :val];

      // add the event to the event queue
      [gDigoutEventQueue addObject:qEvent];
      [qEvent release];

      // sort the event queue by time
      SEL compareByTime = @selector(compareByTime:);
      [gDigoutEventQueue sortUsingSelector:compareByTime];

      // release mutex
      pthread_mutex_unlock(&mut);
    }
    // return 1
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 1;
  }
  // LIST command --------------------------------------------------------------
  else if (command == LIST) {
    if (nidaqThreadInstalled) {
      // lock the mutex to avoid concurrent access to the global variables
      pthread_mutex_lock(&mut);
      // display which ports we are using
      mexPrintf("(mglPrivateDigIO) DigIO thread is running. Input port is: Dev1/port%i. Output port is: Dev1/port%i\n",nidaqInputPortNum,nidaqOutputPortNum);
      if ([gDigoutEventQueue count] == 0) {
	mexPrintf("(mglPrivateDigIO) No events pending.\n");
      }
      else {
	int i;
	for(i = 0; i < [gDigoutEventQueue count]; i++) {
	  mexPrintf("(mglPrivateDigIO) Set output port to %i is pending in %f seconds.\n",[[gDigoutEventQueue objectAtIndex:i] val],[[gDigoutEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds());
	}
      }
      // release mutex
      pthread_mutex_unlock(&mut);
    }
    else {
      mexPrintf("(mglPrivateDigIO) DigIO thread is not running.\n");
    }
    // return 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;

  }

  // QUIT command -----------------------------------------------------------------
  else if (command == QUIT) {
    // return argument set to []
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    // disable the nidaq thread
    if (nidaqThreadInstalled) {
      quitNidaqThread();
    }
  }
  else {
    mexPrintf("(mglPrivateDigIO) Unknown command number %i\n",command);
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  }
}

/////////////////////
//   nidaqThread   //
/////////////////////
void* nidaqThread(void *data)
{
  double currentTimeInSeconds;

  // read the port once to get current state
  int32       read;
  uInt8 nidaqInputStatePrevious[1];
  nidaqInputStatePrevious[0] = 0;
  while(1) {
    // get the current time in seconds
    currentTimeInSeconds = getCurrentTimeInSeconds();
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&mut);
    // read current state of digio port
    uInt8 nidaqInputState[1];
    DAQmxBaseReadDigitalU8(nidaqInputTaskHandle,1,0.01,DAQmx_Val_GroupByChannel,nidaqInputState,1,&read,NULL);
    // see if it is different from previous state
    if (nidaqInputState[0] != nidaqInputStatePrevious[0]) {
      // check which bit has changes
      int bitnum;
      for (bitnum = 0;bitnum < 8;bitnum++) {
	if (((nidaqInputStatePrevious[0]>>bitnum)&0x1) != ((nidaqInputState[0]>>bitnum)&0x1)) {
	  if ((nidaqInputState[0]>>bitnum)&0x1) {
	    // add a digup event
	    queueEvent *qEvent = [[queueEvent alloc] initWithTypeAndValue:DIGUP_EVENT :bitnum];
	    [gDiginEventQueue insertObject:qEvent atIndex:0];
	    [qEvent release];
	  }
	  else {
	    // add a digdown event
	    queueEvent *qEvent = [[queueEvent alloc] initWithTypeAndValue:DIGDOWN_EVENT :bitnum];
	    [gDiginEventQueue insertObject:qEvent atIndex:0];
	    [qEvent release];
	  }
	}
      }
      nidaqInputStatePrevious[0] = nidaqInputState[0];
    }
    // check for digout event
    if ([gDigoutEventQueue count] > 0) {
      // see if we need to post the top element on the queue
      if (currentTimeInSeconds > [[gDigoutEventQueue objectAtIndex:0] time]) {
	// handle a quit event
	if ([[gDigoutEventQueue objectAtIndex:0] eventType] == QUIT_EVENT) {
	  // remove all pending events
	  [gDigoutEventQueue removeAllObjects];
	  [gDiginEventQueue removeAllObjects];
	  // release the event queue
	  [gDigoutEventQueue release];
	  [gDiginEventQueue release];
	  [gPool drain];
	  // destroy mutex
	  pthread_mutex_destroy(&mut);
	  // close nidaq ports
	  nidaqStopTask();
	  mexPrintf("(mglPrivateDigIO) Ending digIO thread and closing nidaq ports\n");
	  return NULL;
	}
	else {
	  // set the port
	  [[gDigoutEventQueue objectAtIndex:0] doEvent];
	}
	// and remove it from the queue
	[gDigoutEventQueue removeObjectAtIndex:0];
      }
    }
    // release mutex
    pthread_mutex_unlock(&mut);
  }

  return NULL;
}
 
///////////////////////////
//   launchNidaqThread   //
///////////////////////////
void launchNidaqThread()
{
  // Create the thread using POSIX routines.
  pthread_attr_t  attr;
  pthread_t       posixThreadID;
 
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
 
  int threadError = pthread_create(&posixThreadID, &attr, &nidaqThread, NULL);
 
  pthread_attr_destroy(&attr);
  if (threadError != 0)
      mexPrintf("(mglPrivateDigIO) Error could not setup digIO thread: error %i\n",threadError);
}

/////////////////////////
//   quitNidaqThread   //
/////////////////////////
void quitNidaqThread(void)
{
  // disable the nidaq thread
  // lock the mutex to avoid concurrent access to the global variables
  pthread_mutex_lock(&mut);
    
  // add a quit event
  queueEvent *qEvent = [[queueEvent alloc] initWithType:QUIT_EVENT];
  [gDigoutEventQueue insertObject:qEvent atIndex:0];
  [qEvent release];

  // set to thread not installed
  nidaqThreadInstalled = FALSE;

  // release mutex
  pthread_mutex_unlock(&mut);
}

///////////////////////////////////
//   queue event implementation  //
///////////////////////////////////
@implementation queueEvent 
- (id)initWithType:(int)initType
{
  // init parent
  [super init];
  // set internals
  type = initType;
  time = getCurrentTimeInSeconds();
  val = 0;
  //return self
  return self;
}
- (id)initWithTypeTimeAndValue:(int)initType :(double)initTime :(uInt32)initVal;
{
  // init parent
  [super init];
  // set internals
  type = initType;
  time = initTime;
  val = initVal;
  //return self
  return self;
}
- (id)initWithTypeAndValue:(int)initType :(uInt32)initVal; 
{
  // init parent
  [super init];
  // set internals
  type = initType;
  time = getCurrentTimeInSeconds();
  val = initVal;
  //return self
  return self;
}

- (int)eventType
{
  return type;
}
- (double)time
{
  return time;
}
- (uInt32)val
{
  return val;
}
- (void)dealloc
{
  [super dealloc];
}
- (void)doEvent
{
  if (type == DIGOUT_EVENT) {
    int32       written;
    // DAQmxBaseWriteDigitalU8 
    DAQmxBaseWriteDigitalU32(nidaqOutputTaskHandle,1,1,10.0,DAQmx_Val_GroupByChannel,&val,&written,NULL);
    return;
  }
}
// comparison function, used to sort the queue in time order
- (NSComparisonResult)compareByTime:(queueEvent*)otherQueueEvent
{
  if ([self time] > [otherQueueEvent time])  {
    return NSOrderedDescending;
  }
  else if ([self time] == [otherQueueEvent time]) {
    return NSOrderedSame;
  }
  else {
    return NSOrderedAscending;
  }
}
@end

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


/////////////////////////
//   nidaqStartTask   //
/////////////////////////
int nidaqStartTask(int nidaqInputPortNum, int nidaqOutputPortNum)
{
  // Error variables
  int32       error = 0;
  char        errBuff[2048];

  // write variables
  int32       written;
  uInt32 val;

  // Setup the channel parameter
  char inputChannel[256];
  sprintf(inputChannel,"Dev1/port%i",nidaqInputPortNum);
  char outputChannel[256];
  sprintf(outputChannel,"Dev1/port%i",nidaqOutputPortNum);
		   
  // open as a digital input
  DAQmxErrChk (DAQmxBaseCreateTask ("", &nidaqInputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDIChan(nidaqInputTaskHandle,inputChannel,"",DAQmx_Val_ChanForAllLines));
  DAQmxErrChk (DAQmxBaseStartTask (nidaqInputTaskHandle));

  // Create the output task
  DAQmxErrChk (DAQmxBaseCreateTask ("", &nidaqOutputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDOChan(nidaqOutputTaskHandle,outputChannel,"",DAQmx_Val_ChanForAllLines));
   
  // Start Task (configure port)
  DAQmxErrChk (DAQmxBaseStartTask (nidaqOutputTaskHandle));

  
  // return success
  return 1;

 Error:

   if (DAQmxFailed (error))
     DAQmxBaseGetExtendedErrorInfo (errBuff, 2048);

   nidaqStopTask();

   // output error, but only if it is not device idnetifier is invalid
   // since this happens when you simply don't have a card in the
   // computer
   if (error)
     if (error != -200220)
       mexPrintf ("(mglPrivateDigIO) DAQmxBase Error %d: %s\n", error, errBuff);
     else
       mexPrintf ("(mglPrivateDigIO) No device found. DAQmxBase Error %d: %s\n", error, errBuff);
       
   return 0;
}

///////////////////////
//   nidaqStopTask   //
///////////////////////
void nidaqStopTask()
{
  if (nidaqInputTaskHandle != 0) {
    // stop input task
    DAQmxBaseStopTask (nidaqInputTaskHandle);
    DAQmxBaseClearTask(nidaqInputTaskHandle);
    nidaqInputTaskHandle = 0;
  }
  if (nidaqOutputTaskHandle != 0) {
    // stop output task
    DAQmxBaseStopTask (nidaqOutputTaskHandle);
    DAQmxBaseClearTask(nidaqOutputTaskHandle);
    nidaqOutputTaskHandle = 0;
  }
}
#else// __APPLE__
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
#endif// __APPLE__

