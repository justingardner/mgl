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

    if (nrhs!=1) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkOpen");
        return;
    }    
    
    // Checks whether we still have the connection to the tracker 
    if(eyelink_is_connected()) 
    { 
    // Places EyeLink tracker in off-line (idle) mode 
        set_offline_mode(); 
    }
    /* **** TODO: Clean up the trackercontype code to use integer values? */
    double *trackermode = 0;
    
    /* optional parameter which controlls the link connection type */
    if (mxGetM(prhs[1]) != 1 && mxGetN(prhs[1]) != 1){
        mexErrMsgTxt("Connection type must be an single value.");
    } else {
        /* should be a real data access call */
        trackermode = (double*)mxGetPr(prhs[1]);
        // if (trackermode[0] != -1 || trackermode[0] != 0 || trackermode[0] != 1) {
        //     mexErrMsgTxt("Connection type must be one of {-1, 0, 1}.");
        // }
    }
    
    switch (trackermode[0]) {
        case 0:
            set_offline_mode()
        case 1:
            
    }
    
    if trackermode[0] == 1 {
        
    }
    
    if(open_eyelink_connection(trackermode[0])) {
        /* abort if we can't open link*/
        mexErrMsgTxt("Connection failed: could not establish a link.\n");
    } else {
        mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker link established.\n");
        mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker IP %s.\n", trackerip);
        mxFree(trackerip);
        
    }
    
}


