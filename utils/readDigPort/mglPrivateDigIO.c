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

    	        To deal with the lack of a 64 bit NI-DAQmx Base (64-bit
                for NI means that it can compile as a 32 bit function on
                a 64 bit OS but not that you can compile a function that
                runs 64 bit), this code compiles a separate version that
                talks to a standalone function (which runs outside matlab
		as a 32-bit function) through a UNIX socket.
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include <stdio.h>
#include <pthread.h>
#import <Foundation/Foundation.h>
#include <mex.h>

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
// used for time function
#include <mach/mach.h>
#include <mach/mach_time.h>

////////////////////////
//   define section   //
////////////////////////
#define INIT 1
#define DIGIN 2
#define DIGOUT 3
#define LIST 4
#define AO 5
#define QUIT 0
#define SHUTDOWN -1
// event types
#define DIGDOWN_EVENT 0
#define DIGUP_EVENT 1
#define DIGOUT_EVENT 2
#define QUIT_EVENT 3
#define INIT_EVENT 4

/////////////////////
//   queue event   //
/////////////////////
@interface digQueueEvent : NSObject {
  int type;
  double time;
  uint32 val;
}
- (id)initWithTypeTimeAndValue:(int)initType :(double)initTime :(uint32)initVal;
- (id)initWithTypeAndValue:(int)initType :(uint32)initVal;
- (id)initWithType:(int)initType;
- (double)time;
- (uint32)val;
- (int)eventType;
- (void)doEvent;
- (NSComparisonResult)compareByTime:(digQueueEvent *)otherQueueEvent;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////
double getCurrentTimeInSeconds();

