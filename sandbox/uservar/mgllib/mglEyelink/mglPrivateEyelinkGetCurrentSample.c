#ifdef documentation
=========================================================================
program: mglPrivateEyelinkGetCurrentSample.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to get the 
usage:   mglPrivateEyelinkGetCurrentSample()


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
        usageError("mglPrivateEyelinkGetCurrentSample");
        return;
    }
    
    // Should this be done every time we try to get a sample? Do we
    // pass in the eye_used? Should we be able to test both eyes
    // (if availible) for valid samples (test one, if ok, exit, else
    // test the other)?
    int eye_used = 0; // indicates which eye’s data to display 
    // Determines which eye(s) are available 
    eye_used = eyelink_eye_available(); 
    
    // Selects eye, add annotation to EDF file 
    switch(eye_used) 
    { 
        case RIGHT_EYE: 
            eyemsg_printf("EYE_USED 1 RIGHT"); 
            break; 
        case BINOCULAR: // both eye’s data present: use left eye only 
            eye_used = LEFT_EYE; 
            eyemsg_printf("EYE_USED 0 LEFT"); 
        case LEFT_EYE: 
            eyemsg_printf("EYE_USED 0 LEFT"); 
            break; 
    } 
        
    // Get a sample, should this be a while loop? It could look forever...
    if(eyelink_newest_float_sample(NULL)>0) // check for new sample update 
    { 
        ALLF_DATA evt; // buffer to hold sample and event data 
        float x, y; // gaze position 
        
        eyelink_newest_float_sample(&evt); // get the sample 
        x = evt.fs.gx[eye_used]; // yes: get gaze position from sample 
        y = evt.fs.gy[eye_used]; 

        double *plhsData;
        plhs[0] = mxCreateDoubleMatrix(1,2,mxREAL);
        plhsData = mxGetPr(plhs[0]);

        // make sure pupil is present 
        if(x!=MISSING_DATA && y!=MISSING_DATA && evt.fs.pa[eye_used]>0) 
        {            
            plhsData[0] = (double)x;
            plhsData[1] = (double)y;
        } 
        else 
        {
            // sample exists but has no pupil so we return NaN
            plhsData[0] = mxGetNaN();
            plhsData[1] = mxGetNaN();
        }
    } else {
        // Return empty array?
        mwSize ndim = 2;
        mwSize dims[2] = {0, 0};
        plhs[0] = mxCreateNumericArray(ndim,dims,mxDOUBLE_CLASS,mxREAL);        
    }

}


