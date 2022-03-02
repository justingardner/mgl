#ifdef documentation
=========================================================================

  program: mglSocketCommandTypes.c
       by: Ben Heasly
     date: 03/02/2022
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to get mglMetal supported commands and data types
    usage: [commands, types] = mglSocketCommandTypes()

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include "mglCommandTypes.h"

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Expose a handy struct of mglMetal command names and uint16 codes.
    int nCommands = sizeof(mglCommandCodes) / sizeof(mglCommandCodes[0]);
    plhs[0] = mxCreateStructMatrix(1, 1, nCommands, mglCommandNames);
    for (int i = 0; i < nCommands; i++) {
        mxArray* commandCode = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
        mxUint16* dataPr = (mxUint16*) mxGetPr(commandCode);
        dataPr[0] = mglCommandCodes[i];
        mxSetField(plhs[0], 0, mglCommandNames[i], commandCode);
    }

    // Expose a handy struct of supported array types and element sizes.
    const char *typeNames[] = {"uint16", "uint32", "double", "single"};
    plhs[1] = mxCreateStructMatrix(1, 1, 4, typeNames);
    mxSetField(plhs[1], 0, "uint16", mxCreateDoubleScalar(mglSizeOfCommandCodeArray(1)));
    mxSetField(plhs[1], 0, "uint32", mxCreateDoubleScalar(mglSizeOfUInt32Array(1)));
    mxSetField(plhs[1], 0, "double", mxCreateDoubleScalar(mglSizeOfDoubleArray(1)));
    mxSetField(plhs[1], 0, "single", mxCreateDoubleScalar(mglSizeOfFloatArray(1)));
}
