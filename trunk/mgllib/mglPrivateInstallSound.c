#ifdef documentation
=========================================================================

     program: mglInstallSound.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to install system sounds
       usage: mglInstallSound()

$Id: mglInstallSound.c 379 2008-12-31 03:56:53Z justin $
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This function takes a full filename to a sound file and 
// initializes any necessary data structures, returning
// an unsigned long identifier. For Mac cocoa this means
// to set up an NSSound object and return a pointer.
unsigned long installSound(char *filename);
// remove sound, takes the identifier returned from
// the above function and clears the object from memory.
// So, it can no longer be played.
void removeSound(unsigned long soundID);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  unsigned long soundID = 0;
  int i;

  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // with no arguments, uninstall all sounds
  if (nrhs == 0) {
    // get already installed sounds
    mxArray *sounds = mglGetGlobalField("sounds");
    if ((sounds != NULL) && (mxGetN(sounds)>0)){
      unsigned long *soundsPtr = (unsigned long*)mxGetPr(sounds);
      if (verbose) mexPrintf("(mglInstallSound) Uninstalling all sounds\n");
      // remove all the sounds
      for (i = 0; i < mxGetN(sounds); i++) {
	if (soundsPtr[i] != 0)
	  removeSound(soundsPtr[i]);
      }
      // and set sounds to empty
      sounds = mxCreateDoubleMatrix(0,0,mxREAL);
      mglSetGlobalField("sounds",sounds);
    }
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  } 
  // with a single argument, set sound to the file that is passed in
  else {
    char soundFilePath[2048];
    mxGetString(prhs[0],soundFilePath,2048);
    soundID = installSound(soundFilePath);
  }

  // Now save the soundID in global structure. This takes the ID (or pointer)
  // returned above and saves it in the global MGL structure
  if (soundID != 0) {
    // now keep the sound id in the MGL global
    mxArray *sounds = mglGetGlobalField("sounds");
    // check for null pointer, this means we have no sounds installed yet
    if ((sounds == NULL) || (mxGetN(sounds) <= 0)){
      // so create an array of 1 for installed sounds
      sounds = mxCreateDoubleMatrix(1,1,mxREAL);
      // and set the first elemet to the newly created sound
      unsigned long *soundsPtr = (unsigned long*)mxGetPr(sounds);
      soundsPtr[0] = soundID;
      // and save it in the global
      mglSetGlobalField("sounds",sounds);
      // return sound number
      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      double *outptr = (double*)mxGetPr(plhs[0]);
      outptr[0] = 1;
    }
    else {
      unsigned long *soundsPtr = (unsigned long*)mxGetPr(sounds);
      // so create a new array of length+1 for installed sounds
      mxArray *newSounds = mxCreateDoubleMatrix(1,mxGetN(sounds)+1,mxREAL);
      unsigned long *newSoundsPtr = (unsigned long*)mxGetPr(newSounds);
      // set the new array to the old values
      for (i = 0; i < mxGetN(sounds); i++)
	newSoundsPtr[i] = soundsPtr[i];
      // and set the first elemet to the newly created sound
      newSoundsPtr[i] = soundID;
      // and save it in the global
      mglSetGlobalField("sounds",newSounds);
      // return sound number
      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      double *outptr = (double*)mxGetPr(plhs[0]);
      outptr[0] = (double)i+1;
    }
  }
  else {
    // return sound number
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }

}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
///////////////////////////
//   cocoaInstallSound   //
///////////////////////////
unsigned long installSound(char *filename)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSString *filenameString = [[NSString alloc] initWithUTF8String:filename];
  NSSound *mySound;
  mySound = [[NSSound alloc] initWithContentsOfFile:filenameString byReference:NO];

  // drain memory
  [filenameString release];
  [pool drain];

  return((unsigned long)mySound);
}

//////////////////////////
//   cocoaRemoveSound   //
//////////////////////////
void removeSound(unsigned long soundID)
{
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // convert to pointer
  NSSound *mySound = (NSSound*)soundID;
  
  // print message
  if (verbose) mexPrintf("(mglInstallSound) Deallocating pointer %x with retain count: %i\n",soundID,[mySound retainCount]);

  // release
  [mySound release];

}
#else//__cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
////////////////////////////
//   carbonInstallSound   //
////////////////////////////
unsigned long installSound(char *filename)
{
  // create the ActionID for the sound
  SystemSoundActionID gSoundID = 0;
  FSRef soundFileRef;
  OSStatus err;
  err = FSPathMakeRef((unsigned char*)filename, &soundFileRef, NULL);
  if (noErr == err) {
    // system call to install the sound
    err = SystemSoundGetActionID(&soundFileRef, &gSoundID);
    if (noErr == err) {
      return((unsigned long)gSoundID);
    }
  }
  return(0);
}

///////////////////////////
//   carbonRemoveSound   //
///////////////////////////
void removeSound(unsigned long soundID)
{
  SystemSoundRemoveActionID((SystemSoundActionID)soundID);
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
unsigned long installSound(char *filename)
{
  mexPrintf("(mglInstallSound) Not implemented on linux\n");
  return 0;
}
void removeSound(unsigned long soundID)
{
  mexPrintf("(mglInstallSound) Not implemented on linux\n");
}
#endif//__linux__


//-----------------------------------------------------------------------------------///
// ****************************** Windows specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
unsigned long installSound(char *filename)
{
  mexPrintf("(mglInstallSound) Not implemented on Windows\n");
  return 0;
}
void removeSound(unsigned long soundID)
{
  mexPrintf("(mglInstallSound) Not implemented on Windows\n");
}
#endif

