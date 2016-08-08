#ifdef documentation
=========================================================================

     program: mglPrivateVolume.c
          by: justin gardner
        date: 08/05/2016
  copyright: (c) 2016 Justin Gardner (GPL see mgl/COPYING)
     purpose: mex function to set volume
       usage: mglPrivateVolume()

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// OS specific call that sets volume to a value between 0 and 1
// volume is an array with number of channels length. If numChannels
// is 0, then volume will contain one value to which all
// channels will be set. 
void setVolume(double *volume, int numChannels);
// getVolume gets the volume of all channels, reporting number
// of channels (and the length of volume) in numChannels.
// volume must be allocated within getVolume and will
// be freed using free 
int getVolume(double **volume,int *numChannels);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // declare variables
  int iChannel;
  double *volume;
  int numChannels;
    
  if (nrhs == 1) {
    // first get current volume settings (to get number of channels)
    if (!getVolume(&volume,&numChannels)) return;
    // check that the desired number of channels to set
    // is either 1 or the number of channels that
    // the device has
    int numSetChannels = mxGetN(prhs[0]);
    if ((numSetChannels != 1) && (numSetChannels != numChannels)) {
      mexPrintf("(mglPrivateVolume) Number of channels to set volume should be either 1 (all channels) or %i\n",numChannels);
      // return NULL on error
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    // make an array with necessary volume levels
    if (numSetChannels == 1) {
      // copy volume settings into volume - one for each channel
      for (iChannel = 0; iChannel < numChannels; iChannel++)
	volume[iChannel] = (double)mxGetScalar(prhs[0]);
    }
    else {
      // use input double volume setting
      free(volume);
      volume = (double *)mxGetPr(prhs[0]);
    }
    // check bounds
    for (iChannel = 0; iChannel < numChannels; iChannel++) {
      // check lower bound
      if (volume[iChannel] < 0.0) {
	mexPrintf("(mglPrivateVolume) Volume setting must be between 0 and 1 (setting to 0)\n");
	volume[iChannel] = 0.0;
      }
      if (volume[iChannel] > 1.0) {
	mexPrintf("(mglPrivateVolume) Volume setting must be between 0 and 1 (setting to 1)\n");
	volume[iChannel] = 1.0;
      }
    }

    // set the volume with os-specific call
    setVolume(volume,numChannels);

    // free volume settings if necessary
    if (numSetChannels == 1) free(volume);
  }
  else if (nrhs != 0) {
    mexPrintf("(mglPrivateVolume) Must give volume argument\n");
  }

  // return current volume settings
  if (getVolume(&volume,&numChannels)) {
    // allocate return array
    plhs[0] = mxCreateDoubleMatrix(1,numChannels,mxREAL);
    double *outptr = (double*)mxGetPr(plhs[0]);
    // copy volume values into return array
    for (iChannel = 0;iChannel < numChannels; iChannel++)
      outptr[iChannel] = volume[iChannel];
    // free space for volume
    free(volume);
  }
  else
    // return NULL on error
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
}



//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
#import <CoreAudio/CoreAudio.h>

////////////////////////
//   cocoaVolume   //
////////////////////////
///////////////
// setVolume //
///////////////
void setVolume(double *volume, int numChannels)
{
  // get verbose setting
  int verbose = (int)mglGetGlobalDouble("verbose");

  /////////////////////////////
  // Get audio device
  /////////////////////////////

  // declare variable
  AudioDeviceID mainAudioDevice = 0;
  UInt32 theSize = sizeof(AudioDeviceID);

  // ask for main audio device
  AudioObjectPropertyAddress mainAudioAddress = 
    { kAudioHardwarePropertyDefaultOutputDevice, 
      kAudioObjectPropertyScopeGlobal,
      kAudioObjectPropertyElementMaster };

  // get pointer to audio device
  OSStatus theError = AudioObjectGetPropertyData(
    kAudioObjectSystemObject,
    &mainAudioAddress,
    0,
    NULL,
    &theSize,
    &mainAudioDevice);

  // handle errors getting pointer to audio device
  if (theError != noErr) {
    mexPrintf("(mglPrivateVolume) Could not get main audio device\n");
    return;
  }

  /////////////////////////////
  // Set volume for all channels
  /////////////////////////////

  // Declare variables
  Float32 channelVolume;
  theSize = sizeof(Float32);
  Boolean isSettable = false;
  int iChannel;

  // loop over channels
  for (iChannel = 1;iChannel <= numChannels;iChannel++) {

    // address for getting volume
    AudioObjectPropertyAddress volumeAddress = { 
      kAudioDevicePropertyVolumeScalar,
      kAudioDevicePropertyScopeOutput,
      iChannel };

    // check if property exists
    if (!AudioObjectHasProperty(mainAudioDevice, &volumeAddress)) {
      mexPrintf("(mglPrivateVolume) Volume property does not exist\n");
      return;
    }

    // check if property is settable
    theError = AudioObjectIsPropertySettable(mainAudioDevice, &volumeAddress, &isSettable);
    if ((theError != noErr) || !isSettable) {
      mexPrintf("(mglPrivateVolume) Volume property is not settable\n");
      return;
    }

    // set the volume
    channelVolume = (Float32)volume[iChannel-1];
    theError = AudioObjectSetPropertyData(
      mainAudioDevice,
      &volumeAddress,
      0,
      NULL,
      theSize,
      &channelVolume);

    // handle errors getting volume
    if (theError != noErr) {
      mexPrintf("(mglPrivateVolume) Error setting volume\n");
      return;
    }

    if (verbose) mexPrintf("(mglPrivateVolume) Setting channel %i Volume: %f\n",iChannel,channelVolume);
  }


}

