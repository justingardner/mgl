#ifdef documentation
=========================================================================

  program: mglSocketWrite.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to write to a posix socket				  usage: s = mglSocketWrite(s, data)
		  
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
 if ((nrhs == 2) && (nlhs == 1)) {
   mxArray *field;
   if ((socketName = mxGetField(prhs[0],0,"socketName")) == NULL) {
     mexPrintf("(mglSocketWrite) Input argument must have field: socketName\n");
     return;
   }
    // get the connectionDescriptor
   if ((field = mxGetField(prhs[0],0,"connectionDescriptor")) == NULL) {
     mexPrintf("(mglSocketWrite) Input argument must have field: connectionDescriptor\n");
     return;
   }
   connectionDescriptor = (unsigned int)mxGetScalar(field);
   // get the socketDescriptor
   if ((field = mxGetField(prhs[0],0,"socketDescriptor")) == NULL) {
     mexPrintf("(mglSocketWrite) Input argument must have field: socketDescriptor\n");
     return;
   }
   socketDescriptor = (unsigned int)mxGetScalar(field);
 }
 else {
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketWrite")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
   return;
 }   

 // check for closed connection, if so, try to reopen
 int displayWaitingForConnection = 1;
 if (connectionDescriptor == -1) {
   // display that we are waiting for connection (but only once)
   if (displayWaitingForConnection) {
     if (verbose) printf("(mglSocketWrite) Waiting for a new connection\n");
     displayWaitingForConnection = 0;
   }
   // try to make a connection
   if ((connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
     mexPrintf("(mglSocketWrite) Unable to make connection with socketDescriptor: %i\n",socketDescriptor);
     plhs[0] = mxDuplicateArray(prhs[0]);
     return;
   }
   else {
     if (verbose) printf("(mglSocketWrite) New connection made: %i\n",(int)connectionDescriptor);
     displayWaitingForConnection = 1;
   }
 }

 if (verbose) mexPrintf("(mglSocketWrite) Using connectionDescriptor %i\n",connectionDescriptor);

 int sentSize;
 size_t len = (size_t)(mxGetN(prhs[1])*mxGetM(prhs[1]));
 size_t dataSize = 0;
 if (mxIsClass(prhs[1],"uint16"))
   dataSize = sizeof(uint16);
 else if (mxIsClass(prhs[1],"uint32"))
   dataSize = sizeof(uint32);
 else if (mxIsClass(prhs[1],"double"))
   dataSize = sizeof(double);
 else if (mxIsClass(prhs[1],"single"))
   dataSize = sizeof(float);
 else {
   mexPrintf("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
   mexPrintf("(mglSocketWrite) Data input is not in a recogonized format\n");
   mexPrintf("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketWrite")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxDuplicateArray(prhs[0]);
   return;
 }
 size_t sendSize = dataSize * len;
 
 // write data
 if ((sentSize = write(connectionDescriptor,mxGetPr(prhs[1]),sendSize)) < sendSize) {
     mexPrintf("(mglSocketWrite) ERROR Only sent %i of %i bytes across socket- data might be corrupted\n",sentSize,sendSize);
 }

 if (verbose) mexPrintf("(mglSocketWrite) Wrote %i bytes\n",sentSize);
 // return structure, set connection descriptor
 plhs[0] = mxDuplicateArray(prhs[0]);
 mxSetField(plhs[0],0,"connectionDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"connectionDescriptor")) = (double)connectionDescriptor;
}

