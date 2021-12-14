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
#include <sys/socket.h>
#include <poll.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
 // get verbose setting
 int verbose = (int)mglGetGlobalDouble("verbose");

 unsigned int socketDescriptor = -1;
 int pollMilliseconds = 10;
 
 // get socket
 if ((nrhs == 1) && (nlhs == 2)) {
   mxArray *field;
   // get the socketDescriptor
   if ((field = mxGetField(prhs[0],0,"socketDescriptor")) == NULL) {
     mexPrintf("(mglSocketDataWaiting) Input argument must have field: socketDescriptor\n");
     return;
   }
   socketDescriptor = (unsigned int)mxGetScalar(field);

   // get the optional polling milliseconds
   if ((field = mxGetField(prhs[0],0,"pollMilliseconds")) != NULL) {
     pollMilliseconds = (int)mxGetScalar(field);
   }
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

 if (verbose) mexPrintf("(mglSocketDataWaiting) Using socketDescriptor %i and pollMilliseconds %i\n", socketDescriptor, pollMilliseconds);

 // use poll function to return whether there is data waiting
 struct pollfd pfd;
 pfd.fd = socketDescriptor;
 pfd.events = POLLIN;
 pfd.revents = 0;
 poll(&pfd,1,pollMilliseconds);

 // return true or false
 if (pfd.revents == POLLIN)
   plhs[0] = mxCreateDoubleScalar(1);
 else
   plhs[0] = mxCreateDoubleScalar(0);
 plhs[1] = mxDuplicateArray(prhs[0]);
 
}

