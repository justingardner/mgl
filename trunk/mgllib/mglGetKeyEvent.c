#ifdef documentation
=========================================================================

     program: mglGetKeyEvent.c
          by: justin gardner
        date: 09/12/06
     purpose: return a key event
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

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
      mexPrintf("(mglGetKeyEvent) Will wait for %i ticks\n",waitTicks);
  }
  else {
    usageError("mglGetKeyEvent");
  }
  
#ifdef __APPLE__
  // get next event on queue
  EventRecord theEvent;
  EventMask theMask = keyDownMask;
  // either return immediately or wait till we get an event
  if (waitTicks)
    WaitNextEvent(theMask,&theEvent,waitTicks,nil);
  else
    GetNextEvent(theMask,&theEvent);

  // create the output structure
  const char *fieldNames[] =  {"charCode","keyCode","keyboard","when" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,4,fieldNames);

  // set the fields
  double *outptr;
  mxSetField(plhs[0],0,"charCode",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"charCode"));
  *outptr = (double)(theEvent.message & charCodeMask);

  mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"keyCode"));
  *outptr = (double)((theEvent.message & keyCodeMask)>>8);

  mxSetField(plhs[0],0,"keyboard",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"keyboard"));
  *outptr = (double)(theEvent.message>>16);

  mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
  *outptr = (double)TicksToEventTime(theEvent.when);
#endif

#ifdef __linux__
  mexPrintf("(mglGetKeyEvent) Not supported yet on linux\n");
  return;
#endif 
  
}

