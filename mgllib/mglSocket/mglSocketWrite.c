#ifdef documentation
=========================================================================

  program: mglSocketWrite.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to write typed data as bytes to a posix socket
    usage: byteCount = mglSocketWrite(s, data)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include "mglCommandTypes.h"
#include <sys/socket.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs != 2) {
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketWrite") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the connectionSocketDescriptor to write to.
    mxArray* field = mxGetField(prhs[0], 0, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketWrite) First argument must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketWrite) Not ready to write to connectionSocketDescriptor %d, please use mglSocketCreateClient first.\n", connectionSocketDescriptor);
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Check for a supported data type and get the corresponding overall data size in bytes.
    size_t numElements = (size_t) (mxGetN(prhs[1]) * mxGetM(prhs[1]));
    size_t numBytes = 0;
    if (mxIsClass(prhs[1], "uint16")) {
        numBytes = mglSizeOfCommandCodeArray(numElements);
    } else if (mxIsClass(prhs[1], "uint32")) {
        numBytes = mglSizeOfUInt32Array(numElements);
    } else if (mxIsClass(prhs[1], "double")) {
        numBytes = mglSizeOfDoubleArray(numElements);
    } else if (mxIsClass(prhs[1], "single")) {
        numBytes = mglSizeOfFloatArray(numElements);
    } else {
        if (verbose) {
            mexPrintf("(mglSocketWrite) Unsupported data type %s, must be uint16, uint32, double, or single.\n", mxGetClassName(prhs[1]));
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    if (verbose) {
        mexPrintf("(mglSocketWrite) Sending %d elements of type %s as %d bytes on connectionSocketDescriptor %d.\n", numElements, mxGetClassName(prhs[1]), numBytes, connectionSocketDescriptor);
    }

    int totalSent = 0;
    while (totalSent < numBytes) {
        int sent = send(connectionSocketDescriptor, mxGetPr(prhs[1]), numBytes, 0);
        if (sent < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                continue;
            } else {
                break;
            }
        }
        totalSent += sent;
    }
    if (verbose) {
        if (totalSent < numBytes) {
            mexPrintf("(mglSocketWrite) Expected to send %d bytes but sent %d, errno: %d\n", numBytes, totalSent, errno);
        } else {
            mexPrintf("(mglSocketWrite) Sent %d bytes.\n", totalSent);
        }
    }
 
    // Return the number of bytes actually sent.
    plhs[0] = mxCreateDoubleScalar(totalSent);
}
