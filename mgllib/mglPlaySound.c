#ifdef documentation
=========================================================================

     program: mglPlaySound.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to play system sounds
       usage: mglPlaySound()

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
#ifdef __APPLE__
  // play system alert sound with no arguments
  if (nrhs == 0) {
    AlertSoundPlay();
  }
  else {
    // get the number
    int soundNum = (int)mxGetScalar(prhs[0]);
    if (mglIsGlobal("sounds") > 0) {
      // get the global sounds vector
      mxArray *sounds = mglGetGlobalField("sounds");
      int *soundsPtr = (int*)mxGetPr(sounds);
      // if we have the called for sound, then play it
      if ((mxGetN(sounds) >= soundNum) && (soundNum > 0))
	SystemSoundPlay(soundsPtr[soundNum-1]);
      else
	AlertSoundPlay();
     }
  }
#endif
}

