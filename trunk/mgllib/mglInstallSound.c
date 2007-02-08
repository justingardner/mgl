#ifdef documentation
=========================================================================

     program: mglInstallSound.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to install system sounds
       usage: mglInstallSound()

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
  int i;
  // with no arguments, uninstall all sounds
  if (nrhs == 0) {
    // get already installed sounds
    mxArray *sounds = mglGetGlobalField("sounds");
    if (sounds != NULL) {
      int *soundsPtr = (int*)mxGetPr(sounds);
      // remove all the sounds
      for (i = 0; i < mxGetN(sounds); i++) {
	SystemSoundRemoveActionID(soundsPtr[i]);      
      }
      // and set sounds to empty
      mwSize ndim, dims[2];
      ndim = 2;dims[0] = 0;dims[1] = 0;
      sounds = mxCreateNumericArray(ndim,dims,mxINT32_CLASS,mxREAL);
      mglSetGlobalField("sounds",sounds);
    }
  } 
  // with a single argument, set sound to the file that is passed in
  else {
    // create the ActionID for the sound
    SystemSoundActionID gSoundID = 0;
    char soundFilePath[2048];
    mxGetString(prhs[0],soundFilePath,2048);
    FSRef soundFileRef;
    OSStatus err;
    err = FSPathMakeRef(soundFilePath, &soundFileRef, NULL);
    if (noErr == err) {
      // system call to install the sound
      err = SystemSoundGetActionID(&soundFileRef, &gSoundID);

      // now keep the sound id in the MGL global
      mxArray *sounds = mglGetGlobalField("sounds");
      // check for null pointer, this means we have no sounds installed yet
      if (sounds == NULL) {
	// so create an array of 1 for installed sounds
	mwSize ndim, dims[2];
	ndim = 2;dims[0] = 1;dims[1] = 1;
	sounds = mxCreateNumericArray(ndim,dims,mxINT32_CLASS,mxREAL);
	// and set the first elemet to the newly created sound
	int *soundsPtr = (int*)mxGetPr(sounds);
	soundsPtr[0] = gSoundID;
	// and save it in the global
	mglSetGlobalField("sounds",sounds);
	// return sound number
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	double *outptr = (double*)mxGetPr(plhs[0]);
	outptr[0] = 1;
      }
      else {
	int *soundsPtr = (int*)mxGetPr(sounds);
	// so create a new array of length+1 for installed sounds
	mwSize ndim, dims[2];
	ndim = 2;dims[0] = 1;dims[1] = mxGetN(sounds)+1;
	mxArray *newSounds = mxCreateNumericArray(ndim,dims,mxINT32_CLASS,mxREAL);
	int *newSoundsPtr = (int*)mxGetPr(newSounds);
	// set the new array to the old values
	for (i = 0; i < mxGetN(sounds); i++)
	  newSoundsPtr[i] = soundsPtr[i];
	// and set the first elemet to the newly created sound
	newSoundsPtr[i] = gSoundID;
	// and save it in the global
	mglSetGlobalField("sounds",newSounds);
	// return sound number
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	double *outptr = (double*)mxGetPr(plhs[0]);
	outptr[0] = (double)i+1;
      }
    }
  }
#endif
}

