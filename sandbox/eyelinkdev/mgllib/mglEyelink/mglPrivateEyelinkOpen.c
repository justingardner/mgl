#ifdef documentation
=========================================================================
program: mglPrivateEyelinkOpen.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkOpen(ipaddress, trackedwindow, displaywindow)


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

    if (nrhs<1 || nrhs>2) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkOpen");
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

    if(trackerip == NULL) 
        mexErrMsgTxt("Could not convert input to string.");

    if (set_eyelink_address(trackerip)==-1){
        mexErrMsgTxt("Could not parse IP addrss.");     
    }    
    

    /* **** TODO: Clean up the trackercontype code to use integer values? */
    // double *trackerconntype = 0;
    // // • 0, opens a connection with the eye tracker; 
    // // • 1, will create a dummy connection for simulation; 
    // // • -1, initializes the DLL but does not open a connection. 
    // *trackerconntype = 0; 
    
    // if (nrhs==2) {
    //     /* optional parameter which controlls the link connection type */
    //     if (mxGetM(prhs[1]) != 1 && mxGetN(prhs[1]) != 1){
    //         mexErrMsgTxt("Connection type must be an single value.");
    //     } else {
    //         /* should be a real data access call */
    //         trackerconntype = (double*)mxGetPr(prhs[1]);
    //         // if (trackerconntype[0] != -1 || trackerconntype[0] != 0 || trackerconntype[0] != 1) {
    //         //     mexErrMsgTxt("Connection type must be one of {-1, 0, 1}.");
    //         // }
    //     }
    // }

    if(open_eyelink_connection(0)) {
        /* abort if we can't open link*/
        mexErrMsgTxt("Connection failed: could not establish a link.\n");
    } else {
        mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker link established.\n");
        mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker IP %s.\n", trackerip);
        mxFree(trackerip);
        
    }
    
}


