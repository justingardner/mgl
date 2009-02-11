#ifdef documentation
=========================================================================
program: mglPrivateEyelinkEDFPrintF.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkEDFPrintF(message)


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

    if (nrhs!=1) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkClose");
        return;
    }

    close_eyelink_connection();
    mexPrintf("(mglPrivateEyelinkClose) MGL Eyelink tracker link closed.\n");
    
}


