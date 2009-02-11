#ifdef documentation
=========================================================================
program: mglPrivateEyelinkEDFPrintF.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkEDFPrintF(message)


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
        usageError("mglPrivateEyelinkClose");
        return;
    }
    
    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1)
        mexErrMsgTxt("Input must be a string.");

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
        mexErrMsgTxt("Input must be a row vector.");    
        
    char *trackerip;
    mwSize buflen;

    /* get the length of the input string */
    buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    trackerip = mxArrayToString(prhs[0]);
    
    eyecmd_printf(message, ... );
    
}


