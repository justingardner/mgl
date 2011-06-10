#ifdef documentation
=========================================================================
program: mglEyelinkIsConnected.c
by:      Christopher Broussard
date:    01/22/10
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Mex function to check the connection to an EyeLink tracker.
usage:   mglEyelinkIsConnected


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
	INT16 connectionStatus;
	
	// Get the connection status.
	connectionStatus = eyelink_is_connected();
  
	// Stick the result into the return array.
	plhs[0] = mxCreateDoubleScalar((double)connectionStatus);
}
