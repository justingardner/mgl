#ifdef documentation
=========================================================================

     program: mglPrivateDeleteSound.c
          by: justin gardner
        date: 08/15/2015
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to delete a previously allocated sound
       usage: mglPrivateDeleteSound()

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
// installSound in mglInstallSound.c and delete that sound. In Mac
// cocoa this is a pointer to a NSSound object.
void deleteSound(unsigned long soundNum);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // delete the sound (no checking here since that is all done in the m file)
  deleteSound(*(unsigned long *)mxGetPr(prhs[0]));
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
////////////////////////
//   cocoaDeleteSound   //
////////////////////////
void deleteSound(unsigned long soundID)
{
  if (soundID != 0) {
    // convert pointer
    NSSound *mySound;
    mySound = (NSSound*)soundID;
    // and free it up
    [mySound release];
  }
}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__cocoa__
////////////////////////
//   carbonDeleteSound  //
////////////////////////
void deleteSound(unsigned long soundID)
{
  mexPrintf("(mglPrivateDeleteSound) Not implemented\n");
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
void deleteSound(unsigned long soundID)
{
  mexPrintf("(mglPrivateDeleteSound) Not implemented\n");
}
#endif//__linux__