/////////////////////////
//   OS Specific calls //
/////////////////////////
// These functions will do different things depending on whether
// we are running in 32 bit mode and using threads to communicate
// with the digIO card or 64 bit mode and using a separate app with sockets
void initDigIO(int,int,int,int); 
mxArray *digin(void);
mxArray *digout(double, uint32);
mxArray *list(void);
void quit(void);
void mglPrivateDigIOOnExit(void);
mxArray *ao(const mxArray **);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // declare variables
  double time;
  uint32 val;

  // get which command this is
  int command = mxGetScalar(prhs[0]);

  // INIT command -----------------------------------------------------------------
  if (command == INIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0]) = 0;

    // get the nidaq ports
    int nidaqInputPortNum = 2;
    int nidaqOutputPortNum = 1;
    int inputDevnum = 1;
    int outputDevnum = 1;
    if (nrhs >=2) nidaqInputPortNum = mxGetScalar(prhs[1]);
    if (nrhs >=3) nidaqOutputPortNum = mxGetScalar(prhs[2]);
    if (nrhs >=4) inputDevnum = mxGetScalar(prhs[3]);
    if (nrhs >=5) outputDevnum = mxGetScalar(prhs[4]);

    // start either the standalone or the thread
    initDigIO(nidaqInputPortNum,nidaqOutputPortNum,inputDevnum,outputDevnum);
    
    // started running, return 1
    *mxGetPr(plhs[0]) = 1;
    return;
  }
  // digin command
  else if (command == DIGIN)
    plhs[0] = digin();
  // digout command
  else if (command == DIGOUT) {
    // get value and time
    time = (double)mxGetScalar(prhs[1]);
    val = (uint32)(double)mxGetScalar(prhs[2]);
    // call digout
    plhs[0] = digout(time,val);
  }
  // list command 
  else if (command == LIST)
    plhs[0] = list();
  // send an ao event
  else if (command == AO) {
    plhs[0] = ao(prhs);
  }
  // quit command
  else if (command == QUIT) {
    // return argument set to []
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    quit();
  }
  // shutdown command
  else if (command == SHUTDOWN) {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    mglPrivateDigIOOnExit();    
  }
  else {
    mexPrintf("(mglPrivateDigIO) Unknown command number %i\n",command);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
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

#ifndef __i386__
/////////////////////////////////////////////////////////////////////
// Implementation for 64 bit (this runs nidaq from a standalone function
// and communciates via a socket)
/////////////////////////////////////////////////////////////////////
/////////////////////////
//   include section   //
/////////////////////////
#include <sys/socket.h>
#include <sys/un.h>
#include "../../mgllib/mgl.h"
#define DEFAULT_DIGIO_SOCKETNAME ".mglDigIO"

////////////////////////
//   define section   //
////////////////////////
#define BUFLEN 8192
#define DIGINEVENTSIZE (1+1+sizeof(double))
#define TIMEOUT 5

// These have to match the command numbers in mglStandaloneDigIO
#define DIGIN_COMMAND 2
#define CLOSE_COMMAND 3
#define SHUTDOWN_COMMAND 4
#define ACK_COMMAND 5
#define DIGOUT_COMMAND 6
#define LIST_COMMAND 7
#define AO_FREQOUT_COMMAND 8

///////////////////////////////
//   function declarations   //
///////////////////////////////
int openSocket(int);
void closeSocket(void);
int writeCommandByte(unsigned char);
uint8 readuint8(int);
int writedouble(double val);
int writeuint32(uint32 val);

////////////////
//   globals  //
////////////////
static int socketDescriptor = 0;
static int verbose = 0;

///////////////
//    ao     //
///////////////
mxArray *ao(const mxArray **prhs)
{
  int i;
  // send command to do AO
  writeCommandByte(AO_FREQOUT_COMMAND);

  // write number of channels
  uint32 numChannels = (uint32)(double)mxGetScalar(prhs[1]);
  writeuint32(numChannels);

  // write time
  double *time = (double*)mxGetData(prhs[2]);
  for (i=0;i<numChannels;i++) writedouble(*(time+i));

  // write channelNum
  double *channelNum = (double*)mxGetData(prhs[3]);
  for (i=0;i<numChannels;i++) writeuint32((uint32)*(channelNum+i));

  // write freq
  double *freq = (double*)mxGetData(prhs[4]);
  for (i=0;i<numChannels;i++) writedouble(*(freq+i));

  // write amplitude
  double *amplitude = (double*)mxGetData(prhs[5]);
  for (i=0;i<numChannels;i++) writedouble(*(amplitude+i));

  // write duration
  double *duration = (double*)mxGetData(prhs[6]);
  for (i=0;i<numChannels;i++) writedouble(*(duration+i));

  // write sampleRate
  uint32 sampleRate = (uint32)(double)mxGetScalar(prhs[7]);
  writeuint32(sampleRate);
  
  // write devnum
  uint32 devnum = (uint32)(double)mxGetScalar(prhs[8]);
  writeuint32(devnum);

  // return argument
  mxArray *retval;
  retval = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(retval) = 1;
  return retval;
}

/////////////////////
//    initDigIO    //
/////////////////////
void initDigIO(int nidaqInputPortNum,int nidaqOutputPortNum,int inputDevnum,int outputDevnum) 
{
  // declare variables
  int ack;
  
  // set verbose
  verbose = mglGetGlobalDouble("verbose");

  // first, check to see if there is a standalone running
  // for which we can simply open a socket to and get an acknowledge from
  if (openSocket(1) == 1) {
    // send ack to standalone
    writeCommandByte(ACK_COMMAND);
    // wait for reply (should be 1 if running, 2 if failed)
    ack = readuint8(socketDescriptor);
    // if we got an ack back then we are done
    mexPrintf("(mglPrivateDigIO) Connected to already running standalone\n");
    if (verbose) mexPrintf("(mglPrivateDigIO) Note that any new settings for verbose, input and output ports will not be transmitted to the standalone function - to do so, you need to mglDigIO(''shutdown'') and start up again\n");
    return;
  }
  
  // If we did not get acknowledge, then shutdown any process that is running
  system("killall mglStandaloneDigIO");

  // get socket name from global
  char socketName[BUFLEN];
  mxArray *digioSocketName = mglGetGlobalField("digioSocketName");
  // check for null pointer
  if (digioSocketName == NULL) {
    sprintf(socketName,DEFAULT_DIGIO_SOCKETNAME);
    // set global to default socket name
    mglSetGlobalField("digioSocketName",mxCreateString(socketName));
  }
  else
    mxGetString(digioSocketName,socketName,BUFLEN);

  // start mglStandaloneDigIO
  if (verbose) mexPrintf("(mglPrivateDigIO) Starting external program mglStandaloneDigIO.\n");
  // first get correct path
  mxArray *mxFilePath[1];
  char filePath[BUFLEN],commandName[BUFLEN];
  mxArray *callInput[] = {mxCreateString("mglDigIO")};
  // call matlab to figure out wher mglDigIO lives
  mexCallMATLAB(1,mxFilePath,1,callInput,"which");
  mxGetString(mxFilePath[0],filePath,BUFLEN);
  // look into what is returned to find mglDigIO (we will replace that with mglStandaloneDigIO)
  char *namePtr = strstr(filePath,"mglDigIO");
  // make command
  if (namePtr) {
    // terminate at point wher mglDigIO is written in path
    *namePtr = 0;
    //make command
    sprintf(commandName,"%smglStandaloneDigIO %s %i %i %i %i %i &",filePath,socketName,nidaqInputPortNum,nidaqOutputPortNum,inputDevnum,outputDevnum,verbose);
  }
  else 
    sprintf(commandName,"mglStandaloneDigIO %s %i %i %i %i %i &",socketName,nidaqInputPortNum,nidaqOutputPortNum,inputDevnum,outputDevnum,verbose);

  // run command
  if (verbose) mexPrintf("(mglPrivateDigIO) Running: %s\n",commandName);
  system(commandName);
  
  // open the socket
  int socketOpened = 0;
  double startTime = getCurrentTimeInSeconds();
  while (((getCurrentTimeInSeconds()-startTime)<TIMEOUT) && !socketOpened) {
    socketOpened = openSocket(1);
  }

  // error, if not opened
  if (!socketOpened) {
    mexPrintf("(mglPrivateDigIO) Could not open socket to mglStandaloneDigIO.\n");
    return;
  }

  // socket has been opened
  if (verbose) mexPrintf("(mglPrivateDigIO) Successfully opened socket to mglStandaloneDigIO\n");

  // wait until we get an acknowledge that the digIO is running
  ack=-1;
  while ((ack != 1) && (ack != 0)) {
    // send ack to standalone
    writeCommandByte(ACK_COMMAND);
    // wait for reply (shoudl be 1 if running, 2 if failed)
    ack = readuint8(socketDescriptor);
  }
  
  if (ack == 1)
    mexPrintf("(mglPrivateDigIO) DigIO is running.\n");
  else 
    mexPrintf("(mglPrivateDigIO) DigIO is NOT running.\n");

  
  // set to call this function when cleared (but lock it so that
  // it only gets cleared at exit
  mexAtExit(mglPrivateDigIOOnExit);
  mexCallMATLAB(0,NULL,0,NULL,"mlock");
}

/////////////////
//    digin    //
/////////////////
mxArray *digin(void)
{
  // return value
  mxArray *retval;
  retval = mxCreateDoubleMatrix(0,0,mxREAL);

  // declare variables
  unsigned char readbuf[BUFLEN];
  int numEvents,eventCount,numThisEvents,readCount,outputCount = 0,partialReadCount,needToRead;
  double *typeOut,*lineOut,*whenOut;

  // write command byte 
  if (writeCommandByte(DIGIN_COMMAND) == -1) return(retval);

  // read a byte specifying how many digin events there are
  if (verbose) mexPrintf("(mglPrivateDigIO) Waiting for ack\n");
  readCount = read(socketDescriptor,readbuf,4);

  // convert from uchar to int
  numEvents = *(unsigned int *)(readbuf);
  if (verbose) mexPrintf("(mglPrivateDigIO) Received: %i bytes numEvents: %i\n",readCount,numEvents);

  // make return structure
  if (numEvents > 0) {
    // create structure for returning events
    const char *fieldNames[] =  {"type","line","when"};
    int outDims[2] = {1, 1};
    retval = mxCreateStructArray(1,outDims,3,fieldNames);
    // set fields and get pointers to each array
    mxSetField(retval,0,"type",mxCreateDoubleMatrix(1,numEvents,mxREAL));
    typeOut = (double*)mxGetPr(mxGetField(retval,0,"type"));
    mxSetField(retval,0,"line",mxCreateDoubleMatrix(1,numEvents,mxREAL));
    lineOut = (double*)mxGetPr(mxGetField(retval,0,"line"));
    mxSetField(retval,0,"when",mxCreateDoubleMatrix(1,numEvents,mxREAL));
    whenOut = (double*)mxGetPr(mxGetField(retval,0,"when"));
  }

  // get each one of the digin events associated with it.
  while (numEvents) {
    // read a block at most at a time. 
    readCount = read(socketDescriptor,readbuf,floor(BUFLEN/DIGINEVENTSIZE)*DIGINEVENTSIZE);
    // check for an even read. If we only have a partial last event, we will need to read that
    if ((floor((double)(readCount)/DIGINEVENTSIZE)*DIGINEVENTSIZE) != (double)(readCount)) {
      // calculate how much more we have to read
      needToRead = (int)((double)(readCount) - floor((double)(readCount)/DIGINEVENTSIZE)*DIGINEVENTSIZE);
      if (verbose) mexPrintf("(mglPrivateDigIO) Partial read of event. Trying to read rest of event (Read %i bytes. Need to read %i\n",readCount,needToRead);
      do {
	// try to read remaining bytes
	partialReadCount = read(socketDescriptor,readbuf+readCount,needToRead);
	// update how much we have read
	readCount = readCount+partialReadCount;
	needToRead = needToRead-partialReadCount;
      } while (needToRead);

    }
    numThisEvents = readCount/DIGINEVENTSIZE;
    if (verbose) mexPrintf("(mglPrivateDigIO) Received: %i bytes numThisEvents: %i of %i\n",readCount,numThisEvents,numEvents);
    if (readCount <= 0) {
      mexPrintf("(mglPrivateDigIO) !!! Could not read events from DigIO !!!\n");
      return(retval);
    }
    // update the number of events left to read
    numEvents = numEvents-numThisEvents;
    // populate return array with events
    for(eventCount = 0;eventCount < numThisEvents; eventCount++) {
      // print info
      if (verbose>1) mexPrintf("(mglPrivateDigIO) %i: Digin: %i line: %i time: %f (sizeof: %i)\n",eventCount+1,(int)(readbuf[0+DIGINEVENTSIZE*eventCount]),(int)(readbuf[1+DIGINEVENTSIZE*eventCount]),*(float*)(readbuf+2+DIGINEVENTSIZE*eventCount),(int)sizeof(float));
      // set the type, line and time in output structure
      typeOut[outputCount] = (double)(int)(readbuf[0+DIGINEVENTSIZE*eventCount]);
      lineOut[outputCount] = (double)(int)(readbuf[1+DIGINEVENTSIZE*eventCount]);
      whenOut[outputCount++] = (double)*(double*)(readbuf+2+DIGINEVENTSIZE*eventCount);
    }
  }
  return(retval);
}

//////////////////
//    digout    //
//////////////////
mxArray *digout(double time, uint32 val)
{
  mxArray *retval;
  retval = mxCreateDoubleMatrix(0,0,mxREAL);
  // send digout command
  writeCommandByte(DIGOUT_COMMAND);
  writedouble(time);
  writeuint32(val);
  return(retval);
}

////////////////
//    list    //
////////////////
mxArray *list(void)
{
  mxArray *retval;
  retval = mxCreateDoubleMatrix(0,0,mxREAL);
  // send list command
  writeCommandByte(LIST_COMMAND);
  return(retval);
}

////////////////
//    quit    //
////////////////
void quit(void)
{
  // send close command and shutdown socket
  if (socketDescriptor != -1)
    writeCommandByte(CLOSE_COMMAND);
  
  // close the socket
  closeSocket();
}

///////////////////////////////
//   mglPrivateDigIOOnExit   //
///////////////////////////////
void mglPrivateDigIOOnExit(void)
{
  // let user know what is going on
  mexPrintf("(mglPrivateDigIO) Shutting down mglPrivateDigIO\n");

  // close the socket
  if (socketDescriptor != -1) {
    // write shutdown to socket
    writeCommandByte(SHUTDOWN_COMMAND);

    // close the socket
    closeSocket();
  }
  
  // unlock this function
  mxArray *callInput[] = {mxCreateString("mglPrivateDigIO")};
  // call matlab to figure out wher mglDigIO lives
  mexCallMATLAB(0,NULL,1,callInput,"munlock");
  
}

//////////////////////
//    openSocket    //
//////////////////////
int openSocket(int suppressErrors)
{
  struct sockaddr_un addr;
  char buf[BUFLEN];

  if (socketDescriptor > 0) {
    if (verbose) mexPrintf("(mglPrivateDigIO) Socket is already open\n");
    return(1);
  }

  // get socket name from global
  char socketName[BUFLEN];
  mxArray *digioSocketName = mglGetGlobalField("digioSocketName");
  // check for null pointer
  if (digioSocketName == NULL) {
    sprintf(socketName,DEFAULT_DIGIO_SOCKETNAME);
    // set global to default socket name
    mglSetGlobalField("digioSocketName",mxCreateString(socketName));
  }
  else
    mxGetString(digioSocketName,socketName,BUFLEN);

  // open socket
  if ( (socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    if (!suppressErrors)
      mexPrintf("(mglPrivateDigIO) Could not open socket. This will prevent communication with the mglStandaloneDigIO function which runs outside of matlab and handles dig I/O.");
    return 0;
  }

  // set the address
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, socketName, sizeof(addr.sun_path)-1);

  // connect
  if (connect(socketDescriptor, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
    if (!suppressErrors)
      mexPrintf("(mglPrivateDigIO) Could not connect to socket. This will prevent communication with the mglStandaloneDigIO function which runs outside of matlab and handles dig I/O.");
    close(socketDescriptor);
    socketDescriptor = -1;
    return 0;
  }
  return 1;
}

///////////////////////
//    closeSocket    //
///////////////////////
void closeSocket()
{
  // and close
  close(socketDescriptor);

  // set socket Descriptor to -1 to specify closed
  socketDescriptor = -1;
}

///////////////////////////
//    writeCommandBye    //
///////////////////////////
int writeCommandByte(unsigned char commandByte)
{
  // check the socket is open
  if (socketDescriptor <= 0) {
    openSocket(1);
    if (socketDescriptor <= 0)
      // could not open. 
      return -1;
  }

  // write the byte
  if (write(socketDescriptor,&commandByte,1) != 1) {
    printf("(mglPrivateDigIO) Could not write to socket to communicate with mglStandalondDigIO. Have you done mglDigIO(''init'')?\n");
    return -1;
  }

  return 0;
}

/////////////////////
//    readuint8    //
/////////////////////
uint8 readuint8(int socketDescriptor)
{
  unsigned char buf;
  
  // check connection descirptor
  if (socketDescriptor <= 0) {
    mexPrintf("(mglPrivateDigIO) Could not read from socket = not open\n");
    return(0);
  }
  // read from 
  if (recv(socketDescriptor,&buf,1,0) == 1) 
    return((uint8)buf);
  else
    mexPrintf("(mglPrivateDigIO) Could not read from socket\n");
  return(0);
}

///////////////////////
//    writedouble    //
///////////////////////
int writedouble(double val)
{
  if ((write(socketDescriptor,&val,sizeof(double))) < sizeof(double)) {
    mexPrintf("(mglPrivateDigIO) Could not write double: %f\n",val);
    return(0);
  }
  return(1);
}

///////////////////////
//    writeunit32    //
///////////////////////
int writeuint32(uint32 val)
{
  if ((write(socketDescriptor,&val,sizeof(uint32))) < sizeof(uint32)) {
    mexPrintf("(mglPrivateDigIO) Could not write double: %f\n",val);
    return(0);
  }
  return(1);
}
#else
/////////////////////////////////////////////////////////////////////
// Implementation for 32 bit (this runs nidaq from within a thread)
/////////////////////////////////////////////////////////////////////
/////////////////////////
//   include section   //
/////////////////////////
#include "/Applications/National Instruments/NI-DAQmx Base/includes/NIDAQmxBase.h"

////////////////////////
//   define section   //
////////////////////////
// NIDAQ error checking macro
#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { goto Error; } }

///////////////////////////////
//   function declarations   //
///////////////////////////////
// functions for 32-bit matlab, which set up and run a thread
void* nidaqThread(void *data);
void launchNidaqThread();
// NIDAQ start/stop port reading/writing
int nidaqStartTask();
void nidaqStopTask();

////////////////
//   globals  //
////////////////
static pthread_mutex_t digioMutex;
static nidaqThreadInstalled = FALSE;
static NSAutoreleasePool *gDigIOPool;
static NSMutableArray *gDiginEventQueue;
static NSMutableArray *gDigoutEventQueue;
// NIDAQ specific globals
static TaskHandle nidaqInputTaskHandle = 0,nidaqOutputTaskHandle = 0;
static int nidaqInputPortNum = 2,nidaqOutputPortNum = 1;
static int stopNidaqThread = 0;

///////////////
//    ao     //
///////////////
mxArray *ao(const mxArray **)
{
  mexPrintf("(mglPrivateDigIO) Analog output not implemented in 32 bit\n");
  return(0);
}

/////////////////////
//    initDigIO    //
/////////////////////
void initDigIO(int setNidaqInputPortNum,int setNidaqOutputPortNum,int inputDevnum, int outputDevnum) 
{
  // Note that inputDevnum and outputDevnum are currently ignored.

  // set the global portnum variables
  nidaqInputPortNum = setNidaqInputPortNum;
  nidaqOutputPortNum = setNidaqOutputPortNum;
  // start the thread that will continue to handle reading and
  // writing the NIDAQ card
  if (!nidaqThreadInstalled) {
    // display messsage
    mexPrintf("(mglPrivateDigIO) Starting DigIO thread\n");
    // turn off flag to shutdown thread
    stopNidaqThread = 0;
    // init pthread_mutex
    pthread_mutex_init(&digioMutex,NULL);
    // init the event queue
    gDigIOPool = [[NSAutoreleasePool alloc] init];
    gDiginEventQueue = [[NSMutableArray alloc] init];
    gDigoutEventQueue = [[NSMutableArray alloc] init];
    // set up the event tap
    launchNidaqThread();
    // and remember that we have an event tap thread running
    nidaqThreadInstalled = TRUE;
    // tell matlab to call mglPrivateDigIOOnExit when this
    // function is cleared (e.g. clear all is used) so
    // that we can close open displays
    mexAtExit(mglPrivateDigIOOnExit);
  }
  // and pass an event to the thread to tell it to initialize
  // note, that we have to do this in this way, since the NIDAQ
  // library is *NOT THREAD SAFE* and the only way to insure
  // proper functioning is to only call NIDAQ functions from 
  // thread - which is the nidaq thread started above
  digQueueEvent *qEvent = [[digQueueEvent alloc] initWithType:INIT_EVENT];
  [gDigoutEventQueue insertObject:qEvent atIndex:0];
  [qEvent release];
}

/////////////////
//    digin    //
/////////////////
mxArray *digin(void)
{
  mxArray *retval;
  if (nidaqThreadInstalled) {
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&digioMutex);
    // see how many events we have
    unsigned count = [gDiginEventQueue count];
    // if we have more than one,
    if (count > 0) {
      int i = 0;
      // return event as a matlab structure
      const char *fieldNames[] =  {"type","line","when"};
      int outDims[2] = {1, 1};
      retval = mxCreateStructArray(1,outDims,3,fieldNames);
      
      mxSetField(retval,0,"type",mxCreateDoubleMatrix(1,count,mxREAL));
      double *typeOut = (double*)mxGetPr(mxGetField(retval,0,"type"));
      mxSetField(retval,0,"line",mxCreateDoubleMatrix(1,count,mxREAL));
      double *lineOut = (double*)mxGetPr(mxGetField(retval,0,"line"));
      mxSetField(retval,0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
      double *whenOut = (double*)mxGetPr(mxGetField(retval,0,"when"));
      while (count--) {
	digQueueEvent *qEvent;
	// get the last event
	qEvent = [gDiginEventQueue objectAtIndex:0];
	// and get the value and time
	typeOut[i] = [qEvent eventType];
	lineOut[i] = [qEvent val];
	whenOut[i++] = [qEvent time];
	// remove it from the queue
	[gDiginEventQueue removeObjectAtIndex:0];
      }
      // release the mutex
      pthread_mutex_unlock(&digioMutex);
    }
    else {
      // no event found, unlock mutex and return empty
      pthread_mutex_unlock(&digioMutex);
      retval = mxCreateDoubleMatrix(0,0,mxREAL);
    }
  } 
  else {
    // nidaq not installed just return empty
    retval = mxCreateDoubleMatrix(0,0,mxREAL);
  }
  return(retval);
}

//////////////////
//    digout    //
//////////////////
mxArray *digout(double time, uint32 val)
{
  mxArray *retval;
  if (nidaqThreadInstalled) {
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
    retval = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(retval) = 1;
  }
  else {
    // return 0
    retval = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(retval) = 0;
  }
  return(retval);
}

////////////////
//    list    //
////////////////
mxArray *list(void)
{
  mxArray *retval;
  if (nidaqThreadInstalled) {
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&digioMutex);
    // display which ports we are using
    mexPrintf("(mglPrivateDigIO) DigIO thread is running\n");
    if (nidaqInputTaskHandle != 0) {
      // see if nidaq card is running
      mexPrintf("(mglPrivtateDigIO) Input port is: Dev1/port%i. Output port is: Dev1/port%i\n",nidaqInputPortNum,nidaqOutputPortNum);
      if ([gDigoutEventQueue count] == 0) {
	mexPrintf("(mglPrivateDigIO) No digiout events pending.\n");
      }
      else {
	int i;
	for(i = 0; i < [gDigoutEventQueue count]; i++) {
	  mexPrintf("(mglPrivateDigIO) Set output port to %i is pending in %f seconds.\n",[[gDigoutEventQueue objectAtIndex:i] val],[[gDigoutEventQueue objectAtIndex:i] time] - getCurrentTimeInSeconds());
	}
      }
      // check input events
      mexPrintf("(mglPrivateDigIO) %i digin events in queue\n",[gDiginEventQueue count]);
    }
    else
      mexPrintf("(mglPrivateDigIO) NIDAQ card is not initialized.\n");
    // release mutex
    pthread_mutex_unlock(&digioMutex);
    // return 1
    retval = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(retval) = 1;
    return(retval);
  }
  else {
    mexPrintf("(mglPrivateDigIO) DigIO thread is not running.\n");
  }
  // return 0
  retval = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(retval) = 0;
  return(retval);
}

////////////////
//    quit    //
////////////////
void quit(void)
{
  if (nidaqThreadInstalled) {
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&digioMutex);
    
    // add a quit event
    digQueueEvent *qEvent = [[digQueueEvent alloc] initWithType:QUIT_EVENT];
    [gDigoutEventQueue insertObject:qEvent atIndex:0];
    [qEvent release];

    // release mutex
    pthread_mutex_unlock(&digioMutex);
  }
}
///////////////////////////////
//   mglPrivateDigIOOnExit   //
///////////////////////////////
void mglPrivateDigIOOnExit(void)
{
  if (nidaqThreadInstalled) {
    // lock mutex
    pthread_mutex_lock(&digioMutex);
    // signal to shutdown thread
    stopNidaqThread = 1;
    // clear the queues
    [gDigoutEventQueue removeAllObjects];
    [gDiginEventQueue removeAllObjects];
    // release the event queue
    [gDigoutEventQueue release];
    [gDiginEventQueue release];
    [gDigIOPool drain];
    // set to uninstalled
    nidaqThreadInstalled = 0;
    // and unlock mutex
    pthread_mutex_unlock(&digioMutex);
  }
  mexPrintf("(mglPrivateDigIO) Shutting down digIO thread\n");
}

