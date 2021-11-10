#ifdef documentation
=========================================================================

  program: mglSocketOpen.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to open a posix socket
    usage: s = mglSocketOpen(socketFilename)
		  
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
 
 // string for filename
 char *socketName = NULL;
 
 // get socketFilename
 if ((nrhs == 1) && (nlhs == 1)){
   // get how long the string is
   int buflen = mxGetM(prhs[0]) * mxGetN(prhs[0]) * sizeof(mxChar) + 1;
   // allocate space
   socketName = (char*)malloc(buflen);
   // and copy it in, checking return code for error
   if (mxGetString(prhs[0],socketName,buflen) == 1) {
     mexPrintf("(mglSocketOpen) Could not open socket %s\n",socketName);
     free(socketName);
     plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
     return;
   }
 }
 else {
   // call help on this function
   const int ndims = 1;
   const int dims[] = {1};
   mxArray *callInput[] = {mxCreateString("mglSocketOpen")};
   mexCallMATLAB(0,NULL,1,callInput,"help");
   plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
   return;
 }   

  // declarations for socket variables
  struct sockaddr_un socketAddress;
  unsigned int socketDescriptor;

  // create socket and check for error
  if ((socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    mexPrintf("(mglSocketOpen) Could not create socket to communicate between matlab and mglStandaloneDisplay\n");
    // return
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // make socket non-blocking
  if (fcntl(socketDescriptor, F_SETFL, O_NONBLOCK) < 0) {
    mexPrintf("(mglSocketOpen) Could not set socket to non-blocking. This will not record io events until a connection is made.\n");
    // return
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // set up socket address
  memset(&socketAddress, 0, sizeof(socketAddress));
  socketAddress.sun_family = AF_UNIX;
  strncpy(socketAddress.sun_path, socketName, sizeof(socketAddress.sun_path)-1);

  // unlink (make sure that it doesn't already exist)
  unlink(socketName);

  // bind the socket to the address, this could fail if you don't have
  // write permission to the directory where the socket is being made
  if (bind(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
    printf("(mglSocketOpen) Could not bind socket to name %s. This prevents communication over the socket\n",socketName);
    // return
    perror(NULL);
    close(socketDescriptor);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // listen to the socket (accept up to 500 connects)
  if (listen(socketDescriptor, 500) == -1) {
    printf("(mglSocketOpen) Could not listen to socket %s. This error will prevent communication over the socket\n",socketName);
    perror(NULL);
    close(socketDescriptor);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // success
 if (verbose) printf("(mglSocketOpen) Opened socket %s with socketDescriptor: %i\n",socketName,socketDescriptor);

  // return structure
  const char *fieldNames[] = {"socketName","socketDescriptor","connectionDescriptor"};
  const mwSize outDims[2] = {1, 1};
 plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);
 mxSetField(plhs[0],0,"socketName",mxCreateString(socketName));
 mxSetField(plhs[0],0,"socketDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
 *(double *)mxGetPr(mxGetField(plhs[0],0,"socketDescriptor")) = (double)socketDescriptor;
 mxSetField(plhs[0],0,"connectionDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
 *(double *)mxGetPr(mxGetField(plhs[0],0,"connectionDescriptor")) = -1;
}

