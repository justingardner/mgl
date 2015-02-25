#ifdef documentation
=========================================================================

    program: mglPrivateSystemCheck.c
         by: justin gardner
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       date: 06/18/08
    purpose: Checks system for various issues. The input number specifies
             the check for a specific system. For now, what has been
             implemented is:

             1 = Keyboard and Mouse

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// Checks keyboard and mouse. Returns 1 if everything is ok. Returns 0 if not
int checkKeyboardMouse();

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int checkNumber = -1;

  // parse input arguments
  if ((nrhs>0) && (mxGetPr(prhs[0]) != NULL))
    checkNumber = (double) *mxGetPr( prhs[0] );
  
  // return value, default to false
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  double *outptr = (double*)mxGetPr(plhs[0]);
  outptr[0] = 0;

  // check different things dependent on checkNumber
  if (checkNumber == 1)
    outptr[0] = checkKeyboardMouse();
  else
    mexPrintf("(mglPrivateSystemCheck) Unknown system check value - should be a number specifying which system to chec\n");

}
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
int checkKeyboardMouse()
{
  if (AXAPIEnabled())
    return 1;
  else
    return 0;
}
#endif

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
int checkKeyboardMouse()
{
  return 1;
}
#endif//__linux__


//-----------------------------------------------------------------------------------///
// ****************************** Windows specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
int checkKeyboardMouse()
{
  return 1;
}
#endif

