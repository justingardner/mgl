#ifdef documentation
=========================================================================

     program: mglPlaySound.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to play system sounds
       usage: mglPlaySound()

$Id: mglPlaySound.c,v 1.2 2007/02/08 17:20:56 justin Exp $
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This function takes the identifier returned from the functions
// installSound in mglInstallSound.c and plays that sound. In Mac
// cocoa this is a pointer to a NSSound object.
void playSound(unsigned long soundNum);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // play system alert sound with no arguments
  if (nrhs == 0) {
    playSound(0);
  }
  else {
    // get the number
    int soundNum = (int)mxGetScalar(prhs[0]);
    if (mglIsGlobal("sounds") > 0) {
      // get the global sounds vector
      mxArray *sounds = mglGetGlobalField("sounds");
      unsigned long *soundsPtr = (unsigned long*)mxGetPr(sounds);
      // if we have the called for sound, then play it
      if ((mxGetN(sounds) >= soundNum) && (soundNum > 0))
	playSound(soundsPtr[soundNum-1]);
      else
	playSound(0);
     }
  }
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
////////////////////////
//   cocoaPlaySound   //
////////////////////////
void playSound(unsigned long soundID)
{
  if (soundID == 0) {
    mexPrintf("(mglPlaySound) No sound\n");
    NSBeep();
  }
  else {
    NSSound *mySound;
    mySound = (NSSound*)soundID;
    [mySound play];
  }
}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__cocoa__
////////////////////////
//   carbonPlaySound  //
////////////////////////
void playSound(unsigned long soundID)
{
  if (soundID == 0)
    AlertSoundPlay();
  else
    SystemSoundPlay(soundID);
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
void playSound(unsigned long soundID)
{
  mexPrintf("(mglPrivatePlaySound) Not implemented\n");
}
#endif//__linux__
