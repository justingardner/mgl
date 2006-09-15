#ifdef documentation
=========================================================================

     program: mglFlush.c
     by: justin gardner; X support by Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

     Warning: if using mglFlush to keep timing, keep in mind that Matlab checks for license every 30s, screwing up timing at this interval. Installing a local copy of the license manager appears to solve problem, mostly.

$Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int fullScreen=1;
  if (nrhs!=0) {
    usageError("mglFlush");
    return;
  }

  
#ifdef __APPLE__ 
  double displayNumber = mglGetGlobalDouble("displayNumber");
  
  if (displayNumber > 0) {

    // get the current context
    CGLContextObj contextObj = CGLGetCurrentContext();

    // and flip the double buffered screen
    // this call waits for vertical blanking
    CGLFlushDrawable(contextObj); 
  }
  else if (displayNumber == 0) {
    // run in a window: get agl context
    AGLContext contextObj=aglGetCurrentContext ();

    if (!contextObj) {
      printf("warning: no drawable context found\n");
    }

    // there seems to be some interaction with the matlab desktop
    // in which the windowed graphics context crashes. The crash
    // appears to occur in handeling a FlushAllWindows call. This
    // causes a EXC_BAD_ACCESS error (something like a seg fault).
    // I think this is occuring because of some interaction with
    // multiple threads running--presumably, the window is being
    // updated by one thread which called FlushAllBuffers and
    // also by our call (either here, or in ShowWindow or HideWindow).
    // the multiple accesses make Mac unhappy. 
    // Don't know how to deal with this problem. I have tried to 
    // check here that QDDone has finished, but it doesn't seem to make a
    // difference.
    // other things were tried too, like checking for events (assuming
    // that maybe the OS got stuck with events that were never processed
    // but none of that helped).
    // The only thing that does seem to help is not closing and opening
    // the window.
    //AGLDrawable drawableObj = aglGetDrawable(contextObj);
    //    QDFlushPortBuffer(drawableObj,NULL);
    // swap buffers
    //    if (QDDone(drawableObj))
    aglSwapBuffers (contextObj);
    
    // get an event
    //    EventRef theEvent;
    //    EventTargetRef theTarget;
    //    theTarget = GetEventDispatcherTarget();
    //    if (ReceiveNextEvent(0,NULL,3/60,true,&theEvent) == noErr) {
    //      SendEventToEventTarget(theEvent,theTarget);
    //      ReleaseEvent(theEvent);
    //    }
    //    EventRecord theEventRecord;
    //    EventMask theMask = everyEvent;
    //    WaitNextEvent(theMask,&theEventRecord,3,nil);
  }

#endif

#ifdef __linux__

  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  glXSwapBuffers( dpy, glXGetCurrentDrawable() );

#endif

}
