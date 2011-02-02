#ifdef documentation
=========================================================================

     program: mglGetSecs.c
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
          by: Jonas Larsson
        date: 09/20/06

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

  double currtime;
  double reftime=0.0;
  if (nrhs>0) 
    reftime = *(double*)mxGetPr(prhs[0]);
  
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  struct timeval tp;
  struct timezone tz;

  gettimeofday( &tp, &tz );
  currtime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;
#endif//__linux__

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
  // get current time
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  // convert microseconds to double
  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)currentTime.hi; 
  double lowerHalf = (double)currentTime.lo; 
  doubleValue = (upperHalf * twoPower32) + lowerHalf; 
  currtime = 0.000001*doubleValue;
#endif//__APPLE__
  
  //-----------------------------------------------------------------------------------///
// ******************************* Windows specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __WINDOWS__
  LARGE_INTEGER frequency, counterTime;

  // Get the hardware counter clock frequency.  We use this to convert the
  // counter clock time into seconds.
  if (QueryPerformanceFrequency(&frequency) == FALSE) {
	mexPrintf("(mglGetSecs) Could not get clock frequency.\n");
	return;
  }

  // Get the hardware clock value.
  if (QueryPerformanceCounter(&counterTime) == FALSE) {
	mexPrintf("(mglGetSecs) Could not get hardware counter time.\n");
	return;
  }

  // Convert the counter time into seconds.
  currtime = (double)counterTime.QuadPart / (double)frequency.QuadPart;
#endif
  
//-----------------------------------------------------------------------------------///
// ***************************** end os-specific code  ****************************** //
//-----------------------------------------------------------------------------------///

  // get time relative to reference time
  currtime -= reftime;

  // and return as a matlab double
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(plhs[0]) = currtime;
}
