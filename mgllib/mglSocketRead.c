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
#include <sys/socket.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
 // get verbose setting
 int verbose = (int)mglGetGlobalDouble("verbose");

 unsigned int socketDescriptor = -1;
 
 // get socket
 if ((nrhs == 1) && (nlhs == 2)) {
   mxArray *field;
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
   plhs[1] = mxDuplicateArray(prhs[0]);
   return;
 }   

 if (verbose) mexPrintf("(mglSocketRead) Using socketDescriptor %i\n", socketDescriptor);

 size_t len = 1;
 size_t dataSize = sizeof(double);
 size_t dataBytes = dataSize * len;

 // allocate space for buffer
 const mwSize dims[2] = {1,len};
 plhs[0] = mxCreateNumericArray(1,dims,mxDOUBLE_CLASS,mxREAL);

 // read data
 int readCount = recv(socketDescriptor, mxGetPr(plhs[0]), dataBytes, MSG_WAITALL);
 if (readCount < dataBytes) {
     mexPrintf("(mglSocketRead) ERROR Expected to read %d dataBytes but read %d, errno: %d\n", dataBytes, readCount, errno);
 }

 if (verbose) mexPrintf("(mglSocketRead) Read %i bytes\n", readCount);

 // return structure
 plhs[1] = mxDuplicateArray(prhs[0]);
}
