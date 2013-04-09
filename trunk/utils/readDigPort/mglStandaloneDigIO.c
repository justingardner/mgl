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

#define DIGIN_COMMAND 2
#define CLOSE_COMMAND 3
#define SHUTDOWN_COMMAND 4
#define ACK_COMMAND 5
#define DIGOUT_COMMAND 6
#define LIST_COMMAND 7

#define DEFAULT_DIGIO_SOCKETNAME ".mglDigIO"
#define BUFSIZE 1024

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
- (void)doEvent:(TaskHandle)nidaqOutputTaskHandle;
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
void digout(NSMutableArray *,int);
void diglist(int,NSMutableArray *,NSMutableArray *);
void digquit(void);
int openSocket(char *socketName, int *, int *);
void processEvent(TaskHandle,NSMutableArray *);
int readSocketCommand(int *, int, NSMutableArray *);
void siginthandler(int);
void senduint8(int, uint8, int);
void senduint32(int, uint32, int);
void sendfloat32(int, float32, int);
void senddouble(int, double, int);
void sendflush(int, int);

////////////////
//   globals  //
////////////////
static uInt8 nidaqInputStatePrevious[1] = {0};
static uInt8 digIOStatus = 0;
static int verbose = 0;
static gRunStatus = 0;
// These are declared as global just so that we can exit gracefully
// if the user hits ctrl-c
static int connectionDescriptor = 0,socketDescriptor = 0;
NSAutoreleasePool *digIOPool = NULL;
NSMutableArray *diginEventQueue = NULL, *digoutEventQueue = NULL;
TaskHandle nidaqInputTaskHandle = 0,nidaqOutputTaskHandle = 0;

