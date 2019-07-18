#ifdef documentation
=========================================================================

     program: mglPrivateGetMouseEvent.c
          by: justin gardner
        date: 09/12/06
     purpose: return a key event
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id: mglPrivateGetMouseEvent.c,v 1.5 2006/10/20 22:37:34 jonas Exp $
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#ifdef __linux__
#include <sys/time.h>
#endif

///////////////////////////////
//   function declarations   //
///////////////////////////////
mxArray *makeOutputStructure(double **outptrX, double **outptrY, double **outptrButton, double **outptrWhen);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  // declare variables
  double waittime;
  double verbose = mglGetGlobalDouble("verbose");
  double *outptrX, *outptrY, *outptrButton, *outptrWhen;

  // check arguments
  if (nrhs==0) {
    waittime = 0.0;
  } else if (nrhs == 1) {
    // get the input argument
    if (mxGetPr(prhs[0]) != NULL)
      waittime = (int)*mxGetPr(prhs[0]);
    if (verbose)
      mexPrintf("(mglGetPrivateMouseEvent) Will wait for %f secs\n",waittime);
  }
  else {
    usageError("mglGetPrivateMouseEvent");
  }
  
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  // 64 bit version not implemented
  plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  mexPrintf("(mglGetPrivateMouseEvent) 64bit version not implemented\n");
  return;
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__cocoa__
  // get next event on queue
  UInt32 waitTicks = (UInt32) round(waittime * 60.15);
  EventRecord theEvent;
  EventMask theMask = mDownMask;
  // either return immediately or wait till we get an event
  if (waitTicks)
    WaitNextEvent(theMask,&theEvent, waitTicks,nil);
  else
    GetNextEvent(theMask,&theEvent);

  // set the fields
  plhs[0] = makeOutputStructure(&outptrX,&outptrY,&outptrButton,&outptrWhen);
  *outptrX = theEvent.where.h;
  *outptrY = theEvent.where.v;
  *outptrButton = (double)1; // no support for multiple buttons on Macs
  *outptrWhen = (double)TicksToEventTime(theEvent.when);
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
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

  // create output structure
  plhs[0] = makeOutputStructure(&outptrCharCode,&outptrKeyCode,&outptrKeyboard,&outptrWhen);
 
  if ( buttonPressed ) {
    // create the output structure
    *outptrX = (double)event.xbutton.x;
    *outptrY = (double)event.xbutton.y;
    *outptrButton = (double)event.xbutton.button; 
    *outptrWhen = (double)event.xkey.time*0.001;
    
  } else {
    // Query mouse position directly
    Window root_return, child_return;
    int win_x_return, win_y_return, root_x_return, root_y_return;
    unsigned int mask_return;
    XQueryPointer(dpy, win, &root_return, &child_return, &root_x_return, &root_y_return, &win_x_return, &win_y_return, &mask_return);

    *outptrX = (double)win_x_return;
    *outptrY = (double)win_y_return;
    *outptrButton = (double)0; 
    *outptrWhen = (double)starttime+currtime;
  }

#endif //__linux__
//-----------------------------------------------------------------------------------///
// ***************************** end os-specific code  ****************************** //
//-----------------------------------------------------------------------------------///
  
}

/////////////////////////////
//   makeOutputStructure   //
/////////////////////////////
mxArray *makeOutputStructure(double **outptrX, double **outptrY, double **outptrButton, double **outptrWhen)
{
  // create the output structure
  mxArray *plhs;
  const char *fieldNames[] =  {"x","y","button","when" };
  int outDims[2] = {1, 1};
  plhs = mxCreateStructArray(1,outDims,4,fieldNames);

  // set the fields
  mxSetField(plhs,0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrX = (double*)mxGetPr(mxGetField(plhs,0,"x"));

  mxSetField(plhs,0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrY = (double*)mxGetPr(mxGetField(plhs,0,"y"));

  mxSetField(plhs,0,"button",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrButton = (double*)mxGetPr(mxGetField(plhs,0,"button"));

  mxSetField(plhs,0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrWhen = (double*)mxGetPr(mxGetField(plhs,0,"when"));
  return(plhs);
}