/////////////////////
//   nidaqThread   //
/////////////////////
void* nidaqThread(void *data)
{
  double currentTimeInSeconds;

  // read the port once to get current state
  int32       read;
  uint8 nidaqInputStatePrevious[1];
  nidaqInputStatePrevious[0] = 0;
  while(!stopNidaqThread) {
    // get the current time in seconds
    currentTimeInSeconds = getCurrentTimeInSeconds();
    // lock the mutex to avoid concurrent access to the global variables
    pthread_mutex_lock(&digioMutex);
    // if we have been shut down then just return
    if (stopNidaqThread) continue;
    // if the nidaq input task handle has been initialized, then read
    // the port
    if (nidaqInputTaskHandle != 0) {
      // read current state of digio port
      uint8 nidaqInputState[1];
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
	      [gDiginEventQueue insertObject:qEvent atIndex:0];
	      [qEvent release];
	    }
	    else {
	      // add a digdown event
	      digQueueEvent *qEvent = [[digQueueEvent alloc] initWithTypeAndValue:DIGDOWN_EVENT :bitnum];
	      [gDiginEventQueue insertObject:qEvent atIndex:0];
	      [qEvent release];
	    }
	  }
	}
	nidaqInputStatePrevious[0] = nidaqInputState[0];
      }
    }
    // check for events to process
    if ([gDigoutEventQueue count] > 0) {
      // see if we need to post the top element on the queue
      if (currentTimeInSeconds > [[gDigoutEventQueue objectAtIndex:0] time]) {
	/////////////////////////////////
	// handle a quit event
	/////////////////////////////////
	if ([[gDigoutEventQueue objectAtIndex:0] eventType] == QUIT_EVENT) {
	  // remove all pending events
	  [gDigoutEventQueue removeAllObjects];
	  [gDiginEventQueue removeAllObjects];
	  // close nidaq ports
	  nidaqStopTask();
	  mexPrintf("(mglPrivateDigIO) Closing nidaq ports\n");
	}
	/////////////////////////////////
	// handle an init event
	/////////////////////////////////
	else if ([[gDigoutEventQueue objectAtIndex:0] eventType] == INIT_EVENT) {
	  // display message
	  mexPrintf("(mglPrivateDigIO) Initializing digin port: Dev1/port%i digout port: Dev1/port%i. End with mglDigIO('quit').\n",nidaqInputPortNum,nidaqOutputPortNum);
	  // and attempt to start task
	  if (nidaqStartTask() == 0) {
	    mexPrintf("============================================================================\n");
	    mexPrintf("(mglPrivateDigIO) UHOH! Could not start NIDAQ ports digin: %i and digout: %i\n",nidaqInputPortNum,nidaqOutputPortNum);
	    mexPrintf("============================================================================\n");
	  }
	  // and remove event from the queue
	  [gDigoutEventQueue removeObjectAtIndex:0];
	}
	/////////////////////////////////
	// handle a digout event
	/////////////////////////////////
	else {
	  // set the port
	  [[gDigoutEventQueue objectAtIndex:0] doEvent];
	  // and remove event from the queue
	  [gDigoutEventQueue removeObjectAtIndex:0];
	}
      }
    }
    // release mutex
    pthread_mutex_unlock(&digioMutex);
  }
  
  // shutdown nidaq
  pthread_mutex_lock(&digioMutex);
  nidaqStopTask();
  pthread_mutex_unlock(&digioMutex);

  // destroy mutex and return
  pthread_mutex_destroy(&digioMutex);
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
- (id)initWithTypeTimeAndValue:(int)initType :(double)initTime :(uint32)initVal;
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
- (id)initWithTypeAndValue:(int)initType :(uint32)initVal; 
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
- (uint32)val
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
    DAQmxBaseWriteDigitalU32(nidaqOutputTaskHandle,1,1,10.0,DAQmx_Val_GroupByChannel,(uInt32*)&val,&written,NULL);
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


