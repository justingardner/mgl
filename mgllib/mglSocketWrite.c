#ifdef documentation
=========================================================================

  program: mglSocketWrite.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to write to a posix socket
    usage: s = mglSocketWrite(s, data)
		  
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
 if ((nrhs == 2) && (nlhs == 1)) {
   mxArray *field;
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

 if (verbose) mexPrintf("(mglSocketWrite) Using socketDescriptor %i\n", socketDescriptor);

 size_t len = (size_t)(mxGetN(prhs[1])*mxGetM(prhs[1]));
 size_t dataSize = 0;
 if (mxIsClass(prhs[1],"uint16"))
   dataSize = sizeof(uint16);
 else if (mxIsClass(prhs[1],"uint32"))
   dataSize = sizeof(uint32);
 else if (mxIsClass(prhs[1],"uint8"))
   dataSize = sizeof(uint8);
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

 size_t dataBytes = dataSize * len;
 int sentSize = write(socketDescriptor, mxGetPr(prhs[1]), dataBytes);
 if (sentSize < 0) {
     mexPrintf("(mglSocketWrite) Expected to send %d dataBytes but sent %d, errno: %d\n", dataBytes, sentSize, errno);
 }

 if (verbose) mexPrintf("(mglSocketWrite) Wrote %i of %i dataBytes (%i (%i x %i))\n", sentSize, dataBytes, len, mxGetN(prhs[1]), mxGetM(prhs[1]));
 
 // return structure, set connection descriptor
 plhs[0] = mxDuplicateArray(prhs[0]);
}
