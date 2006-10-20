#ifdef documentation
=========================================================================

     program: mglGetMouseEvent.c
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
      waittime = (int)*mxGetPr(prhs[0]);
    if (verbose)
      mexPrintf("(mglGetMouseEvent) Will wait for %f secs\n",waittime);
  }
  else {
    usageError("mglGetMouseEvent");
  }
  
#ifdef __APPLE__
  // get next event on queue
  UInt32 waitTicks = (UInt32) round(waittime * 60.15);
  EventRecord theEvent;
  EventMask theMask = mDownMask;
  // either return immediately or wait till we get an event
  if (waitTicks)
    WaitNextEvent(theMask,&theEvent, waitTicks,nil);
  else
    GetNextEvent(theMask,&theEvent);

  // create the output structure
  const char *fieldNames[] =  {"x","y","button","when" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,4,fieldNames);

  // set the fields
  double *outptr;
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
  *outptr = theEvent.where.h;

  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
  *outptr = theEvent.where.v;

  mxSetField(plhs[0],0,"button",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"button"));
  *outptr = (double)1; // no support for multiple buttons on Macs

  mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
  *outptr = (double)TicksToEventTime(theEvent.when);
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

  Bool buttonPressed=false;
  struct timeval tp;
  struct timezone tz;
  
  gettimeofday( &tp, &tz );
  double starttime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;

  double currtime=0.0;
  if (waittime>0.0) {
    do {
      buttonPressed=XCheckTypedWindowEvent(dpy, win, ButtonPress, &event);
      gettimeofday( &tp, &tz );
      currtime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001 - starttime;
    } while ( !buttonPressed && currtime<waittime );    
  } else {
    buttonPressed=XCheckTypedWindowEvent(dpy, win, ButtonPress, &event);
  }
  
  const char *fieldNames[] =  {"x","y","button","when" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,4,fieldNames);
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL)); 
  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  mxSetField(plhs[0],0,"button",mxCreateDoubleMatrix(1,1,mxREAL));
  mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
 
  // set the fields
  double *outptr;

  if ( buttonPressed ) {
    // create the output structure
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
    *outptr = (double)event.xbutton.x;
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
    *outptr = (double)event.xbutton.y;
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"button"));
    *outptr = (double)event.xbutton.button; 
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
    *outptr = (double)event.xkey.time*0.001;
    
  } else {
    // Query mouse position directly
    Window root_return, child_return;
    int win_x_return, win_y_return, root_x_return, root_y_return;
    unsigned int mask_return;
    XQueryPointer(dpy, win, &root_return, &child_return, &root_x_return, &root_y_return, &win_x_return, &win_y_return, &mask_return);
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
    *outptr = (double)win_x_return;
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
    *outptr = (double)win_y_return;
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"button"));
    *outptr = (double)0; 
    
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
    *outptr = (double)starttime+currtime;
    
    
  }

#endif 
  
}

