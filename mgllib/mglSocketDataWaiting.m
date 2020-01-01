#ifdef documentation
=========================================================================

  program: mglSocketRead.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to read from a posix socket
   usage: [s data] = mglSocketRead(s)
		  
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
 if ((nrhs == 1) && (nlhs == 2)) {
   mxArray *field;
   if ((socketName = mxGetField(prhs[0],0,"socketName")) == NULL) {
     mexPrintf("(mglSocketRead) Input argument must have field: socketName\n");
     return;
   }
    // get the connectionDescriptor
   if ((field = mxGetField(prhs[0],0,"connectionDescriptor")) == NULL) {
     mexPrintf("(mglSocketRead) Input argument must have field: connectionDescriptor\n");
     return;
   }
   connectionDescriptor = (unsigned int)mxGetScalar(field);
   // get the socketDescriptor
   if ((field = mxGetField(prhs[0],0,"socketDescriptor")) == NULL) {
     mexPrintf("(mglSocketRead) Input argument must have field: socketDescriptor\n");
     return;
   }
   socketDescriptor = (unsigned int)mxGetScalar(field);
 }
 else {
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketRead")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
   return;
 }   

 // check for closed connection, if so, try to reopen
 int displayWaitingForConnection = 1;
 if (connectionDescriptor == -1) {
   // display that we are waiting for connection (but only once)
   if (displayWaitingForConnection) {
     if (verbose) printf("(mglSocketRead) Waiting for a new connection\n");
     displayWaitingForConnection = 0;
   }
   // try to make a connection
   if ((connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
     mexPrintf("(mglSocketRead) Unable to make connection with socketDescriptor: %i\n",socketDescriptor);
     plhs[0] = mxDuplicateArray(prhs[0]);
     return;
   }
   else {
     if (verbose) printf("(mglSocketRead) New connection made: %i\n",(int)connectionDescriptor);
     displayWaitingForConnection = 1;
   }
 }

 if (verbose) mexPrintf("(mglSocketRead) Using connectionDescriptor %i\n",connectionDescriptor);

 int readCount;
 size_t len = 1;
 size_t dataSize = sizeof(double);
 size_t buflen = dataSize * len;

 // allocate space for buffer
 const int dims[2] = {1,len};
 plhs[1] = mxCreateNumericArray(1,dims,mxDOUBLE_CLASS,mxREAL);

 // read data
 if ((readCount=recv(connectionDescriptor,mxGetPr(plhs[1]),buflen,0)) != buflen) {
     mexPrintf("(mglSocketRead) ERROR Only read %i of %i bytes across socket- data might be corrupted\n",readCount,buflen);
 }

p if (verbose) mexPrintf("(mglSocketRead) Read %i bytes\n",readCount);

 // return structure, set connection descriptor
 plhs[0] = mxDuplicateArray(prhs[0]);
 mxSetField(plhs[0],0,"connectionDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"connectionDescriptor")) = (double)connectionDescriptor;
}

