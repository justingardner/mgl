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
  // setup output argument
  double *outptr;
  if (nlhs == 1){
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    outptr = mxGetPr(plhs[0]);
    *outptr = 0;
  }

  // lock this function
  mexCallMATLAB(0,NULL,0,NULL,"mlock");

  if (nrhs<1 || nrhs>2) /* What arguments should this take? */
    {
      usageError("mglPrivateEyelinkOpen");
      return;
    }

  /* input must be a string */
  if ( mxIsChar(prhs[0]) != 1) {
    mexPrintf("Input must be a string.\n");
    return;
  }

  /* input must be a row vector */
  if (mxGetM(prhs[0])!=1) {
    mexPrintf("Input must be a row vector.\n");    
    return;
  }
        
  char *trackerip;
  mwSize buflen;

  /* get the length of the input string */
  buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;

  /* copy the string data from prhs[0] into a C string input_ buf.    */
  trackerip = mxArrayToString(prhs[0]);

  if(trackerip == NULL) {
    mexPrintf("Could not convert input to string.\n");
    return;
  }

  if (set_eyelink_address(trackerip)==-1){
    mexPrintf("Could not parse IP addrss.\n");     
    return;
  }    
    

  /* **** TODO: Clean up the trackercontype code to use integer values? */
  int trackerconntype = 0;
  // • 0, opens a connection with the eye tracker; 
  // • 1, will create a dummy connection for simulation; 
  // • -1, initializes the DLL but does not open a connection. 
    
  if (nrhs==2) {
    /* optional parameter which controlls the link connection type */
    if (mxGetM(prhs[1]) != 1 && mxGetN(prhs[1]) != 1){
      mexPrintf("Connection type must be an single value.\n");
      return;
    } else {
      /* should be a real data access call */
      trackerconntype = (int)*mxGetPr(prhs[1]);
      mexPrintf("(mglPrivateEyelinkOpen) Connection type is %d\n", trackerconntype);
      if (trackerconntype != -1 && trackerconntype != 0 && trackerconntype != 1) {
	mexPrintf("Connection type must be one of {-1, 0, 1}.\n");
	return;
      }
    }
  }

  if(open_eyelink_connection(trackerconntype)) {
    /* abort if we can't open link*/
    mexPrintf("Connection failed: could not establish a link.\n");
    return;
  } else {
    mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker link established.\n");
    mexPrintf("(mglPrivateEyelinkOpen) MGL Eyelink tracker IP %s.\n", trackerip);
    mxFree(trackerip);
    // set output argument
    if (nlhs == 1)*outptr = 1;
  }
    
}


