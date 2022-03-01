#ifdef documentation
=========================================================================

  program: mglSocketRead.c
       by: justin gardner
     date: 12/26/2019
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to read from a posix socket
   usage: data = mglSocketRead(s, typeName, rows=1, columns=1)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include "mglCommandTypes.h"
#include <string.h>
#include <sys/socket.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    // Check for expected usage.
    if (nrhs < 2 || nrhs > 4 || nlhs != 1) {
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketRead") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the connectionSocketDescriptor to read from.
    mxArray* field = mxGetField(prhs[0], 0, "connectionSocketDescriptor");
    if (field == NULL) {
        if (verbose) {
            mexPrintf("(mglSocketRead) First argument must have field connectionSocketDescriptor, please use mglSocketCreateClient first.\n");
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    int connectionSocketDescriptor = (int) mxGetScalar(field);
    if (connectionSocketDescriptor < 0) {
        if (verbose) {
            mexPrintf("(mglSocketRead) Not ready to read from connectionSocketDescriptor %d, please use mglSocketCreateClient first.\n", connectionSocketDescriptor);
        }
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Get the type and size of data expecting to read.
    char *typeName = mxArrayToUTF8String(prhs[1]);
    if (typeName == NULL) {
        mexPrintf("(mglSocketRead) Could not read data type name from second arg.\n");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    if (verbose) {
        mexPrintf("(mglSocketRead) Reading data type %s.\n", typeName);
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

    size_t numElements = rows * columns;
    size_t numBytes = 0;
    mxArray* data;
    if (!strcmp("uint16", typeName)) {
        numBytes = mglSizeOfCommandCodeArray(numElements);
        data = mxCreateNumericMatrix(rows, columns, mxUINT16_CLASS, mxREAL);
    } else if (!strcmp("uint32", typeName)) {
        numBytes = mglSizeOfUInt32Array(numElements);
        data = mxCreateNumericMatrix(rows, columns, mxUINT32_CLASS, mxREAL);
    } else if (!strcmp("double", typeName)) {
        numBytes = mglSizeOfDoubleArray(numElements);
        data = mxCreateNumericMatrix(rows, columns, mxDOUBLE_CLASS, mxREAL);
    } else if (!strcmp("single", typeName)) {
        numBytes = mglSizeOfFloatArray(numElements);
        data = mxCreateNumericMatrix(rows, columns, mxSINGLE_CLASS, mxREAL);
    } else {
        if (verbose) {
            mexPrintf("(mglSocketRead) Unsupported data type %s, must be uint16, uint32, double, or single.\n", typeName);
        }
        mxFree(typeName);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    if (verbose) {
        mexPrintf("(mglSocketRead) Reading %dx%d elements of type %s as %d bytes on connectionSocketDescriptor %d.\n", rows, columns, mxGetClassName(data), numBytes, connectionSocketDescriptor);
    }

    // Read data from the socket into the Matlab data matrix.
    int readBytes = recv(connectionSocketDescriptor, mxGetPr(data), numBytes, MSG_WAITALL);
    if (verbose) {
        if (readBytes < numBytes) {
            mexPrintf("(mglSocketRead) Expected to read %d bytes but read %d, errno: %d\n", numBytes, readBytes, errno);
        } else {
            mexPrintf("(mglSocketRead) Read %d bytes.\n", readBytes);
        }
    }

    // Success -- return the data.
    plhs[0] = data;
}
