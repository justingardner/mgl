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
#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <math.h>
#include <time.h>
#include <unistd.h>

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
#define AO_INIT_EVENT 5
#define AO_START_EVENT 6
#define AO_END_EVENT 7
#define BUFLEN 256

#define DIGIN_COMMAND 2
#define CLOSE_COMMAND 3
#define SHUTDOWN_COMMAND 4
#define ACK_COMMAND 5
#define DIGOUT_COMMAND 6
#define LIST_COMMAND 7
#define AO_FREQOUT_COMMAND 8

#define DEFAULT_DIGIO_SOCKETNAME ".mglDigIO"
#define BUFSIZE 1024

// Number of analog outputs (board this was built to support NI USB-6211 has two analog outputs)
// Change this if you need to support more analog outputs
#define NUMAO 2

#define PI	3.1415926535

/////////////////////
//   queue event   //
/////////////////////
@interface queueEvent : NSObject {
  int type;
  double time;
  uInt32 val;
  // the following are specific for ao events
  uInt32 numChannels;
  uInt32 devnum;
  uInt32 *channelNum;
  double *freq;
  double *amplitude;
  uInt32 sampleRate;
  TaskHandle nidaqTaskHandle;
}
- (id)initWithTypeTimeAndValue:(int)initType :(double)initTime :(uInt32)initVal;
- (id)initWithTypeAndValue:(int)initType :(uInt32)initVal;
- (id)initWithType:(int)initType;
- (id)initAO:(double)initTime :(uInt32)initDev :(uInt32)initNumChannels :(uInt32*)initChannelNum :(double*)initFreq :(double*)initAmplitude :(uInt32)initSampleRate; 
- (id)startAO:(double)startTime :(TaskHandle)taskToStart; 
- (id)endAO:(double)endTime :(TaskHandle)taskToEnd :(uInt32)initDevnum :(uInt32)initNumChannels :(uInt32*)initChannelNum; 
- (double)time;
- (uInt32)val;
- (TaskHandle)nidaqTaskHandle;
- (int)eventType;
- (void)doEvent:(TaskHandle)nidaqOutputTaskHandle;
- (NSComparisonResult)compareByTime:(queueEvent *)otherQueueEvent;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////
double getCurrentTimeInSeconds();
int ao(NSMutableArray *,int);
TaskHandle createAO(uInt32 devnum, uInt32 numChannels, uInt32 *channelNum, double *amplitude);
TaskHandle initAO(TaskHandle nidaqTaskHandle, uInt32 numChannels, double *freq, double *amplitude, uInt32 sampleRate);
void startAO(TaskHandle nidaqTaskHandle);
void endAO(TaskHandle nidaqTaskHandle, uInt32 devnum, uInt32 numChannels, uInt32 *channelNum);
int initDigIO(int, int, int, int, TaskHandle *, TaskHandle *, NSMutableArray **,NSMutableArray **,NSAutoreleasePool **);
int nidaqStartTask(int, int, int, int, TaskHandle *, TaskHandle *);
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
static int gRunStatus = 0;
// These are declared as global just so that we can exit gracefully
// if the user hits ctrl-c
static int connectionDescriptor = 0,socketDescriptor = 0;
NSAutoreleasePool *digIOPool = NULL;
NSMutableArray *diginEventQueue = NULL, *outEventQueue = NULL;
TaskHandle nidaqInputTaskHandle = 0,nidaqOutputTaskHandle = 0;
static double lastAOEndTime = 0;
//////////////
//   main   //
//////////////
int main(int argc, char *argv[])
{
  // declare variables
  int nidaqInputPortNum = 2;
  int nidaqOutputPortNum = 1;
  int inputDevnum = 1;
  int outputDevnum = 1;
  char socketName[BUFSIZE];

  // set default socketName
  strncpy(socketName,DEFAULT_DIGIO_SOCKETNAME,BUFSIZE);

  // process input arguments. First one is socket name
  if (argc>=2) sprintf(socketName,"%s",argv[1]);
  if (argc>=3) nidaqInputPortNum = atoi(argv[2]);
  if (argc>=4) nidaqOutputPortNum = atoi(argv[3]);
  if (argc>=4) inputDevnum = atoi(argv[4]);
  if (argc>=5) outputDevnum = atoi(argv[5]);
  if (argc>=6) verbose = atoi(argv[6]);

  // display settings
  if (verbose) printf("(mglStandaloneDigIO) Starting with Input port: %i Ouptut port: %i Verbose: %i socketName: %s\n",nidaqInputPortNum,nidaqOutputPortNum,verbose,socketName);

  // register sigint handler (this will clean up if the user hits ctrl-c)
  signal(SIGINT, siginthandler);

  // open the communication socket, checking for error
  if (openSocket(socketName,&connectionDescriptor,&socketDescriptor) == 0)
    return(0);
  
  // init digIO
  if (initDigIO(nidaqInputPortNum,nidaqOutputPortNum,inputDevnum,outputDevnum,&nidaqInputTaskHandle,&nidaqOutputTaskHandle,&diginEventQueue,&outEventQueue,&digIOPool) == 0) {
    close(socketDescriptor);
    return(0);
  }
  digIOStatus = 1;

  // read socket commands, log dig IO events and process events
  // this is the main body of this function. The events are kept 
  // on a queue so that they can be timed as precisely as possible
  // That is, for output events (digitial or analog), they are placed
  // on a queue and the code here checks to see if it is time to 
  // act on them - like for example, if you ask to change the digout
  // at a particular time, this code will run that when the time comes
  // and the event is ready to be processed. Likewise, every loop
  // here digin events are stored on another queue. When matlab
  // asks for digital IO events this code pulls those events of that
  // queue and sends them back to matlab
  int runStatus = 1;
  while (runStatus) {
    // read command
    runStatus = readSocketCommand(&connectionDescriptor,socketDescriptor,diginEventQueue);
    // log any dig IO event there is
    if (gRunStatus) logDigIO(nidaqInputTaskHandle,diginEventQueue);
    // process events
    processEvent(nidaqOutputTaskHandle,outEventQueue);
  }
    
  // close socket
  close(socketDescriptor);

  // end digIO
  endDigIO(nidaqInputTaskHandle,nidaqOutputTaskHandle,diginEventQueue,outEventQueue,digIOPool);

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
  endDigIO(nidaqInputTaskHandle,nidaqOutputTaskHandle,diginEventQueue,outEventQueue,digIOPool);

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
	    queueEvent *qEvent = [[queueEvent alloc] initWithTypeAndValue:DIGUP_EVENT :bitnum];
	    [diginEventQueue insertObject:qEvent atIndex:0];
	    [qEvent release];
	  }
	  else {
	    // add a digdown event
	    queueEvent *qEvent = [[queueEvent alloc] initWithTypeAndValue:DIGDOWN_EVENT :bitnum];
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
      return(-1);
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
      digout(outEventQueue,*connectionDescriptor);
    // list command
    else if (buf[0] == LIST_COMMAND)
      diglist(*connectionDescriptor,diginEventQueue,outEventQueue);
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
    else if (buf[0] == AO_FREQOUT_COMMAND) {
      ao(outEventQueue,*connectionDescriptor);
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
void processEvent(TaskHandle nidaqOutputTaskHandle, NSMutableArray *outEventQueue)
{
  double currentTimeInSeconds;

  // get the current time in seconds
  currentTimeInSeconds = getCurrentTimeInSeconds();
  // check for events to process
  if ([outEventQueue count] > 0) {
    // see if we need to post the top element on the queue
    if (currentTimeInSeconds > [[outEventQueue objectAtIndex:0] time]) {
      // set the port
      [[outEventQueue objectAtIndex:0] doEvent:nidaqOutputTaskHandle];
      // and remove event from the queue
      [outEventQueue removeObjectAtIndex:0];
    }
  }
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
- (id)initAO:(double)initTime :(uInt32)initDevnum :(uInt32)initNumChannels :(uInt32*)initChannelNum :(double*)initFreq :(double*)initAmplitude :(uInt32)initSampleRate; 
{
  // init parent
  [super init];
  // set internals
  type = AO_INIT_EVENT;
  devnum = initDevnum;
  numChannels = initNumChannels;
  channelNum = initChannelNum;
  time = initTime;
  freq = initFreq;
  amplitude = initAmplitude;
  sampleRate = initSampleRate;
  nidaqTaskHandle = createAO(devnum,numChannels,channelNum,amplitude);
  //return self
  return self;
}
- (id)startAO:(double)startTime :(TaskHandle)taskToStart; 
{
  // init parent
  [super init];
  // set internals
  type = AO_START_EVENT;
  time = startTime;
  nidaqTaskHandle = taskToStart;
  //return self
  return self;
}
- (id)endAO:(double)endTime :(TaskHandle)taskToEnd :(uInt32)initDevnum :(uInt32)initNumChannels :(uInt32*)initChannelNum; 
{
  // init parent
  [super init];
  // set internals
  type = AO_END_EVENT;
  time = endTime;
  devnum = initDevnum;
  numChannels = initNumChannels;
  channelNum = initChannelNum;
  nidaqTaskHandle = taskToEnd;
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
- (TaskHandle)nidaqTaskHandle
{
  return nidaqTaskHandle;
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
  else if (type == AO_INIT_EVENT)
    initAO(nidaqTaskHandle,numChannels,freq,amplitude,sampleRate);
  else if (type == AO_START_EVENT)
    startAO(nidaqTaskHandle);
  else if (type == AO_END_EVENT) 
    endAO(nidaqTaskHandle,devnum,numChannels,channelNum);

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
}

/////////////////////////
//   nidaqStartTask   //
/////////////////////////
int nidaqStartTask(int nidaqInputPortNum, int nidaqOutputPortNum, int inputDevnum, int outputDevnum, TaskHandle *nidaqInputTaskHandle, TaskHandle *nidaqOutputTaskHandle)
{
  // Error variables
  int32       error = 0;
  char        errBuff[2048];

  // write variables
  int32       written;
  uInt32 val;

  // Setup the channel parameter
  char inputChannel[256];
  sprintf(inputChannel,"Dev%i/port%i",inputDevnum,nidaqInputPortNum);
  char outputChannel[256];
  sprintf(outputChannel,"Dev%i/port%i",outputDevnum,nidaqOutputPortNum);

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
   if (error) {
     if (error != -200220) 
       printf("(mglStandaloneDigIO) DAQmxBase Error %d: %s\n", (int)error, errBuff);
     else
       printf("(mglStandaloneDigIO) No device found. DAQmxBase Error %d: %s\n", (int)error, errBuff);
   }
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

//////////////
//    ao    // 
//////////////
int ao(NSMutableArray *outEventQueue,int connectionDescriptor)
{
  // THis is the function that gets called when an ao request comes in.
  // It reads the parameters and the creates events to init, start and end
  // the analog output

  int i;

  // buffer for reading
  unsigned char buf[16];

  // get number of channels
  if (recv(connectionDescriptor,buf,sizeof(uInt32),0) < sizeof(uInt32)){
    printf("(mglStandaloneDigIO) Could not read event time\n");
    return 0;
  }
  uInt32 numChannels = *(uInt32*)buf;

  // get time of event, this can be an array since we support multiple channels
  // though, note that the eventTime parameter does not actually do anything
  // differently for different channels as of now.
  double *eventTime;
  // this malloc is freed below
  eventTime = (double*)malloc(numChannels*sizeof(double));
  for (i=0;i<numChannels;i++) {
    if (recv(connectionDescriptor,buf,sizeof(double),0) < sizeof(double)){
      printf("(mglStandaloneDigIO) Could not read event time\n");
      return 0;
    }
    eventTime[i] = *(double*)buf;
  }

  // get channelNum
  uInt32 *channelNum;
  // this malloc is freed in endAO
  channelNum = (uInt32*)malloc(numChannels*sizeof(uInt32));
  for (i=0;i<numChannels;i++) {
    if (recv(connectionDescriptor,buf,sizeof(uInt32),0) < sizeof(uInt32)){
      printf("(mglStandaloneDigIO) Could not read channelNum\n");
      return 0;
    }
    channelNum[i] = *(uInt32*)buf;
  }

  // get frequency
  double *freq;
  // this malloc is freed in initAO
  freq = (double*)malloc(numChannels*sizeof(double));
  for (i=0;i<numChannels;i++) {
    if (recv(connectionDescriptor,buf,sizeof(double),0) < sizeof(double)){
      printf("(mglStandaloneDigIO) Could not read frequency\n");
      return 0;
    }
    freq[i] = *(double*)buf;
  }

  // get amplitude
  double *amplitude;
  // this malloc is freed in initAO
  amplitude = (double*)malloc(numChannels*sizeof(double));
  for (i=0;i<numChannels;i++) {
    if (recv(connectionDescriptor,buf,sizeof(double),0) < sizeof(double)){
      printf("(mglStandaloneDigIO) Could not read amplitude\n");
      return 0;
    }
    amplitude[i] = *(double*)buf;
  }

  // get duration
  double *duration;
  // this malloc is freed below
  duration = (double*)malloc(numChannels*sizeof(double));
  for (i=0;i<numChannels;i++) {
    if (recv(connectionDescriptor,buf,sizeof(double),0) < sizeof(double)){
      printf("(mglStandaloneDigIO) Could not read duration\n");
      return 0;
    }
    duration[i] = *(double*)buf;
  }

  // get sampleRate
  if (recv(connectionDescriptor,buf,sizeof(uInt32),0) < sizeof(uInt32)){
    printf("(mglStandaloneDigIO) Could not read sampleRate\n");
    return 0;
  }
  uInt32 sampleRate = *(uInt32*)buf;

  // get device number
  if (recv(connectionDescriptor,buf,sizeof(uInt32),0) < sizeof(uInt32)){
    printf("(mglStandaloneDigIO) Could not read devnum\n");
    return 0;
  }
  uInt32 devnum = *(uInt32*)buf;

  // although we passed in an array for eventTime and duration, we cannot
  // actually set different dureations and start times for the NI-DAQ
  // call, so we discard that here - in the future, if we figure out how
  // to do it correctly, can build that functionality from here
  double thisEventTime = *eventTime;free(eventTime);
  double thisDuration = *duration;free(duration);

  // ok, now we have all the parameters for setting up the ao event, display them
  for (i=0;i<numChannels;i++) 
    if (verbose>1) printf("(mglStandaloneDigIO) Setting up frequency output at time: %f dev%lu/an%lu freq: %f amplitude: %f duration: %f (sampleRate: %lu)\n",thisEventTime,devnum,channelNum[i],freq[i],amplitude[i],thisDuration,sampleRate);

  // the init event HAS to start AFTER the last ao event has ended (this is some strageness in the
  // NI-DAQmx Library - I would have thought that you could create a Task on one AO channel independent
  // of another, but so far I have not gotten this to work. Instead, once you have loaded the data to
  // output for one channel, you can't load any new data until that task has ended. So here we init
  // new Tasks (that is, load the sine waveform) only after the last analog output event has ended
  // the timing of the last event is kept in a global variable. We assume that it takes about
  // 25 ms to init events (that's what I was getting on my Mac Pro. So we make sure that we
  // have 25 ms to create the event before running - that is the epsilonTime variable here).
  double epsilonTime = 0.025;
  if (lastAOEndTime == 0) lastAOEndTime = getCurrentTimeInSeconds();
  if (thisEventTime < (lastAOEndTime + epsilonTime)) {
    printf("(mglStandaloneDigIO) !!! AO events -even if they are on different channels- need to happen consecutively. You need to specify an AO event time at least %f ms after the last one for this function to work. Ignoring this AO event request !!!\n",epsilonTime*1000);
    return 0;
  }

  // create the init, start and end events
  queueEvent *qInitEvent = [[queueEvent alloc] initAO:lastAOEndTime+0.001 :devnum :numChannels :channelNum :freq :amplitude :sampleRate];
  queueEvent *qStartEvent = [[queueEvent alloc] startAO:thisEventTime :[qInitEvent nidaqTaskHandle]];
  queueEvent *qEndEvent = [[queueEvent alloc] endAO:thisEventTime+thisDuration :[qInitEvent nidaqTaskHandle] :devnum :numChannels :channelNum];

  // remember the end time of these event as the last one
  lastAOEndTime = thisEventTime+thisDuration;

  // add the events to the event queue
  [outEventQueue addObject:qInitEvent];
  [outEventQueue addObject:qStartEvent];
  [outEventQueue addObject:qEndEvent];

  // sort the event queue by time
  SEL compareByTime = @selector(compareByTime:);
  [outEventQueue sortUsingSelector:compareByTime];

  // release the events
  [qInitEvent release];
  [qStartEvent release];
  [qEndEvent release];

  return 1;
}

///////////////////
//   createAO    //
///////////////////
TaskHandle createAO(uInt32 devnum, uInt32 numChannels, uInt32 *channelNum,double *amplitude)
{
  // Error handling
  int32       error = 0;
  char        errBuff[2048]={'\0'};

  // task handle
  TaskHandle nidaqTaskHandle;

  // Channel parameters
  char        chanName[256];
  int i;
  float64     maxVoltage = (float64)amplitude[0];
  for (i=0;i<numChannels;i++)
    if (maxVoltage < amplitude[i]) 
      maxVoltage = (float64)amplitude[i];

  // create channel name
  for(i=0;i<numChannels;i++) {
    if (i==0)
      sprintf(chanName,"Dev%lu/ao%lu",devnum,channelNum[i]);
    else
      sprintf(chanName,"%s,Dev%lu/ao%lu",chanName,devnum,channelNum[i]);
  }
  if (verbose>1) printf("(mglStandaloneDigIO) Creating %lu channels: %s with maxVoltage: %f\n",numChannels,chanName,maxVoltage);

  // create analog output task
  DAQmxErrChk (DAQmxBaseCreateTask("",&nidaqTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateAOVoltageChan(nidaqTaskHandle,chanName,"",-maxVoltage,maxVoltage,DAQmx_Val_Volts,NULL));

  return(nidaqTaskHandle);

Error:
  if( DAQmxFailed(error) )
    DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
  if( nidaqTaskHandle!=0 ) {
    DAQmxBaseStopTask(nidaqTaskHandle);
    DAQmxBaseClearTask(nidaqTaskHandle);
  }
  if( DAQmxFailed(error) )
    printf ("DAQmxBase Error %ld: %s\n", error, errBuff);
  return NULL;
}

/////////////////
//   initAO    //
/////////////////
TaskHandle initAO(TaskHandle nidaqTaskHandle, uInt32 numChannels, double *freq, double *amplitude, uInt32 sampleRate)
{
  double startTime = getCurrentTimeInSeconds();

  // Error handling
  int32       error = 0;
  char        errBuff[2048]={'\0'};
  int i,iChannel;
  // we can only handle one frequency for the time being - since we have to compute a buffer
  // which contains one cycle of the correct sine wave - and if we have different frequencies
  // that buffer will be need to be different lengths, so just ignore all but the first value here
  double thisFreq = *freq;
  free(freq);

  // Calculate buffer size
  uInt64 bufferSize = (uInt64)((double)sampleRate/thisFreq);
  // the upper end cutoff here is just arbitrary - can be expanded, but this seemed realistically large.
  if ((bufferSize < 1) || (bufferSize > 10000000)) {
    printf("(mglStandaloneDigIO) Required bufferSize for freq %f and sampleRate %lu is out of range: %llu\n",thisFreq,sampleRate,bufferSize);
    free(amplitude);
    return NULL;
  }
  if (verbose>1) printf("(mglStandaloneDigIO) bufferSize: %llu\n",bufferSize);

  // Data write parameters
  float64     data[bufferSize*numChannels];
  int32       pointsWritten;
  // load buffer with one cycle of a sine wave
  for(i=0;i<bufferSize;i++)
    for(iChannel=0;iChannel<numChannels;iChannel++) 
      data[i+(iChannel*bufferSize)] = amplitude[iChannel]*sin((double)i*2.0*PI/(double)bufferSize);
  free(amplitude);
  
  // set up timing for continuous repeating of this sine wave
  DAQmxErrChk (DAQmxBaseCfgSampClkTiming(nidaqTaskHandle,"",(double)sampleRate,DAQmx_Val_Rising,DAQmx_Val_ContSamps,bufferSize));

  // load data (timeout specifies how long to allow this to take in seconds)
  float64 timeout = 0.1;
  DAQmxErrChk (DAQmxBaseWriteAnalogF64(nidaqTaskHandle,bufferSize,0,timeout,DAQmx_Val_GroupByChannel,data,&pointsWritten,NULL));

  // check that we wrote all the data
  if (pointsWritten != (int32)bufferSize) {
    printf("(mglStandaloneDigIO) Could not write analog output buffer of size %llu in %f seconds (%ld was transferred)\n",bufferSize,timeout,pointsWritten);
    return NULL;
  }
  
  if (verbose>1) printf("(mglStandaloneDigIO) Creating analog output task took: %f ms\n",1000*(getCurrentTimeInSeconds()-startTime));
  
  return nidaqTaskHandle;

Error:
  if( DAQmxFailed(error) )
    DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
  if( nidaqTaskHandle!=0 ) {
    DAQmxBaseStopTask(nidaqTaskHandle);
    DAQmxBaseClearTask(nidaqTaskHandle);
  }
  if( DAQmxFailed(error) )
    printf ("DAQmxBase Error %ld: %s\n", error, errBuff);
  return NULL;
}

////////////////////
//    startAO     // 
////////////////////
void startAO(TaskHandle nidaqTaskHandle)
{
  // no handle, no nothing to do
  if (nidaqTaskHandle == NULL) return;

  // Error handling
  int32       error = 0;
  char        errBuff[2048]={'\0'};

  if (verbose>1) printf("(mglStandaloneDigIO) Start AO\n");
  
  // start the task
  DAQmxErrChk (DAQmxBaseStartTask(nidaqTaskHandle));
  return;

Error:
  if( DAQmxFailed(error) )
    DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
  if( nidaqTaskHandle!=0 ) {
    DAQmxBaseStopTask(nidaqTaskHandle);
    DAQmxBaseClearTask(nidaqTaskHandle);
  }
  if( DAQmxFailed(error) )
    printf ("DAQmxBase Error %ld: %s\n", error, errBuff);
  return;
}

//////////////////
//    endAO     // 
//////////////////
void endAO(TaskHandle nidaqTaskHandle,uInt32 devnum, uInt32 numChannels, uInt32 *channelNum)
{
  // no handle, no nothing to do
  if (nidaqTaskHandle == NULL) return;

  // Error handling
  int32       error = 0;
  char        errBuff[2048]={'\0'};

  if (verbose>1) printf("(mglStandaloneDigIO) End AO\n");

  // create channel name
  char        chanName[256];
  int i;
  for(i=0;i<numChannels;i++) {
    if (i==0)
      sprintf(chanName,"Dev%lu/ao%lu",devnum,channelNum[i]);
    else
      sprintf(chanName,"%s,Dev%lu/ao%lu",chanName,devnum,channelNum[i]);
  }
  free(channelNum);

  // stop task
  float64     data = 0.0;
  int32 pointsWritten;

  // shutdown task
  DAQmxErrChk (DAQmxBaseStopTask(nidaqTaskHandle));
  DAQmxErrChk (DAQmxBaseClearTask(nidaqTaskHandle));

  // Now set the voltage to 0
  DAQmxErrChk (DAQmxBaseCreateTask("",&nidaqTaskHandle));

  DAQmxErrChk (DAQmxBaseCreateAOVoltageChan(nidaqTaskHandle,chanName,"",-5,5,DAQmx_Val_Volts,NULL));
  DAQmxErrChk (DAQmxBaseStartTask(nidaqTaskHandle));
  DAQmxErrChk (DAQmxBaseWriteAnalogF64(nidaqTaskHandle,1,0,0.1,DAQmx_Val_GroupByChannel,&data,&pointsWritten,NULL));
  DAQmxErrChk (DAQmxBaseStopTask(nidaqTaskHandle));
  DAQmxErrChk (DAQmxBaseClearTask(nidaqTaskHandle));

  if (verbose>1) printf("(mglStandaloneDigIO) Stopped\n");
  return;

Error:
  if( DAQmxFailed(error) )
    DAQmxBaseGetExtendedErrorInfo(errBuff,2048);
  if( nidaqTaskHandle!=0 ) {
    DAQmxBaseStopTask(nidaqTaskHandle);
    DAQmxBaseClearTask(nidaqTaskHandle);
  }
  if( DAQmxFailed(error) )
    printf ("DAQmxBase Error %ld: %s\n", error, errBuff);
  return;
}

////////////////////
//    initDigIO   // 
////////////////////
int initDigIO(int nidaqInputPortNum, int nidaqOutputPortNum, int inputDevnum, int outputDevnum, TaskHandle *nidaqInputTaskHandle, TaskHandle *nidaqOutputTaskHandle, NSMutableArray **diginEventQueue, NSMutableArray **outEventQueue, NSAutoreleasePool **digIOPool)
{
  // display message
  printf("(mglStandaloneDigIO) Initializing NI device with digin port: Dev%i/port%i digout port: Dev%i/port%i. End with mglDigIO('quit').\n",inputDevnum,nidaqInputPortNum,outputDevnum,nidaqOutputPortNum);

  // Attempt to start NIDAQ task
  if (nidaqStartTask(nidaqInputPortNum, nidaqOutputPortNum, inputDevnum, outputDevnum, nidaqInputTaskHandle, nidaqOutputTaskHandle) == 0) {
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
  *outEventQueue = [[NSMutableArray alloc] init];

  printf("(mglStandaloneDigIO) Successfully initialized NI device (Input port: %i Output port: %i)\n",nidaqInputPortNum,nidaqOutputPortNum);

  // return ok
  return 1;
}

//////////////////
//   endDigIO   //
//////////////////
void endDigIO(TaskHandle nidaqInputTaskHandle,TaskHandle nidaqOutputTaskHandle,NSMutableArray *diginEventQueue,NSMutableArray *outEventQueue,NSAutoreleasePool *digIOPool)
{
  // clear and release digout
  if (outEventQueue) {
    [outEventQueue removeAllObjects];
    [outEventQueue release];
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
      queueEvent *qEvent;
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
    //if (verbose) printf("(mglStandaloneDigIO:digin) No events pending\n");
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
void digout(NSMutableArray *outEventQueue,int connectionDescriptor) 
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
  queueEvent *qEvent = [[queueEvent alloc] initWithTypeTimeAndValue:DIGOUT_EVENT :time :val];

  // add the event to the event queue
  [outEventQueue addObject:qEvent];
  [qEvent release];

  // sort the event queue by time
  SEL compareByTime = @selector(compareByTime:);
  [outEventQueue sortUsingSelector:compareByTime];

}

//////////////////
//    diglist   // 
//////////////////
void diglist(int connectionDescriptor,NSMutableArray *digintEventQueue,NSMutableArray *outEventQueue)
{
  int eventType,i;

  // display which ports we are using
  printf("(mglStandaloneDigIO) DigIO standalone is running (connectionDescriptor = %i)\n",connectionDescriptor);
  printf("(mglStandaloneDigIO) Status is %s\n",(gRunStatus) ? "running" : "paused");

  if (nidaqInputTaskHandle != 0) {
    // display events on event queue
    if ([outEventQueue count] == 0) {
      printf("(mglStandaloneDigIO) No digout events pending.\n");
    }
    else {
      for(i = 0; i < [outEventQueue count]; i++) {
	// get evenType
	eventType = (int)[[outEventQueue objectAtIndex:i] eventType];
	// check for DIGOUT events
	if (eventType==DIGOUT_EVENT)
	  printf("(mglStandaloneDigIO) Set output port to %i is pending in %f seconds.\n",(int)[[outEventQueue objectAtIndex:i] val],[[outEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds());
	// check for AO events
	else if ((eventType>=AO_INIT_EVENT) && (eventType<=AO_END_EVENT))
	  printf("(mglStandaloneDigIO) Analog ouput %s event in %f seconds.\n",(eventType==AO_INIT_EVENT?"init":((eventType==AO_START_EVENT)?"start":"end")),([[outEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds()));
	else
	  printf("(mglStandaloneDigIO) Unknown event type in %f seconds.\n",([[outEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds()));
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
  queueEvent *qEvent = [[queueEvent alloc] initWithType:QUIT_EVENT];
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


