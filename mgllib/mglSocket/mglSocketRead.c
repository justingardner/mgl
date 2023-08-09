#ifdef documentation
=========================================================================

  program: mglSocketRead.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to read from one or more posix socket
   usage: data = mglSocketRead(s, typeName, rows=1, columns=1, slices=1)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include "mglCommandTypes.h"
#include <string.h>
#include <sys/socket.h>

mxDouble readForStructElement(const mxArray* socketInfo, mwIndex index, void* dataBytes, size_t numBytes, int verbose);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    // Check for expected usage.
    if (nrhs < 2 || nrhs > 5 || !mxIsStruct(prhs[0])) {
        mxArray *callInput[] = { mxCreateString("mglSocketRead") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the element type of data expecting to read.
    char *typeName = mxArrayToUTF8String(prhs[1]);
    if (typeName == NULL) {
        mexPrintf("(mglSocketRead) Could not read data type name from second arg.\n");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    if (verbose) {
        mexPrintf("(mglSocketRead) Reading data with element type %s.\n", typeName);
    }

    // Get the dimensions of the output matrix.
    mwSize rows = 1;
    if (nrhs >= 3) {
        rows = (mwSize) mxGetScalar(prhs[2]);
    }

    mwSize columns = 1;
    if (nrhs >= 4) {
        columns = (mwSize) mxGetScalar(prhs[3]);
    }

    mwSize slices = 1;
    if (nrhs >= 5) {
        slices = (mwSize) mxGetScalar(prhs[4]);
    }

    size_t m = mxGetM(prhs[0]);
    size_t n = mxGetN(prhs[0]);
    size_t socketCount = m * n;

    // Construct the output matrix of expected size and type.
    size_t numElements = rows * columns * slices;
    size_t numBytes = 0;
    mwSize dims[] = {rows, columns, slices, socketCount};
    mxArray* data;
    if (!strcmp("uint8", typeName)) {
        numBytes = numElements;
        data = mxCreateNumericArray(4, dims, mxUINT8_CLASS, mxREAL);
    } else if (!strcmp("uint16", typeName)) {
        numBytes = mglSizeOfCommandCodeArray(numElements);
        data = mxCreateNumericArray(4, dims, mxUINT16_CLASS, mxREAL);
    } else if (!strcmp("uint32", typeName)) {
        numBytes = mglSizeOfUInt32Array(numElements);
        data = mxCreateNumericArray(4, dims, mxUINT32_CLASS, mxREAL);
    } else if (!strcmp("double", typeName)) {
        numBytes = mglSizeOfDoubleArray(numElements);
        data = mxCreateNumericArray(4, dims, mxDOUBLE_CLASS, mxREAL);
    } else if (!strcmp("single", typeName)) {
        numBytes = mglSizeOfFloatArray(numElements);
        data = mxCreateNumericArray(4, dims, mxSINGLE_CLASS, mxREAL);
    } else {
        mexPrintf("(mglSocketRead) Unsupported data type %s, must be uint8,uint16, uint32, double, or single.\n", typeName);
        mxFree(typeName);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    mxFree(typeName);

    if (verbose) {
        mexPrintf("(mglSocketRead) Reading %d x %d x %d elements of type %s as %d bytes from %d sockets.\n", rows, columns, slices, mxGetClassName(data), numBytes, socketCount);
    }

    // Aggregate read results from multiple sockets, one from each element
    // of the given socket info struct array.
    void* dataBytes = mxGetData(data);
    int index;
    for (index = 0; index < socketCount; index++) {
        size_t socketOffset = index * numBytes;
        readForStructElement(prhs[0], index, dataBytes + socketOffset, numBytes, verbose);
    }

    plhs[0] = data;
}

mxDouble readForStructElement(const mxArray* socketInfo, mwIndex index, void* dataBytes, size_t numBytes, int verbose) {
    // Get the connectionSocketDescriptor to read from.
    mxArray* field = mxGetField(socketInfo, index, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketRead) Socket info must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        return -1;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketRead) Not ready to read from connectionSocketDescriptor %d (index %d), please use mglSocketCreateClient first.\n", connectionSocketDescriptor, index);
        }
        return -1;
    }

    // Read data from the socket into the Matlab data matrix.
    int readBytes = recv(connectionSocketDescriptor, dataBytes, numBytes, MSG_WAITALL);
    if (verbose) {
        if (readBytes < numBytes) {
            mexPrintf("(mglSocketRead) Expected to read %d bytes but read %d, errno: %d\n", numBytes, readBytes, errno);
        } else {
            mexPrintf("(mglSocketRead) Read %d bytes.\n", readBytes);
        }
    }
    return readBytes;
}
