#ifdef documentation
=========================================================================

     program: mglIsCursorVisible.c
          by: Christopher Broussard
        date: 02/15/11
   copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Returns whether or not the cursor is visible on any display.
       usage: mglIsCursorVisible

$Id: mglIsCursorVisible.c 444 2009-01-30 07:20:40Z chris $
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
bool isCursorVisible();

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 0) {
    usageError("mglIsCursorVisible");
    return;
  }

  plhs[0] = mxCreateDoubleScalar((double)isCursorVisible());
}

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
bool isCursorVisible()
{
  return (bool)CGCursorIsVisible();
}
#endif //__APPLE__
