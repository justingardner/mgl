#ifdef documentation
=========================================================================

  program: mglSocketWrite.c
       by: justin gardner
     date: 12/24/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to write typed data as bytes to one or more posix socket
    usage: byteCount = mglSocketWrite(s, data)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include "mglCommandTypes.h"
#include <sys/socket.h>

mxDouble writeForStructElement(const mxArray* socketInfo, mwIndex index, const void* dataBytes, size_t numBytes, int verbose);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs != 2 || !mxIsStruct(prhs[0])) {
        mxArray *callInput[] = { mxCreateString("mglSocketWrite") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Check for a supported data type and get the corresponding overall data size in bytes.
    size_t numElements = mxGetN(prhs[1]) * mxGetM(prhs[1]);
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

    // Aggregate write results from multiple sockets, one from each element
    // of the given socket info struct array.
    size_t m = mxGetM(prhs[0]);
    size_t n = mxGetN(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
    mxDouble* resultDoubles = mxGetPr(plhs[0]);
    size_t socketCount = m * n;

    if (verbose) {
        mexPrintf("(mglSocketWrite) Sending %d elements of type %s as %d bytes on %d sockets.\n", numElements, mxGetClassName(prhs[1]), numBytes, socketCount);
    }

    void* dataBytes = mxGetData(prhs[1]);
    int index;
    for (index = 0; index < socketCount; index++) {
        mxDouble bytesWritten = writeForStructElement(prhs[0], index, dataBytes, numBytes, verbose);
        resultDoubles[index] = bytesWritten;
    }
}

// Write data to the socket from the index-th element of socketInfo.
// Return the number of bytes written, or -1.0 on error.
mxDouble writeForStructElement(const mxArray* socketInfo, mwIndex index, const void* dataBytes, size_t numBytes, int verbose) {
    // Get the connectionSocketDescriptor to write to.
    mxArray* field = mxGetField(socketInfo, index, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketWrite) Socket info must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        return -1;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketWrite) Not ready to write to connectionSocketDescriptor %d (index %d), please use mglSocketCreateClient first.\n", connectionSocketDescriptor, index);
        }
        return -1;
    }

    if (verbose) {
        mexPrintf("(mglSocketWrite) Sending %d bytes on connectionSocketDescriptor %d (index %d).\n", numBytes, connectionSocketDescriptor, index);
    }

    int totalSent = 0;
    while (totalSent < numBytes) {
        int sent = send(connectionSocketDescriptor, dataBytes + totalSent, numBytes - totalSent, 0);
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

    return totalSent;
}
