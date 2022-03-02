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
#include <sys/socket.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs != 1) {
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketClose") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the server's boundSocketDescriptor, if any.
    mxArray* field = mxGetField(prhs[0], 0, "boundSocketDescriptor");
    if (field != NULL) {
        int boundSocketDescriptor = (int) mxGetScalar(field);
        if (boundSocketDescriptor < 0) {
            if (verbose) {
                mexPrintf("(mglSocketClose) boundSocketDescriptor is already closed.\n");
            }
        } else {
            if (verbose) {
                mexPrintf("(mglSocketClose) closing boundSocketDescriptor %d.\n", boundSocketDescriptor);
            }
            close(boundSocketDescriptor);
        }
    }

    // Get the client's or server's connectionSocketDescriptor, if any.
    field = mxGetField(prhs[0], 0, "connectionSocketDescriptor");
    if (field != NULL) {
        int connectionSocketDescriptor = (int) mxGetScalar(field);
        if (connectionSocketDescriptor < 0) {
            if (verbose) {
                mexPrintf("(mglSocketClose) connectionSocketDescriptor is already closed.\n");
            }
        } else {
            if (verbose) {
                mexPrintf("(mglSocketClose) closing connectionSocketDescriptor %d.\n", connectionSocketDescriptor);
            }
            close(connectionSocketDescriptor);
        }
    }
    
    // Return updated info struct with socket descriptors taken out.
    plhs[0] = mxDuplicateArray(prhs[0]);
    mxSetField(plhs[0], 0, "boundSocketDescriptor", mxCreateDoubleScalar(-1));
    mxSetField(plhs[0], 0, "connectionSocketDescriptor", mxCreateDoubleScalar(-1));
}

