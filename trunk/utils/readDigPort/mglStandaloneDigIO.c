#ifdef documentation
=========================================================================

       program: mglStandaloneDigIO.c
            by: justin gardner
     copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
          date: 06/30/09
       purpose: Based on the mglPrivateDigIO.c code. This installs a 
                background process that reads and writes a NI digital
                IO device (based on NI-DAQmx Base -- you will need to install
                NI-DAQmx Base to compile and use. I have been using this on
                an NI USB device (NI USB-6501 24-line Digital I/O). See the
                MGL wiki for info on how to install the NI driver and use
                this code. Note that this runs outside of Matlab (as opposed
                to on a thread like mglPrivateDigIO. Matlab communicates
                to this process through a socket. This is so that we can
                run matlab in 64 bit since NI refuses to provide a 64 bit
                library for NI cards
			   
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include <stdio.h>
#include <pthread.h>
#include "/Applications/National Instruments/NI-DAQmx Base/includes/NIDAQmxBase.h"
#include <sys/socket.h>
#include <sys/un.h>
#import <Foundation/Foundation.h>
#include <signal.h>
#include <errno.h>

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__

////////////////////////
//   define section   //
////////////////////////
// NIDAQ error checking macro
#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { goto Error; } }
// event types
#define DIGDOWN_EVENT 0
#define DIGUP_EVENT 1
#define DIGOUT_EVENT 2
#define QUIT_EVENT 3
#define INIT_EVENT 4
#define BUFLEN 256

/////////////////////
//   queue event   //
/////////////////////
@interface digQueueEvent : NSObject {
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
- (NSComparisonResult)compareByTime:(digQueueEvent *)otherQueueEvent;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////
double getCurrentTimeInSeconds();
int initDigIO(int, int, TaskHandle *, TaskHandle *, NSMutableArray **,NSMutableArray **,NSAutoreleasePool **);
int nidaqStartTask(int, int, TaskHandle *, TaskHandle *);
void endDigIO(TaskHandle, TaskHandle, NSMutableArray *,NSMutableArray *,NSAutoreleasePool *);
void nidaqStopTask(TaskHandle, TaskHandle);
void logDigIO(TaskHandle, NSMutableArray *);
void digin(NSMutableArray *,int); 
void digout(void);
void diglist(void);
void digquit(void);
int openSocket(char *socketName, int *, int *);
void processEvent(TaskHandle,NSMutableArray *);
void readSocketCommand(int *, int, NSMutableArray *);
void siginthandler(int);
void senduint8(int, uint8, int);
void senduint32(int, uint32, int);
void sendfloat32(int, float32, int);
void sendflush(int, int);

////////////////
//   globals  //
////////////////
static uInt8 nidaqInputStatePrevious[1] = {0};

// These are declared as global just so that we can exit gracefully
// if the user hits ctrl-c
int connectionDescriptor = 0,socketDescriptor = 0;
NSAutoreleasePool *digIOPool = NULL;
NSMutableArray *diginEventQueue = NULL, *digoutEventQueue = NULL;
TaskHandle nidaqInputTaskHandle = 0,nidaqOutputTaskHandle = 0;

//////////////
//   main   //
//////////////
int main(int argc, char *argv[])
{
  // register sigint handler (this will clean up if the user hits ctrl-c)
  signal(SIGINT, siginthandler);

  // init digIO
  if (initDigIO(1,2,&nidaqInputTaskHandle,&nidaqOutputTaskHandle,&diginEventQueue,&digoutEventQueue,&digIOPool) == 0) return;

  // open the communication socket, checking for error
  if (openSocket(".mglDigIO",&connectionDescriptor,&socketDescriptor) == 0)
    return;
  
  double startTimeInSeconds = getCurrentTimeInSeconds();
  while ((getCurrentTimeInSeconds()-startTimeInSeconds) < 60.0) {
    // read the socket for new commands
    readSocketCommand(&connectionDescriptor,socketDescriptor,diginEventQueue);
    // log any dig IO event there is
    logDigIO(nidaqInputTaskHandle,diginEventQueue);
    // process events
    //    processEvent(nidaqOutputTaskHandle,digoutEventQueue);
  }
    

  // close socket
  close(socketDescriptor);

  // end digIO
  endDigIO(nidaqInputTaskHandle,nidaqOutputTaskHandle,diginEventQueue,digoutEventQueue,digIOPool);
  
  return(0);
}

//////////////////
//    sigint    //
//////////////////
void siginthandler(int param)
{
  // print that the user hit ctrl-c
  printf("(mglStandaloneDigIO) User hit ctrl-c\n");

  // close socket
  if (socketDescriptor) {
    close(socketDescriptor);
    printf("(mglStandaloneDigIO) Socket closed\n");
  }

  // end digIO
  endDigIO(nidaqInputTaskHandle,nidaqOutputTaskHandle,diginEventQueue,digoutEventQueue,digIOPool);

  // exit
  exit(1);
}

///////////////////
//    logDigIO   //
///////////////////
void logDigIO(TaskHandle nidaqInputTaskHandle, NSMutableArray *diginEventQueue)
{
  // read the port once to get current state
  int32       read;
  // if the nidaq input task handle has been initialized, then read the port
  if (nidaqInputTaskHandle != 0) {
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
	    digQueueEvent *qEvent = [[digQueueEvent alloc] initWithTypeAndValue:DIGUP_EVENT :bitnum];
	    [diginEventQueue insertObject:qEvent atIndex:0];
	    [qEvent release];
	  }
	  else {
	    // add a digdown event
	    digQueueEvent *qEvent = [[digQueueEvent alloc] initWithTypeAndValue:DIGDOWN_EVENT :bitnum];
	    [diginEventQueue insertObject:qEvent atIndex:0];
	    [qEvent release];
	  }
	}
      }
      nidaqInputStatePrevious[0] = nidaqInputState[0];
    }
  }
}