/////////////////////////
//   nidaqStartTask   //
/////////////////////////
int nidaqStartTask()
{
  // Error variables
  int32       error = 0;
  char        errBuff[2048];

  // write variables
  int32       written;
  uint32 val;

  // Setup the channel parameter
  char inputChannel[256];
  sprintf(inputChannel,"Dev1/port%i",nidaqInputPortNum);
  char outputChannel[256];
  sprintf(outputChannel,"Dev1/port%i",nidaqOutputPortNum);

  if (nidaqInputTaskHandle != 0) {
    mexPrintf("(mglPrivateDigIO) DigIO already open, shutting down and restarting\n");
    nidaqStopTask;
  }
		   
  // open as a digital input
  DAQmxErrChk (DAQmxBaseCreateTask ("", &nidaqInputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDIChan(nidaqInputTaskHandle,inputChannel,"",DAQmx_Val_ChanForAllLines));
  DAQmxErrChk (DAQmxBaseStartTask (nidaqInputTaskHandle));



  // Create the output task
  DAQmxErrChk (DAQmxBaseCreateTask ("", &nidaqOutputTaskHandle));
  DAQmxErrChk (DAQmxBaseCreateDOChan(nidaqOutputTaskHandle,outputChannel,"",DAQmx_Val_ChanForAllLines));
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

#endif //__i386__
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

