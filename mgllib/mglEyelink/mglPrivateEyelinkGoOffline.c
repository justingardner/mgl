#ifdef documentation
=========================================================================
program: mglPrivateEyelinkGoOffline.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Places EyeLink tracker in off-line (idle) mode.
usage:   mglPrivateEyelinkGoOffline
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
#include <eyelink.h>

//////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 0) {/* What arguments should this take? */
    usageError("mglPrivateEyelinkGoOffline");
    return;
  }    
    
  // Checks whether we still have the connection to the tracker 
  if (eyelink_is_connected()) { 
    // Places EyeLink tracker in off-line (idle) mode 
    set_offline_mode();
  }
  else {
    mexErrMsgTxt("Link error occured.");
  }  
}