/////////////////////////////
//    readSocketCommand    //
/////////////////////////////
void readSocketCommand(int *connectionDescriptor, int socketDescriptor, NSMutableArray *diginEventQueue)
{
  int readCount;
  static char buf[BUFLEN], *commandName;
  static int displayWaitingForConnection = 1;

  // check for closed connection, if so, try to reopen
  if (*connectionDescriptor == -1) {
    // display that we are waiting for connection (but only once)
    if (displayWaitingForConnection) {
      printf("(mglStandaloneDigIO) Waiting for a new connection\n");
      displayWaitingForConnection = 0;
    }
    // try to make a connection
    if ((*connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
      return;
    }
    else {
      printf("(mglStandaloneDigIO) New connection made: %i\n",*connectionDescriptor);
      displayWaitingForConnection = 1;
    }
  }

  // clear command buffer
  memset(buf,0,BUFLEN);

  // read command
  if ((readCount=recv(*connectionDescriptor,buf,BUFLEN,0)) > 0) {
    // pull out command
    commandName = strtok(buf," \n\0");

    //++++++++++++++++++++++++++++++++
    // Open
    //++++++++++++++++++++++++++++++++
    if (strcmp(commandName,"open")==0) {
      printf("(mglStandaloneDigIO) Got open command\n");
    }
    //++++++++++++++++++++++++++++++++
    // digin
    //++++++++++++++++++++++++++++++++
    else if (strcmp(commandName,"digin")==0) {
      digin(diginEventQueue,*connectionDescriptor);
    }
    //++++++++++++++++++++++++++++++++
    // close
    //++++++++++++++++++++++++++++++++
    else if (strcmp(commandName,"close")==0) {
      close(*connectionDescriptor);
      *connectionDescriptor = -1;
    }
    else
      printf("(mglStandaloneDigIO) Unknown command %s\n",commandName);
  }
  else {
    // error on read, assume that connection was closed.
    if (errno != EAGAIN) {
      close(*connectionDescriptor);
      *connectionDescriptor = -1;
    }
  }
}

//////////////////////
//   processEvent   //
//////////////////////
void processEvent(TaskHandle nidaqOutputTaskHandle, NSMutableArray *digoutEventQueue)
{
  double currentTimeInSeconds;

  // get the current time in seconds
  currentTimeInSeconds = getCurrentTimeInSeconds();
  // check for events to process
  if ([digoutEventQueue count] > 0) {
    // see if we need to post the top element on the queue
    if (currentTimeInSeconds > [[digoutEventQueue objectAtIndex:0] time]) {
      // set the port
      [[digoutEventQueue objectAtIndex:0] doEvent];
      // and remove event from the queue
      [digoutEventQueue removeObjectAtIndex:0];
    }
  }
}
 
///////////////////////////////////
//   queue event implementation  //
///////////////////////////////////
@implementation digQueueEvent 
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
    //    DAQmxBaseWriteDigitalU32(nidaqOutputTaskHandle,1,1,10.0,DAQmx_Val_GroupByChannel,&val,&written,NULL);
    printf("Should output event here - get handle needs to be implemented\n");
    // FIX FIX FIX
    return;
  }
}
// comparison function, used to sort the queue in time order
- (NSComparisonResult)compareByTime:(digQueueEvent*)otherQueueEvent
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
int nidaqStartTask(int nidaqInputPortNum, int nidaqOutputPortNum, TaskHandle *nidaqInputTaskHandle, TaskHandle *nidaqOutputTaskHandle)
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
  DAQmxErrChk (DAQmxBaseCreateTask ("", nidaqInputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDIChan(*nidaqInputTaskHandle,inputChannel,"",DAQmx_Val_ChanForAllLines));
  DAQmxErrChk (DAQmxBaseStartTask (*nidaqInputTaskHandle));

  // Create the output task
  DAQmxErrChk (DAQmxBaseCreateTask ("", nidaqOutputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDOChan(*nidaqOutputTaskHandle,outputChannel,"",DAQmx_Val_ChanForAllLines));
  DAQmxErrChk (DAQmxBaseStartTask (*nidaqOutputTaskHandle));
  
  // return success
  return 1;

 Error:

   if (DAQmxFailed (error))
     DAQmxBaseGetExtendedErrorInfo (errBuff, 2048);

   nidaqStopTask(*nidaqInputTaskHandle,*nidaqOutputTaskHandle);

   // output error, but only if it is not device idnetifier is invalid
   // since this happens when you simply don't have a card in the
   // computer
   if (error)
     if (error != -200220)
       printf("(mglStandaloneDigIO) DAQmxBase Error %d: %s\n", (int)error, errBuff);
     else
       printf("(mglStandaloneDigIO) No device found. DAQmxBase Error %d: %s\n", (int)error, errBuff);
       
   return 0;
}

///////////////////////
//   nidaqStopTask   //
///////////////////////
void nidaqStopTask(TaskHandle nidaqInputTaskHandle,TaskHandle nidaqOutputTaskHandle)
{
  if (nidaqInputTaskHandle != 0) {
    printf("(mglStandaloneDigIO) Shutting down input task\n");
    // stop input task
    DAQmxBaseStopTask (nidaqInputTaskHandle);
    DAQmxBaseClearTask(nidaqInputTaskHandle);
  }
  if (nidaqOutputTaskHandle != 0) {
    printf("(mglStandaloneDigIO) Shutting down output task\n");
    // stop output task
    DAQmxBaseStopTask (nidaqOutputTaskHandle);
    DAQmxBaseClearTask(nidaqOutputTaskHandle);
  }
}

////////////////////
//    initDigIO   // 
////////////////////
int initDigIO(int nidaqInputPortNum, int nidaqOutputPortNum, TaskHandle *nidaqInputTaskHandle, TaskHandle *nidaqOutputTaskHandle, NSMutableArray **diginEventQueue, NSMutableArray **digoutEventQueue, NSAutoreleasePool **digIOPool)
{
  // display message
  printf("(mglStandaloneDigIO) Initializing NI device with digin port: Dev1/port%i digout port: Dev1/port%i. End with mglDigIO('quit').\n",nidaqInputPortNum,nidaqOutputPortNum);

  // Attempt to start NIDAQ task
  if (nidaqStartTask(nidaqInputPortNum, nidaqOutputPortNum, nidaqInputTaskHandle, nidaqOutputTaskHandle) == 0) {
    printf("============================================================================\n");
    printf("(mglStandaloneDigIO) UHOH! Could not start NIDAQ ports digin: %i and digout: %i\n",nidaqInputPortNum,nidaqOutputPortNum);
    printf("============================================================================\n");
    return 0;
  }

  // init the auto-release pool
  *digIOPool = [[NSAutoreleasePool alloc] init];
  
  // init the queues
  *diginEventQueue = [[NSMutableArray alloc] init];
  *digoutEventQueue = [[NSMutableArray alloc] init];

  printf("(mglStandaloneDigIO) Successfully initialized NI device\n",nidaqInputPortNum,nidaqOutputPortNum);

  // return ok
  return 1;
}

//////////////////
//   endDigIO   //
//////////////////
void endDigIO(TaskHandle nidaqInputTaskHandle,TaskHandle nidaqOutputTaskHandle,NSMutableArray *diginEventQueue,NSMutableArray *digoutEventQueue,NSAutoreleasePool *digIOPool)
{
  // clear and release digout
  if (digoutEventQueue) {
    [digoutEventQueue removeAllObjects];
    [digoutEventQueue release];
  }
  // clear and release digin
  if (diginEventQueue) {
    [diginEventQueue removeAllObjects];
    [diginEventQueue release];
  }
  // empty pool
  if (digIOPool)
    [digIOPool drain];

  // stop nidaq task
  nidaqStopTask(nidaqInputTaskHandle,nidaqOutputTaskHandle);
}

////////////////
//    digin   // 
////////////////
void digin(NSMutableArray *diginEvengtQueue,int connectionDescriptor) 
{
  // see how many events we have
  unsigned int count = [diginEventQueue count];
  // send how many events to socket
  senduint32(connectionDescriptor,count,1);
  // if we have more than one, send the info about the events
  // across the socket
  if (count > 0) {
    while (count--) {
      digQueueEvent *qEvent;
      // get the last event
      qEvent = [diginEventQueue objectAtIndex:count];
      // send its eventType (up or down), line number and event time
      senduint8(connectionDescriptor,(uint8)[qEvent eventType],0);
      senduint8(connectionDescriptor,(uint8)[qEvent val],0);
      sendfloat32(connectionDescriptor,(float32)[qEvent time],0);
      // flush the output buffer, but only if it is full
      sendflush(connectionDescriptor,0);
      // printm message
      printf("(mglStandaloneDigIO:digin) %i: Event type: %i line: %i time: %f\n",count+1,(int)[qEvent eventType],(int)[qEvent val],(float)[qEvent time]);
      // remove it from the queue
      [diginEventQueue removeObjectAtIndex:count];
    }
    // flush the output buffer
    sendflush(connectionDescriptor,1);
  }
  else {
    printf("(mglStandaloneDigIO:digin) No events pending\n");
  }
} 

////////////////////////////////
//    send buffer variables   //
////////////////////////////////
#define SENDBUFSIZE (8192)
#define SENDBUFTHRESHOLD (SENDBUFSIZE-16)
unsigned char sendBuffer[SENDBUFSIZE];
unsigned int sendBufferLoc = 0;

////////////////////
//    senduint8   // 
////////////////////
void senduint8(int connectionDescriptor, uint8 value, int flush)
{
  // load the send buffer
  sendBuffer[sendBufferLoc++] = (unsigned char)value;
  // flush it if called for
  if (flush) sendflush(connectionDescriptor,1);
}

/////////////////////
//    senduint32   // 
/////////////////////
void senduint32(int connectionDescriptor, uint32 value, int flush)
{
  // load the send buffer
  *(uint32*)(sendBuffer+sendBufferLoc) = value;
  sendBufferLoc += sizeof(uint32);
  // flush it if called for
  if (flush) sendflush(connectionDescriptor,1);
}

//////////////////////
//    sendfloat32   //
//////////////////////
void sendfloat32(int connectionDescriptor, float32 value, int flush)
{
  // load the send buffer
  *(float32*)(sendBuffer+sendBufferLoc) = value;
  sendBufferLoc += sizeof(float32);
  // flush it if called for
  if (flush) sendflush(connectionDescriptor,1);
}

////////////////////
//    sendflush   //
////////////////////
void sendflush(int connectionDescriptor,int force)
{
  int sentSize;
  if (sendBufferLoc && (force || (sendBufferLoc > SENDBUFTHRESHOLD))) {
    // send the buffer
    if ((sentSize = write(connectionDescriptor,sendBuffer,sendBufferLoc)) < sendBufferLoc)
      printf("(mglStgandaloneDigIO) ERROR Only sent %i of %i bytes across socket to matlab - data might be corrupted\n",sentSize,sendBufferLoc);
    // clear send buffer
    sendBufferLoc = 0;
  }
}

/////////////////
//    digout   // 
/////////////////
void digout(void)
{
#if 0
  // get value and time
  double time = (double)mxGetScalar(prhs[1]);
  uInt32 val = (uInt32)(double)mxGetScalar(prhs[2]);

  // lock the mutex to avoid concurrent access to the global variables
  pthread_mutex_lock(&digioMutex);

  // create the event
  digQueueEvent *qEvent = [[digQueueEvent alloc] initWithTypeTimeAndValue:DIGOUT_EVENT :time :val];

  // add the event to the event queue
  [gDigoutEventQueue addObject:qEvent];
  [qEvent release];

  // sort the event queue by time
  SEL compareByTime = @selector(compareByTime:);
  [gDigoutEventQueue sortUsingSelector:compareByTime];

  // release mutex
  pthread_mutex_unlock(&digioMutex);
  // return 1
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(plhs[0]) = 1;
#endif
}

//////////////////
//    diglist   // 
//////////////////
void diglist(void)
{
#if 0
  // lock the mutex to avoid concurrent access to the global variables
  pthread_mutex_lock(&digioMutex);
  // display which ports we are using
  printf("(mglStandaloneDigIO) DigIO thread is running\n");
  if (nidaqInputTaskHandle != 0) {
    // see if nidaq card is running
    printf("(mglPrivtateDigIO) Input port is: Dev1/port%i. Output port is: Dev1/port%i\n",nidaqInputPortNum,nidaqOutputPortNum);
    if ([gDigoutEventQueue count] == 0) {
      printf("(mglStandaloneDigIO) No digiout events pending.\n");
    }
    else {
      int i;
      for(i = 0; i < [gDigoutEventQueue count]; i++) {
	printf("(mglStandaloneDigIO) Set output port to %i is pending in %f seconds.\n",[[gDigoutEventQueue objectAtIndex:i] val],[[gDigoutEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds());
      }
    }
    // check input events
    printf("(mglStandaloneDigIO) %i digin events in queue\n",[gDiginEventQueue count]);
  }
  else
    printf("(mglStandaloneDigIO) NIDAQ card is not initialized.\n");
  // release mutex
  pthread_mutex_unlock(&digioMutex);
  // return 1
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(plhs[0]) = 1;
#endif
}

//////////////////
//    digquit   // 
//////////////////
void digquit(void)
{
#if 0
  // lock the mutex to avoid concurrent access to the global variables
  pthread_mutex_lock(&digioMutex);
    
  // add a quit event
  digQueueEvent *qEvent = [[digQueueEvent alloc] initWithType:QUIT_EVENT];
  [gDigoutEventQueue insertObject:qEvent atIndex:0];
  [qEvent release];

  // release mutex
  pthread_mutex_unlock(&digioMutex);
#endif
}

//////////////////////
//    openSocket    //
//////////////////////
int openSocket(char *socketName, int *connectionDescriptor, int *socketDescriptor)
{
  struct sockaddr_un socketAddress;

  // create socket and check for error
  if ((*socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    perror("(mglStandaloneDigIO) Could not create socket to communicate between matlab and mglStandaloneDigIO");
    return 0;
  }

  // set up socket address
  memset(&socketAddress, 0, sizeof(socketAddress));
  socketAddress.sun_family = AF_UNIX;
  strncpy(socketAddress.sun_path, socketName, sizeof(socketAddress.sun_path)-1);

  // unlink (make sure that it doesn't already exist)
  unlink(socketName);

  // bind the socket to the address, this could fail if you don't have
  // write permission to the directory where the socket is being made
  if (bind(*socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
    printf("(mglStandaloneDigIO) Could not bind socket to name %s. This prevents communication between matlab and mglStandaloneDigIO. This might have happened because you do not have permission to write the file %s",socketName,socketName);
    perror(NULL);
    close(*socketDescriptor);
    return 0;
  }

  // listen to the socket (accept up to 500 connects)
  if (listen(*socketDescriptor, 500) == -1) {
    printf("(mglStandaloneDigIO) Could not listen to socket %s, which is used to communicate between matlab and mglStandaloneDigIO.",socketName);
    perror(NULL);
    close(*socketDescriptor);
    return 0;
  }
  printf("(mglStandaloneDigIO) Opened socket %s\n",socketName);

  // check for a connection
  printf("(mglStandaloneDigIO) Waiting for connection on %s\n",socketName);
  if ( (*connectionDescriptor = accept(*socketDescriptor, NULL, NULL)) == -1) {
     perror("(mglMovieStandAlone) Error accepting a connection on socket. This prevents communication between matlab and mglMovieStandAlone");
     return 0;
    }
  printf("(mglStandaloneDigIO) Connection on %s accepted\n",socketName);

  // make socket non-blocking
  long on = 1L;
  if (fcntl(*socketDescriptor, F_SETFL, O_NONBLOCK) < 0) {
    printf("(mglStandaloneDigIO) Could not set socket to non-blocking. This will not record io events until a connection is made.");
  }

  return 1;
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


