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
#ifdef __linux__
#include <sys/time.h>
#endif

///////////////////
//   functions   //
///////////////////
#ifdef __APPLE__
double ConvertMicrosecondsToDouble(UnsignedWidePtr microsecondsValue)
{ 
  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)microsecondsValue->hi; 
  double lowerHalf = (double)microsecondsValue->lo; 
  
  doubleValue = (upperHalf * twoPower32) + lowerHalf; 
  return doubleValue;
}
#endif


//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  double currtime;
  double reftime=0.0;
  if (nrhs>0) 
    reftime = *(double*)mxGetPr(prhs[0]);
  
#ifdef __linux__
  struct timeval tp;
  struct timezone tz;

  gettimeofday( &tp, &tz );
  currtime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;
#endif

#ifdef __APPLE__
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  currtime = 0.000001*ConvertMicrosecondsToDouble(&currentTime); 
#endif

  currtime -= reftime;

  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *mxGetPr(plhs[0]) = currtime;

}
