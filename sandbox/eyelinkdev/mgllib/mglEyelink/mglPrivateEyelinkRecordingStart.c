#ifdef documentation
=========================================================================
    program: mglEyelinkRecordingStart.c
    by:      eric dewitt and eli merriam
    date:    02/08/09
    copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
    purpose: mex function to open a connection to an Eyelink tracker and configure
    it for use with the specificed mgl window
    usage:   mglEyelinkRecordingStart(message)


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

    if (nrhs>1) /* What arguments should this take? */
    {
        usageError("mglEyelinkRecordingStart");
        return;
    }

    int edf_samples = 1, edf_events = 1, link_samples = 1, link_events = 1;

    if (nrhs==1) {
        int n;
        n = (mxGetN(prhs[0])*mxGetM(prhs[0]));
        if (n != 4) {
            mexErrMsgTxt("Specify data to record with a logical array: [ edf_samples, edf_events, link_samples, link_events ]");
        }
        if (mxIsLogical(prhs[0])) {
            mxLogical *toRecordL = mxGetLogicals(prhs[0]);
            edf_samples = (int)toRecordL[0];
            edf_events = (int)toRecordL[1];
            link_samples = (int)toRecordL[2];
            link_events = (int)toRecordL[3];
        } else {
            // could bitwise or and verify that inputs are logical
            double* toRecord = mxGetPr(prhs[0]);
            edf_samples = (int)toRecord[0];
            edf_events = (int)toRecord[1];
            link_samples = (int)toRecord[2];
            link_events = (int)toRecord[3];
        }
    } else {
        mexPrintf("(mglEyelinkRecordingStart) Using default values.");
    }

    mexPrintf("(mglEyelinkRecordingStart) Recording:  edf_samples = %d, edf_events = %d, link_samples = %d, link_events = %d.\n", 
        edf_samples, edf_events, link_samples, link_events);

    if(start_recording(edf_samples, edf_events, link_samples, link_events)!= 0) 
    {
        mexErrMsgTxt("Start recording failed");
    }

}


