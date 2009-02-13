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
    
    if (nrhs>0) /* What arguments should this take? */
    {
        usageError("mglEyelinkStopRecording");
        return;
    }

    stop_recording();

}


