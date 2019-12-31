#ifdef documentation
=========================================================================

  program: mglSocketDataWaiting.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to read from a posix socket
   usage: [tf s] = mglSocketDataWaiting(s)
		  
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <memory.h>
#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <CoreServices/CoreServices.h>
#include <poll.h>
									   
									   

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
 // get verbose setting
 int verbose = (int)mglGetGlobalDouble("verbose");

 unsigned int socketDescriptor;
 unsigned int connectionDescriptor = -1;
 mxArray *socketName;
 
 // get socket
 if ((nrhs == 1) && (nlhs == 2)) {
   mxArray *field;
   if ((socketName = mxGetField(prhs[0],0,"socketName")) == NULL) {
     mexPrintf("(mglSocketDataWaiting) Input argument must have field: socketName\n");
     return;
   }
    // get the connectionDescriptor
   if ((field = mxGetField(prhs[0],0,"connectionDescriptor")) == NULL) {
     mexPrintf("(mglSocketDataWaiting) Input argument must have field: connectionDescriptor\n");
     return;
   }
   connectionDescriptor = (unsigned int)mxGetScalar(field);
   // get the socketDescriptor
   if ((field = mxGetField(prhs[0],0,"socketDescriptor")) == NULL) {
     mexPrintf("(mglSocketDataWaiting) Input argument must have field: socketDescriptor\n");
     return;
   }
   socketDescriptor = (unsigned int)mxGetScalar(field);
 }
 else {
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketDataWaiting")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
   plhs[1] = mxDuplicateArray(prhs[0]);
   return;
 }   

 // check for closed connection, if so, try to reopen
 int displayWaitingForConnection = 1;
 if (connectionDescriptor == -1) {
   // display that we are waiting for connection (but only once)
   if (displayWaitingForConnection) {
     if (verbose) printf("(mglSocketDataWaiting) Waiting for a new connection\n");
     displayWaitingForConnection = 0;
   }
   // try to make a connection
   if ((connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
     mexPrintf("(mglSocketDataWaiting) Unable to make connection with socketDescriptor: %i\n",socketDescriptor);
     plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
     plhs[1] = mxDuplicateArray(prhs[0]);
     return;
   }
   else {
     if (verbose) printf("(mglSocketDataWaiting) New connection made: %i\n",(int)connectionDescriptor);
     displayWaitingForConnection = 1;
   }
 }

 if (verbose) mexPrintf("(mglSocketDataWaiting) Using connectionDescriptor %i\n",connectionDescriptor);

 // use poll function to return whether there is data waiting
 struct pollfd pfd;
 pfd.fd = connectionDescriptor;
 pfd.events = POLLIN;
 pfd.revents = 0;
 poll(&pfd,1,0);
    
 // return true or false
 if (pfd.revents == POLLIN)
   plhs[0] = mxCreateDoubleScalar(1);
 else
   plhs[0] = mxCreateDoubleScalar(0);
 plhs[1] = mxDuplicateArray(prhs[0]);
 
}

