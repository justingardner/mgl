#ifdef documentation
=========================================================================

     program: mglPrivateGetKeyEventc
          by: justin gardner
        date: 09/12/06
     purpose: return a key event
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id: mglPrivateGetKeyEventc,v 1.6 2006/10/25 18:14:46 justin Exp $
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
mxArray *makeOutputStructure(double **outptrCharCode, double **outptrKeyCode, double **outptrKeyboard, double **outptrWhen);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  // declare variables
  double waittime;
  double verbose = mglGetGlobalDouble("verbose");
  double *outptrCharCode,*outptrKeyCode,*outptrKeyboard,*outptrWhen;

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


//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  // 64 bit version not implemented
  plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  mexPrintf("(mglGetKeyEvent) 64bit version not implemented\n");
  return;
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else //__cocoa__
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
    mexPrintf("(mglGetKeyEvent) No event\n");

  if (!result) {
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
  }
  else {
      FlushEvents (theMask, 0);
      // set the output variables
      plhs[0] = makeOutputStructure(&outptrCharCode,&outptrKeyCode,&outptrKeyboard,&outptrWhen);
      *outptrCharCode = (double)(theEvent.message & charCodeMask);
      *outptrKeyCode = (double)((theEvent.message & keyCodeMask)>>8);
      *outptrKeyboard = (double)(theEvent.message>>16);
      *outptrWhen = (double)theEvent.when;      
  }
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
    // set the fields
    plhs[0] = makeOutputStructure(&outptrCharCode,&outptrKeyCode,&outptrKeyboard,&outptrWhen);
    *outptrCharCode = (double)*(XKeysymToString(XKeycodeToKeysym(dpy, event.xkey.keycode, 0))); // always returns first entry of keycode list
    *outptrKeyCode = (double)event.xkey.keycode;
    *outptrKeyboard = (double)event.xkey.state; // contains information about keyboard
    *outptrWhen = (double)event.xkey.time*0.001;
    
  } else {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
#endif //__linux__
//-----------------------------------------------------------------------------------///
// ***************************** end os-specific code  ****************************** //
//-----------------------------------------------------------------------------------///
}


/////////////////////////////
//   makeOutputStructure   //
/////////////////////////////
mxArray *makeOutputStructure(double **outptrCharCode, double **outptrKeyCode, double **outptrKeyboard, double **outptrWhen)
{
  // create the output structure
  mxArray *plhs;
  const char *fieldNames[] =  {"charCode","keyCode","keyboard","when" };
  int outDims[2] = {1, 1};
  plhs = mxCreateStructArray(1,outDims,4,fieldNames);
  
  // Create the output fields
  mxSetField(plhs,0,"charCode",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrCharCode = (double*)mxGetPr(mxGetField(plhs,0,"charCode"));

  mxSetField(plhs,0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrKeyCode = (double*)mxGetPr(mxGetField(plhs,0,"keyCode"));

  mxSetField(plhs,0,"keyboard",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrKeyboard = (double*)mxGetPr(mxGetField(plhs,0,"keyboard"));

  mxSetField(plhs,0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
  *outptrWhen = (double*)mxGetPr(mxGetField(plhs,0,"when"));

  return(plhs);
}
