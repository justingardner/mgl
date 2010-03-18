#ifdef documentation
=========================================================================
program: mglPrivateEyelinkCMDPrintF.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkCMDPrintF(message)


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
        usageError("mglPrivateEyelinkCMDPrintF");
        return;
    }
    
    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1)
        mexErrMsgTxt("Input must be a string.");

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
        mexErrMsgTxt("Input must be a row vector.");    
        
    char *message;
    mwSize buflen;

    /* get the length of the input string */
    buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    message = mxArrayToString(prhs[0]);
    
    UINT32 t = current_msec(); 
    int results, errormsg;
    char buf[256]; 
    
    // Sends command
    eyecmd_printf(message);
    
    // Waits for a maximum of 1000 msec 
    while(current_msec()-t < 1000) 
    { 
        // Checks for result from command execution 
        results = eyelink_command_result(); 
        // Used to get more information on tracker result 
        errormsg = eyelink_last_message(buf); 
        if (results == OK_RESULT) 
        { 
            eyemsg_printf("Command executed successfully: %s", errormsg?buf:""); 
            break; 
        } 
        else if (results!=NO_REPLY) 
        { 
            eyemsg_printf("Error in executing command: %s", errormsg?buf:"");
            mexPrintf(errormsg?buf:"");
            break; 
        } 
    }     
}


