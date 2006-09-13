#ifdef documentation
=========================================================================

     program: mglGetMouseEvent.c
          by: justin gardner
        date: 09/12/06
     purpose: return a mouse down event

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
  UInt32 waitTicks = 0;
  double verbose = mglGetGlobalDouble("verbose");
  // check arguments
  if (nrhs == 0) {
    waitTicks = 0;
  }
  else if (nrhs == 1) {
    // get the input argument
    if (mxGetPr(prhs[0]) != NULL)
      waitTicks = (UInt32)*mxGetPr(prhs[0]);
    if (verbose)
      mexPrintf("(mglGetMouseEvent) Will wait for %i ticks\n",waitTicks);
  }
  else {
    usageError("mglGetMouseEvent");
  }

#ifdef __APPLE__  
  // get next event on queue
  EventRecord theEvent;
  EventMask theMask = mDownMask;

  // either return immediately or wait till we get an event
  if (waitTicks)
    WaitNextEvent(theMask,&theEvent,waitTicks,nil);
  else
    GetNextEvent(theMask,&theEvent);

  // create the output structure
  const char *fieldNames[] =  {"x","y","when" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);

  // set the fields
  double *outptr;
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
  *outptr = theEvent.where.h;

  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
  *outptr = theEvent.where.v;

  mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
  *outptr = (double)theEvent.when;
#endif

#ifdef __linux__
  mexPrintf("(mglGetMouseEvent) Not supported yet on linux\n");
  return;
#endif 
}

