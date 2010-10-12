#ifdef documentation
=========================================================================
program: mglPrivateEyelinkClose.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkClose(ipaddress, trackedwindow, displaywindow)


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

  if (nrhs!=0) /* What arguments should this take? */
    {
      usageError("mglPrivateEyelinkClose");
      return;
    }
  
  // the close used to call close_eyelink_connection();
  // but that caused problems with the 64bit libraries (like, bad matlab crashing)
  // eyelink_close(1) seems to do the trick. -Eli, 9/30/2010
  //close_eyelink_connection();
  eyelink_close(1);
  // I don't believe we need this.
  // close_eyelink_system();
  mexPrintf("(mglPrivateEyelinkClose) MGL Eyelink tracker link closed.\n");
  
}


