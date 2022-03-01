#ifdef documentation
=========================================================================

  program: mglSocketAcceptConnection.c
       by: Ben Heasly
     date: 03/01/2022
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to accept a posix socet connection from a client.
    usage: s = mglSocketAcceptConnection(s)
		  
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
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs != 1 || nlhs != 1) {
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketAcceptConnection") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the server's boundSocketDescriptor, if any.
    mxArray* field = mxGetField(prhs[0], 0, "boundSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketAcceptConnection) First argument must have field boundSocketDescriptor, please use mglSocketCreateServer first.\n");
        }
        plhs[0] = mxDuplicateArray(prhs[0]);
        return;
    }
    int boundSocketDescriptor = (int) mxGetScalar(field);
    if (boundSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketAcceptConnection) Not ready to accept connection with boundSocketDescriptor %d, please use mglSocketCreateServer first.\n", boundSocketDescriptor);
        }
        plhs[0] = mxDuplicateArray(prhs[0]);
        return;
    }

    // Accept a client connection if one is pending.
    int connectionSocketDescriptor = accept(boundSocketDescriptor, NULL, NULL);
    if (verbose) {
        if (connectionSocketDescriptor >= 0) {
            mexPrintf("(mglSocketAcceptConnection) Accepted client connection with connectionSocketDescriptor %d.\n", connectionSocketDescriptor);
        } else if (errno == EAGAIN || errno == EWOULDBLOCK) {
            mexPrintf("(mglSocketAcceptConnection) No client connection is pending, please wait and try again.\n");
        } else {
            mexPrintf("(mglSocketAcceptConnection) Error accepting client connection -- result: %d, errno: %d\n", connectionSocketDescriptor, errno);
        }
    }
    
    // Return info struct with updated connectionSocketDescriptor.
    plhs[0] = mxDuplicateArray(prhs[0]);
    mxSetField(plhs[0], 0, "connectionSocketDescriptor", mxCreateDoubleScalar(connectionSocketDescriptor));
}
