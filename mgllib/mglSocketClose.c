#ifdef documentation
=========================================================================

  program: mglSocketClose.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to close a posix socket
    usage: s = mglSocketClose(s)
		  
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
 unsigned int connectionDescriptor;
 
 // get socket
 if (nrhs == 1) {
   mxArray *field;
   // get the connectionDescriptor
   if ((field = mxGetField(prhs[0],0,"connectionDescriptor")) == NULL) {
     mexPrintf("(mglSocketClose) Input argument must have field: connectionDescriptor\n");
     return;
   }
   connectionDescriptor = (unsigned int)mxGetScalar(field);
   // get the socketDescriptor
   if ((field = mxGetField(prhs[0],0,"socketDescriptor")) == NULL) {
     mexPrintf("(mglSocketClose) Input argument must have field: socketDescriptor\n");
     return;
   }
   socketDescriptor = (unsigned int)mxGetScalar(field);
 }
 else {
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketClose")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
   return;
 }   

 // check if open
 if (connectionDescriptor == -1) {
   if (verbose) mexPrintf("(mglSocketClose) Socket already closed\n");
 }
 else {
   if (verbose) mexPrintf("(mglSocketClose) Closing socket %i\n",connectionDescriptor);
   close(connectionDescriptor);
 }

  // return structure
 plhs[0] = mxDuplicateArray(prhs[0]);
 mxSetField(plhs[0],0,"connectionDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
 *(double *)mxGetPr(mxGetField(plhs[0],0,"connectionDescriptor")) = -1.0;
}

