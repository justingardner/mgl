#ifdef documentation
=========================================================================

     program: mglFlush.c
     by: justin gardner; X support by Jonas Larsson
        date: 04/03/06

     Warning: if using mglFlush to keep timing, keep in mind that Matlab checks for license every 30s, screwing up timing at this interval. Installing a local copy of the license manager appears to solve problem, mostly.

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
  if (nrhs>0) {
    fullScreen = (int) *mxGetPr( prhs[0] );
  }

  
#ifdef __APPLE__ 
  
  if (fullScreen) {

    // get the current context
    CGLContextObj contextObj = CGLGetCurrentContext();

    // and flip the double buffered screen
    // this call waits for vertical blanking
    CGLFlushDrawable(contextObj); 
  } else {
    // run in a window: get agl context
    AGLContext contextObj=aglGetCurrentContext ();

    if (!contextObj) {
      printf("warning: no drawable context found\n");
    }
     
    // swap buffers
    aglSwapBuffers (contextObj);
  }

#endif

#ifdef __linux__

  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  glXSwapBuffers( dpy, glXGetCurrentDrawable() );

#endif

}
