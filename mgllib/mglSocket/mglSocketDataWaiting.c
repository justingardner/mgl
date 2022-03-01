#ifdef documentation
=========================================================================

  program: mglSocketDataWaiting.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to poll a socket for data waiting to be reada
   usage: tf = mglSocketDataWaiting(s)
		  
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
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs != 1 || nlhs != 1) {
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketDataWaiting") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the connectionSocketDescriptor to poll.
    mxArray* field = mxGetField(prhs[0], 0, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) First argument must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) Not ready to poll connectionSocketDescriptor %d, please use mglSocketCreateClient first.\n", connectionSocketDescriptor);
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Get the pollMilliseconds configuration to use.
    field = mxGetField(prhs[0], 0, "pollMilliseconds");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) First argument must have field pollMilliseconds, please use mglSocketCreateClient first.\n");
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    int pollMilliseconds = (int) mxGetScalar(field);

    // Poll the socket for incoming data.
    struct pollfd pfd;
    pfd.fd = connectionSocketDescriptor;
    pfd.events = POLLIN;
    pfd.revents = 0;
    poll(&pfd, 1, pollMilliseconds);

    if (pfd.revents == POLLIN) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) Yes, data waiting to be read for connectionSocketDescriptor %d\n", connectionSocketDescriptor);
        }
        plhs[0] = mxCreateDoubleScalar(1);
    } else {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) No, no data waiting for connectionSocketDescriptor %d\n", connectionSocketDescriptor);
        }
        plhs[0] = mxCreateDoubleScalar(0);
    }
}
