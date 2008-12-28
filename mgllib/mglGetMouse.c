#ifdef documentation
=========================================================================

     program: mglGetMouse.c
          by: justin gardner
        date: 09/12/06
     purpose: return state of mouse buttons
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
  if (nrhs != 0) {
    usageError("mglGetMouse");
    return;
  }

  // create the output structure
  const char *fieldNames[] =  {"buttons","x","y" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,3,fieldNames);

  // and the field for X
  double *outptrX,*outptrY,*outptrButton;
  mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrX = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));

  // and the field for Y
  mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrY = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));

  // and the field for buttons
  mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,1,mxREAL));
  outptrButton = (double*)mxGetPr(mxGetField(plhs[0],0,"buttons"));

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  NSPoint mouseLocation = [NSEvent mouseLocation];

  // set the button state
  *outptrButton = (double)GetCurrentButtonState();
  *outptrX = mouseLocation.x;
  *outptrY = mouseLocation.y;
  return;
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else// __cocoa__
  // The following code does not work on 64bit since it relies on events
  // get next event on queue
  EventRecord theEvent;
  EventMask theMask = mDownMask;

  // get the mouse position
  GetNextEvent(theMask,&theEvent);

  // set the position of the mouse
  *outptrX = theEvent.where.h;
  *outptrY = theEvent.where.v;

#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  *outptrButton = -1;
  *outptrX = -1;
  *outptrY = -1;
  mexPrintf("(mglGetMouse) Not supported yet on linux\n");
  return;
#endif //__linux__
}

