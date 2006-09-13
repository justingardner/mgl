#ifdef documentation
=========================================================================

     program: mglGetMouse.c
          by: justin gardner
        date: 09/12/06
     purpose: return state of mouse buttons

$Id$
=========================================================================
#endif



/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 0) {
    usageError("mglGetMouse");
    return;
  }

#ifdef __APPLE__
  // get next event on queue
  EventRecord theEvent;
  EventMask theMask = mDownMask;

  // get the mouse position
  GetNextEvent(theMask,&theEvent);

  // create the output structure
  const char *fieldNames[] =  {"buttons","x","y" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);

  // set the position of the mouse
  double *outptr;
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
  *outptr = theEvent.where.h;

  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
  *outptr = theEvent.where.v;

  // set the button state
  mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"buttons"));
  *outptr = (double)GetCurrentButtonState();
#endif
#ifdef __linux__
  mexPrintf("(mglGetMouse) Not supported yet on linux\n");
  return;
#endif 
}

