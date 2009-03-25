#ifdef documentation
=========================================================================
program: mglEyelinkRecordingCheck.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: check the eyelink recording status 
         
usage:   mglEyelinkRecordingCheck()


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
        usageError("mglEyelinkCheckRecording");
        return;
    }
    double *plhsData;
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    plhsData = mxGetPr(plhs[0]);
    
    *plhsData =  (double)check_recording();

}