///////////////
// getVolume //
///////////////
int getVolume(double **volume, int *numChannels)
{
  // get verbose setting
  int verbose = (int)mglGetGlobalDouble("verbose");

  /////////////////////////////
  // Get audio device
  /////////////////////////////

  // declare variable
  AudioDeviceID mainAudioDevice = 0;
  UInt32 theSize = sizeof(AudioDeviceID);

  // ask for main audio device
  AudioObjectPropertyAddress mainAudioAddress = 
    { kAudioHardwarePropertyDefaultOutputDevice, 
      kAudioObjectPropertyScopeGlobal,
      kAudioObjectPropertyElementMaster };

  // get pointer to audio device
  OSStatus theError = AudioObjectGetPropertyData(
    kAudioObjectSystemObject,
    &mainAudioAddress,
    0,
    NULL,
    &theSize,
    &mainAudioDevice);

  // handle errors getting pointer to audio device
  if (theError != noErr) {
    mexPrintf("(mglPrivateVolume) Could not get main audio device\n");
    return(0);
  }

  /////////////////////////////
  // Get number of channels
  /////////////////////////////

  // Declare variables
  AudioBufferList bufferList;
  theSize = sizeof(AudioBufferList);
  *numChannels = 0;

  // address for getting volume
  AudioObjectPropertyAddress bufferListAddress = { 
    kAudioDevicePropertyStreamConfiguration,
    kAudioDevicePropertyScopeOutput,
    kAudioObjectPropertyElementMaster };

  // get the buffer list
  theError = AudioObjectGetPropertyData(
    mainAudioDevice,
    &bufferListAddress,
    0,
    NULL,
    &theSize,
    &bufferList);

  // handle errors getting number of channels
  if (theError != noErr) {
    mexPrintf("(mglPrivateVolume) Could not find audio buffer number of channels\n");
    return(0);
  }

  // get field with number of channels
  if (bufferList.mNumberBuffers) { 
    if (verbose)
      mexPrintf("(mglPrivateVolume) Number of channels: %i\n",bufferList.mBuffers[0].mNumberChannels);
    *numChannels = bufferList.mBuffers[0].mNumberChannels;
  }
  else {
    mexPrintf("(mglPrivateVolume) Could not find audio buffer number of channels\n");
    return(0);
  }
    
  // get space for volume
  *volume = (double*)malloc(sizeof(double) * *numChannels);
  if (*volume == NULL) {
    mexPrintf("(mglPrivateVolume) Could not allocate space for volume data\n");
    return(0);
  }

  /////////////////////////////
  // Get volume for all channels
  /////////////////////////////

  // Declare variables
  Float32 channelVolume = 0;
  theSize = sizeof(Float32);
  int iChannel;

  // loop over channels
  for (iChannel = 1;iChannel <= *numChannels;iChannel++) {

    // address for getting volume
    AudioObjectPropertyAddress volumeAddress = { 
      kAudioDevicePropertyVolumeScalar,
      kAudioDevicePropertyScopeOutput,
      iChannel };

    // check if property exists
    // check if property exists
    if (!AudioObjectHasProperty(mainAudioDevice, &volumeAddress)) {
      mexPrintf("(mglPrivateVolume) Volume property does not exist\n");
      free(*volume);
      return(0);
    }

    // get the volume
    theError = AudioObjectGetPropertyData(
      mainAudioDevice,
      &volumeAddress,
      0,
      NULL,
      &theSize,
      &channelVolume);

    // handle errors getting volume
    if (theError != noErr) {
      mexPrintf("(mglPrivateVolume) Could not get volume\n");
      free(*volume);
      return(0);
    }

    if (verbose) mexPrintf("(mglPrivateVolume) Channel %i Volume: %f\n",iChannel,channelVolume);
    // store channel volume in volume array
    (*volume)[iChannel-1] = (double)channelVolume;
  }
  return(1);
}

//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__cocoa__
////////////////////////
//   carbonVolume  //
////////////////////////
void setVolume(double *volume, int numChannels)
{
  mexPrintf("(mglPrivateVolume) Not implemented\n");
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
void setVolume(double *volume, int numChannels)
{
  mexPrintf("(mglPrivateVolume) Not implemented\n");
}
#endif//__linux__
