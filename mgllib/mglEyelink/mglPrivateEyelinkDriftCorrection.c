#ifdef documentation
=========================================================================
    program: mglPrivateEyelinkDriftCorrection.c
    by:      eric dewitt and eli merriam
    date:    02/08/09
    copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
    purpose: Sets the eyetracker into setup mode for calibration, validation
    and drift correction. Allows for mgl based (local) calibration 
    and eyelink software (remote, on eyelink computer) based setup.
    Local setup allows for self calibration. Wrapper handles keyboard.
    You must specify display location for the camera graphics.
    usage:   mglPrivateEyelinkDriftCorrection([display_num])

    =========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mglPrivateEyelinkSetup.h"

#ifndef DRAW_OWN_TARGET
#define DRAW_OWN_TARGET 1
#endif
#ifndef ALLOW_SETUP
#define ALLOW_SETUP 0
#endif
/////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *inVec;
    int n, x, y;
    if (nrhs != 1) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkDriftCorrection");
        return;
    } else {
        n = mxGetN(prhs[0])*mxGetM(prhs[0]);
        if (n != 2) {
            mexErrMsgTxt("(mglPrivateEyelinkDriftCorrection) You must specify the position as [x y] in screen coords.");
        }
        inVec = (double*)mxGetPr(prhs[0]);
        x = (int)inVec[0];
        y = (int)inVec[1];
    }
    double *plhsData;
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    plhsData = mxGetPr(plhs[0]);
    
    // initialize the callbacks
    // init_expt_graphics();

    *plhsData = do_drift_correct(x, y, DRAW_OWN_TARGET, ALLOW_SETUP);

    // let everyone know that we're finished
    mexPrintf("(mglPrivateEyelinkDriftCorrection) Doing drift correction.\n");

}
// // This programs illustrates the use of eyelink_cal_message() 
// #include <eyelink.h> 
// char message[256]; 
// // Performs a drift correction 
// while(1) 
// { // Check link often so we can exit if tracker stopped 
// if(!eyelink_is_connected()) return ABORT_EXPT; 
// // Performs drift correction with target pre-drawn 
// error = do_drift_correct(SCRWIDTH/2, SCRHEIGHT/2, 1, 1); 
// // repeat if ESC was pressed to access Setup menu 
// if(error!=27) break; 
// } 
// // Retrieves and writes out the calibration result message 
// eyelink_cal_message(message); 
// eyemsg_printf(message); 
// 
// This program illustrates the use of do_drift_correction with drift correction target drawn by t 
// #include <eyelink.h> 
// int target_shown = 0; 
// while(1) 
// { 
// // Checks link often so we can exit if tracker stopped 
// if(!eyelink_is_connected()) 
// return ABORT_EXPT; 
// // If drift correct target is not drawn, we have to draw it here 
// if (draw_own_target && !target_shown) 
// { 
// // Code for drawing own drift correction target 
// target_shown = 1; 
// } 
// // Performs drift correction with target drawn in the center 
// error = do_drift_correct(SCRWIDTH/2, SCRHEIGHT/2, 
// draw_own_target, 1); 
// // repeat if ESC was pressed to access Setup menu 
// // Redawing the target may be necessary 
// if(error!=27) 
// break; 
// else 
// target_shown = 0; 
// } 
