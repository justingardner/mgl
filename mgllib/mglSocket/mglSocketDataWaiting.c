#ifdef documentation
=========================================================================

  program: mglSocketDataWaiting.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to poll one or more sockets for data waiting to be read
   usage: tf = mglSocketDataWaiting(s)
		  
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include <sys/socket.h>
#include <poll.h>

double pollForStructElement(const mxArray* socketInfo, mwIndex index, int verbose);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check for expected usage.
    if (nrhs != 1 || nlhs != 1 || !mxIsStruct(prhs[0])) {
        mxArray *callInput[] = { mxCreateString("mglSocketDataWaiting") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    int verbose = (int)mglGetGlobalDouble("verbose");

    // Aggregate polling results from multiple sockets, one from each element
    // of the given socket info struct array.
    size_t m = mxGetM(prhs[0]);
    size_t n = mxGetN(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
    mxDouble* resultDoubles = mxGetPr(plhs[0]);
    size_t socketCount = m * n;
    int index;
    for (index = 0; index < socketCount; index++) {
        mxDouble dataWaiting = pollForStructElement(prhs[0], index, verbose);
        resultDoubles[index] = dataWaiting;
    }
}

// Poll the socket from the index-th element of the socketInfo array.
// Return 1.0 if data waiting, 0.0 if not, or -1.0 on error.
mxDouble pollForStructElement(const mxArray* socketInfo, mwIndex index, int verbose) {
    // Get the connectionSocketDescriptor to poll.
    mxArray* field = mxGetField(socketInfo, index, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) Socket info must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        return -1.0;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) Not ready to poll connectionSocketDescriptor %d (index %d), please use mglSocketCreateClient first.\n", connectionSocketDescriptor, index);
        }
        return -1.0;
    }

    // Get the pollMilliseconds configuration to use.
    field = mxGetField(socketInfo, index, "pollMilliseconds");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) Socket info must have field pollMilliseconds, please use mglSocketCreateClient first.\n");
        }
        return -1.0;
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
            mexPrintf("(mglSocketDataWaiting) Yes, data waiting to be read for connectionSocketDescriptor %d (index %d)\n", connectionSocketDescriptor, index);
        }
        return 1;
    } else {
        if (verbose) {
            mexPrintf("(mglSocketDataWaiting) No, no data waiting for connectionSocketDescriptor %d (index %d)\n", connectionSocketDescriptor, index);
        }
        return 0;
    }
}