//////////////
//   main   //
//////////////
int main(int argc, char *argv[])
{
  // declare variables
  int nidaqInputPortNum = 2;
  int nidaqOutputPortNum = 1;
  char socketName[BUFSIZE];

  // set default socketName
  strncpy(socketName,DEFAULT_DIGIO_SOCKETNAME,BUFSIZE);

  // process input arguments. First one is socket name
  if (argc>=2) sprintf(socketName,"%s",argv[1]);
  if (argc>=3) nidaqInputPortNum = atoi(argv[2]);
  if (argc>=4) nidaqOutputPortNum = atoi(argv[3]);
  if (argc>=5) verbose = atoi(argv[4]);

  // display settings
  if (verbose) printf("(mglStandaloneDigIO) Starting with Input port: %i Ouptut port: %i Verbose: %i socketName: %s\n",nidaqInputPortNum,nidaqOutputPortNum,verbose,socketName);

  // register sigint handler (this will clean up if the user hits ctrl-c)
  signal(SIGINT, siginthandler);

  // open the communication socket, checking for error
  if (openSocket(socketName,&connectionDescriptor,&socketDescriptor) == 0)
    return;
  
  // init digIO
  if (initDigIO(nidaqInputPortNum,nidaqOutputPortNum,&nidaqInputTaskHandle,&nidaqOutputTaskHandle,&diginEventQueue,&digoutEventQueue,&digIOPool) == 0) {
    close(socketDescriptor);
    return;
  }
  digIOStatus = 1;

  // read socket commands, log dig IO events and process events
  int runStatus = 1;
  while (runStatus) {
    // read command
    runStatus = readSocketCommand(&connectionDescriptor,socketDescriptor,diginEventQueue);
    // log any dig IO event there is
    if (gRunStatus) logDigIO(nidaqInputTaskHandle,diginEventQueue);
    // process events
    processEvent(nidaqOutputTaskHandle,digoutEventQueue);
  }
    
  // close socket
  close(socketDescriptor);

  // end digIO
  endDigIO(nidaqInputTaskHandle,nidaqOutputTaskHandle,diginEventQueue,digoutEventQueue,digIOPool);

  // shutdown
  printf("(mglStandaloneDigIO) mglStandaloneDigIO is shutdown\n");

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
    if (verbose) printf("(mglStandaloneDigIO) Socket closed\n");
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
int readSocketCommand(int *connectionDescriptor, int socketDescriptor, NSMutableArray *diginEventQueue)
{
  int readCount;
  static char buf[BUFLEN], *commandName;
  static int displayWaitingForConnection = 1;

  // check for closed connection, if so, try to reopen
  if (*connectionDescriptor == -1) {
    // display that we are waiting for connection (but only once)
    if (displayWaitingForConnection) {
      if (verbose) printf("(mglStandaloneDigIO) Waiting for a new connection\n");
      displayWaitingForConnection = 0;
    }
    // try to make a connection
    if ((*connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
      return;
    }
    else {
      printf("(mglStandaloneDigIO) New connection made: %i\n",(int)*connectionDescriptor);
      displayWaitingForConnection = 1;
    }
  }

  // clear command buffer
  memset(buf,0,BUFLEN);

  // read command
  if ((readCount=recv(*connectionDescriptor,buf,1,0)) > 0) {
    // digin command
    if (buf[0] == DIGIN_COMMAND)
      digin(diginEventQueue,*connectionDescriptor);
    // digout command
    else if (buf[0] == DIGOUT_COMMAND)
      digout(digoutEventQueue,*connectionDescriptor);
    // list command
    else if (buf[0] == LIST_COMMAND)
      diglist(*connectionDescriptor,diginEventQueue,digoutEventQueue);
    // close command
    else if (buf[0] == CLOSE_COMMAND) {
      close(*connectionDescriptor);
      *connectionDescriptor = -1;
      // set status to paused
      gRunStatus = 0;
    }
    // shutdown command
    else if (buf[0] == SHUTDOWN_COMMAND) {
      close(*connectionDescriptor);
      *connectionDescriptor = -1;
      // set status to paused
      gRunStatus = 0;
      return(0);
    }
    // ack command
    else if (buf[0] == ACK_COMMAND) {
      // read any more pending bytes
      //      while (recv(*connectionDescriptor,buf,1,0) > 0) ;
      // send acknowledge byte 
      if (digIOStatus)
	// one if digIO is running
	senduint8(*connectionDescriptor,1,1);
      else
	// two if not running
	senduint8(*connectionDescriptor,2,1);
      // set status to running
      gRunStatus = 1;
    }
    // unknown command
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
  return(1);
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
      [[digoutEventQueue objectAtIndex:0] doEvent:nidaqOutputTaskHandle];
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
- (void)doEvent:(TaskHandle)nidaqOutputTaskHandle
{
  if (type == DIGOUT_EVENT) {
    int32       written;
    // DAQmxBaseWriteDigitalU8 
    DAQmxBaseWriteDigitalU32(nidaqOutputTaskHandle,1,1,10.0,DAQmx_Val_GroupByChannel,&val,&written,NULL);
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
    printf("(mglStandaloneDigIO) Ending mglStandaloneDigIO\n");
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
void digin(NSMutableArray *diginEventQueue,int connectionDescriptor) 
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
      senddouble(connectionDescriptor,[qEvent time],0);
      // flush the output buffer, but only if it is full
      sendflush(connectionDescriptor,0);
      // print message
      if (verbose>1)  printf("(mglStandaloneDigIO:digin) %i: Event type: %i line: %i time: %f\n",count+1,(int)[qEvent eventType],(int)[qEvent val],(float)[qEvent time]);
      // remove it from the queue
      [diginEventQueue removeObjectAtIndex:count];
    }
    // flush the output buffer
    sendflush(connectionDescriptor,1);
  }
  else {
    if (verbose) printf("(mglStandaloneDigIO:digin) No events pending\n");
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

/////////////////////
//    senddouble   //
/////////////////////
void senddouble(int connectionDescriptor, double value, int flush)
{
  // load the send buffer
  *(double*)(sendBuffer+sendBufferLoc) = value;
  sendBufferLoc += sizeof(double);
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
void digout(NSMutableArray *digoutEventQueue,int connectionDescriptor) 
{
  unsigned char buf[16];

  // get time of event
  if (recv(connectionDescriptor,buf,sizeof(double),0) < sizeof(double)){
    printf("(mglStandaloneDigIO) Could not read event time\n");
    return;
  }
  double time = *(double*)buf;
  // get value 
  if (recv(connectionDescriptor,buf,sizeof(uInt32),0) < sizeof(uInt32)){
    printf("(mglStandaloneDigIO) Could not read event value\n");
    return;
  }
  uInt32 val = *(uInt32*)buf;
  if (verbose) printf("(mglStandaloneDigIO) Queing event of %i at time %f\n",(int)val,time);

  // create the event
  digQueueEvent *qEvent = [[digQueueEvent alloc] initWithTypeTimeAndValue:DIGOUT_EVENT :time :val];

  // add the event to the event queue
  [digoutEventQueue addObject:qEvent];
  [qEvent release];

  // sort the event queue by time
  SEL compareByTime = @selector(compareByTime:);
  [digoutEventQueue sortUsingSelector:compareByTime];

}

//////////////////
//    diglist   // 
//////////////////
void diglist(int connectionDescriptor,NSMutableArray *digintEventQueue,NSMutableArray *digoutEventQueue)
{
  // display which ports we are using
  printf("(mglStandaloneDigIO) DigIO standalone is running (connectionDescriptor = %i)\n",connectionDescriptor);
  printf("(mglStandaloneDigIO) Status is %s\n",(gRunStatus) ? "running" : "paused");

  if (nidaqInputTaskHandle != 0) {
    // display events on event queue
    if ([digoutEventQueue count] == 0) {
      printf("(mglStandaloneDigIO) No digout events pending.\n");
    }
    else {
      int i;
      for(i = 0; i < [digoutEventQueue count]; i++) {
	printf("(mglStandaloneDigIO) Set output port to %i is pending in %f seconds.\n",(int)[[digoutEventQueue objectAtIndex:i] val],[[digoutEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds());
      }
    }
    // check input events
    printf("(mglStandaloneDigIO) %i digin events in queue\n",[diginEventQueue count]);
  }
  else
    printf("(mglStandaloneDigIO) NIDAQ card is not initialized.\n");
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

  // make socket non-blocking
  long on = 1L;
  if (fcntl(*socketDescriptor, F_SETFL, O_NONBLOCK) < 0) {
    printf("(mglStandaloneDigIO) Could not set socket to non-blocking. This will not record io events until a connection is made.");
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
  if (verbose) printf("(mglStandaloneDigIO) Opened socket %s\n",socketName);

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


