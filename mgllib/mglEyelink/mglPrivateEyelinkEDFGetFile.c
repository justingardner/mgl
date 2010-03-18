#ifdef documentation
=========================================================================
program: mglPrivateEyelinkEDFGetFile.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkEDFGetFile(message)


=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
#include <eyelink.h>

/////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    
    if (nrhs<1) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkEDFGetFile");
        return;
    }
    
    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1) {
        mexPrintf("(mglPrivateEyelinkEDFGetFile) Input must be a string.\n");
	return;
    }
    
    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1) {
        mexPrintf("(mglPrivateEyelinkEDFGetFile) Input must be a row vector.\n");    
	return;
    }
    
    char *our_file_name;
    mwSize buflen;

    /* get the length of the input string */
    buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    our_file_name = mxArrayToString(prhs[0]);
    
    int result;
    mexPrintf("(mglPrivateEyelinkEDFGetFile) ");
    if (result = receive_data_file(our_file_name, our_file_name, 0)) {
        if (result == FILE_CANT_OPEN || result == FILE_XFER_ABORTED) {
	  mexPrintf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");    
	  mexPrintf("(mglPrivateEyelinkEDFGetFile) File transfer error.\n");    
	  mexPrintf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");    
        }
    } else {
        mexPrintf("\n.");
    }
    
}


