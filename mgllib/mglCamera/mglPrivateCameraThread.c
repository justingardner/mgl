#ifdef documentation
=========================================================================

    program: mglPrivateCameraThread.c
         by: justin gardner
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       date: 10/14/2019
    purpose: Starts a thread to interact with FLIR camera - based on mglPrivateListener.c
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mex.h"
#include <pthread.h>

////////////////////////
//   define section   //
////////////////////////
#define TRUE 1
#define FALSE 0
#define INIT 1
#define QUIT 0

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* cameraThread(void *data);
void startCameraThread();
void mglPrivateCameraThreadOnExit(void);

////////////////
//   globals  //
////////////////
static pthread_mutex_t mut;
static int cameraThreadInstalled = FALSE;
static int stopCameraThread = 0;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get which command this is
  int command = mxGetScalar(prhs[0]);

  // INIT command -----------------------------------------------------------------
  if (command == INIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleScalar(0);

    // set flag to not stop
    stopCameraThread = FALSE;

    // start the thread that will have a callback that gets called every
    // time there is a keyboard or mouse event of interest
    if (!cameraThreadInstalled) {

      // init pthread_mutex
      pthread_mutex_init(&mut,NULL);
      pthread_mutex_lock(&mut);

      // start the thread
      startCameraThread();

      // and remember that we have a thread running
      cameraThreadInstalled = TRUE;

      // display that we started
      mexPrintf("(mglPrivateCameraThread) Starting camera thread. End with mglCameraThread('quit').\n");

      // tell matlab to call this function to cleanup properly
      mexAtExit(mglPrivateCameraThreadOnExit);

      // unlock the mutex
      pthread_mutex_unlock(&mut);

      // started running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
    else {
      // already running, return 1
      *mxGetPr(plhs[0]) = 1;
    }
  }
  // QUIT command -----------------------------------------------------------------
  else if (command == QUIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleScalar(0);

    // disable the thread
    if (cameraThreadInstalled) {

      // display that we started
      mexPrintf("(mglPrivateCameraThread) Quitting running camera thread\n");

      // lock the pthread mutex
      pthread_mutex_lock(&mut);

      // set flag to stop loop
      stopCameraThread = TRUE;

      // set flag to not installed
      cameraThreadInstalled = FALSE;

      // unlock the mutex
      pthread_mutex_unlock(&mut);

      // destroy mutex
      pthread_mutex_destroy(&mut);

      // message to user
      mexPrintf("(mglPrivateCameraThread) Ending camera thread\n");
    }
  }
}

//////////////////////////////////////
//   mglPrivateCameraThreadOnExit   //
//////////////////////////////////////
void mglPrivateCameraThreadOnExit()
{
  // call mglSwitchDisplay with -1 to close all open screens
  mxArray *callInput =  mxCreateDoubleMatrix(1,1,mxREAL);
  *(double*)mxGetPr(callInput) = 0;
  mexCallMATLAB(0,NULL,1,&callInput,"mglListener");
}


//////////////////////////
//   startCameraThread  //
//////////////////////////
void startCameraThread()
{
  // Create the thread using POSIX routines.
  pthread_attr_t  attr;
  pthread_t       posixThreadID;

  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

  int threadError = pthread_create(&posixThreadID, &attr, &cameraThread, NULL);

  pthread_attr_destroy(&attr);
  if (threadError != 0)
    mexPrintf("(mglPrivateCameraThread) Error could not setup camera thread: error %i\n",threadError);
}


/////////////////////
//   cameraThread   //
/////////////////////
void* cameraThread(void *data)
{
  int i = 0;
  mexPrintf("Starting\n");
  while(!stopCameraThread) {
    if (i++ > 1000000) {
      i = 0;
      mexPrintf(".");
    }
    // get the current time in seconds
     //currentTimeInSeconds = getCurrentTimeInSeconds();
  }
  
  mexPrintf("Stopped\n");
  return NULL;
}
