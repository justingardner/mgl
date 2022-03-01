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
#include <sys/socket.h>
#include <sys/un.h>

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
     mexPrintf("(mglSocketOpen) Could not read socket name %s\n",socketName);
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
  socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0);
  if (socketDescriptor < 0) {
    mexPrintf("(mglSocketOpen) Could not create socket: %u errno: %d\n", socketDescriptor, errno);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // set up socket address
  memset(&socketAddress, 0, sizeof(socketAddress));
  socketAddress.sun_family = AF_UNIX;
  strncpy(socketAddress.sun_path, socketName, sizeof(socketAddress.sun_path)-1);

  // connect the socket to the server at the given address
  // this requires that the server has already bound the address
  // and is listening and accepting connections
  int connectResult = connect(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress));
  if (connectResult < 0) {
    printf("(mglSocketOpen) Could not connect to %s: %d errno: %d\n", socketName, connectResult, errno);
    perror(NULL);
    close(socketDescriptor);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    free(socketName);
    return;
  }

  // success
 if (verbose) printf("(mglSocketOpen) Opened socket %s with socketDescriptor: %i\n", socketName, socketDescriptor);

 // return structure
 const char *fieldNames[] = {"socketName","socketDescriptor"};
 const mwSize outDims[2] = {1, 1};
 plhs[0] = mxCreateStructArray(1,outDims,2,fieldNames);
 mxSetField(plhs[0],0,"socketName",mxCreateString(socketName));
 mxSetField(plhs[0],0,"socketDescriptor",mxCreateDoubleMatrix(1,1,mxREAL));
 *(double *)mxGetPr(mxGetField(plhs[0],0,"socketDescriptor")) = (double)socketDescriptor;
}

