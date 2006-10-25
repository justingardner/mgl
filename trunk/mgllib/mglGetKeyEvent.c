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
#ifdef __linux__
#include <sys/time.h>
#endif

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  double waittime;
  double verbose = mglGetGlobalDouble("verbose");
  // check arguments
  if (nrhs==0) {
    waittime = 0.0;
  } else if (nrhs == 1) {
    // get the input argument
    if (mxGetPr(prhs[0]) != NULL)
      waittime = *mxGetPr(prhs[0]);
    if (verbose)
      mexPrintf("(mglGetKeyEvent) Will wait for %f secs\n",waittime);
  }
  else {
    usageError("mglGetKeyEvent");
  }
  
#ifdef __APPLE__
  // get next event on queue
  UInt32 waitTicks = (UInt32) round(waittime * 60.15);
  EventRecord theEvent;
  EventMask theMask = keyDownMask;

  // either return immediately or wait till we get an event
  Boolean result;
  if (waitTicks)
    result=WaitNextEvent(theMask,&theEvent, waitTicks,nil);
  else
    result=GetNextEvent(theMask,&theEvent);
  
  if (!result && verbose)
    mexPrintf("no event\n");

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
  *outptr = (double)theEvent.when;
#endif

#ifdef __linux__
  
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    if (verbose) mexPrintf("No display found!\n");
    return;
  }
  Display * dpy=(Display *)dpyptr;
  int winptr=(int) mglGetGlobalDouble("XWindowPointer");
  Window win = *(Window *)winptr;
  XEvent event;

  Bool keyPressed=false;
  if (waittime>0.0) {
    struct timeval tp;
    struct timezone tz;

    double currtime=0.0;

    gettimeofday( &tp, &tz );
    double starttime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;

    do {
      //      keyPressed=XCheckTypedWindowEvent(dpy, win, KeyPress, &event);
      keyPressed=XCheckTypedEvent(dpy, KeyPress, &event);
      gettimeofday( &tp, &tz );
      currtime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001 - starttime;
    } while ( !keyPressed && currtime<waittime );
    
  } else {
    //    keyPressed=XCheckTypedWindowEvent(dpy, win, KeyPress, &event);
    keyPressed=XCheckTypedEvent(dpy, KeyPress, &event);
  }
  
  if ( keyPressed ) {
    // create the output structure
    const char *fieldNames[] =  {"charCode","keyCode","keyboard","when" };
    int outDims[2] = {1, 1};
    plhs[0] = mxCreateStructArray(1,outDims,4,fieldNames);
    
    // set the fields
    double *outptr;
    mxSetField(plhs[0],0,"charCode",mxCreateDoubleMatrix(1,1,mxREAL));
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"charCode"));
    *outptr = (double)*(XKeysymToString(XKeycodeToKeysym(dpy, event.xkey.keycode, 0))); // always returns first entry of keycode list
    
    mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"keyCode"));
    *outptr = (double)event.xkey.keycode;
    
    mxSetField(plhs[0],0,"keyboard",mxCreateDoubleMatrix(1,1,mxREAL));
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"keyboard"));
    *outptr = (double)event.xkey.state; // contains information about keyboard
    
    mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
    *outptr = (double)event.xkey.time*0.001;
    
  } else {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }

#endif 
  
}

