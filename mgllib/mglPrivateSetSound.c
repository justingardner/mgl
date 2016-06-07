#ifdef documentation
=========================================================================

     program: mglPrivateSetSound.c
          by: justin gardner
        date: 08/10/2015
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to set properties of sound returned by mglSetSound
       usage: soundNum = mglPrivateSetSound(soundNum,propertyValue,propertyNum)

$Id: mglInstallSound.c 379 2008-12-31 03:56:53Z justin $
=========================================================================
#endif

/////////////////////////
//   define section    //
/////////////////////////
#define STRLEN 1024

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// soundNum contains the identifier for the sound (in Cocoa this is a pointer to an NSSound
// object). propertyName is a c string with the name of the property to set and propertyValue
// the number to set it to. Note that if propertyValue is nan then this means to display
// a list of possible settings
void setSound(unsigned long soundNum, char *propertyName, int propertyValue);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  char propertyName[STRLEN];
  if (mxIsEmpty(prhs[1]))
    // if propteryName is empty, then propertyName is empty
    propertyName[0] = 0;
  else	
    // get the string property name
    mxGetString(prhs[1],propertyName,STRLEN);

  // get the int propertyValue
  int propertyValue = mxGetScalar(prhs[2]);

  // get the sound number
  int soundNum = (int)mxGetScalar(prhs[0]);
  if (mglIsGlobal("sounds") > 0) {
    // get the global sounds vector
    mxArray *sounds = mglGetGlobalField("sounds");
    unsigned long *soundsPtr = (unsigned long*)mxGetPr(sounds);
    // if we have the called for sound, then play it
    if ((mxGetN(sounds) >= soundNum) && (soundNum > 0))
      setSound(soundsPtr[soundNum-1],propertyName,propertyValue);
  }
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
////////////////////////////////////
//   cocoa local function decls   //
////////////////////////////////////
NSString *deviceIDs(UInt32 devNum);

////////////////////////////
//   cocoa local include  //
////////////////////////////
#include <CoreAudio/CoreAudio.h>

///////////////////////
//   cocoaSetSound   //
///////////////////////
void setSound(unsigned long soundNum, char *propertyName, int propertyValue)
{
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // convert to pointer
  NSSound *mySound = (NSSound*)soundNum;

  // if propertyName is NULL then display properties
  if (strlen(propertyName) == 0) {
    // display the deviceID
    mexPrintf("deviceID: %s\n",[[mySound playbackDeviceIdentifier] cString]);
    return;
  }

  // check what property to set
  if (strcmp(propertyName,"deviceid")==0) {
    if (propertyValue == -1)
      // device ID. If propertyValue is set to negative one then display list
      deviceIDs(0);
    else {
      // get the deviceID
      NSString *deviceID = deviceIDs(propertyValue);
      if (deviceID == NULL)
	mexPrintf("(mglPrivateSetSound) DeviceID number out of range\n");
      else {
	// set the deviceID
	[mySound setPlaybackDeviceIdentifier:deviceID];
      }
    }
  }
  else {
    mexPrintf("(mglPrivateSetSound) Unrecognized propertyName: %s\n",propertyName);
  }
}

/////////////////////////////
//   cocoa: deviceIDs  //
/////////////////////////////
NSString *deviceIDs(UInt32 devNum)
{
  // get some information
  UInt32 sz;
  AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,&sz,NULL);
  AudioDeviceID *audioDevices=(AudioDeviceID *)malloc(sz);
  AudioHardwareGetProperty(kAudioHardwarePropertyDevices,&sz,audioDevices);
  UInt32 deviceCount = (sz / sizeof(AudioDeviceID));
  
  // set up some variables
  UInt32 i, outputDeviceCount = 0;
  // get buffer list
  UInt32 outputChannelCount;

  // loop over devices
  for(i=0;i<deviceCount;++i){

    // default to no channels
    outputChannelCount=0;

    // get properties of AudioDevice
    AudioDeviceGetPropertyInfo(audioDevices[i],0,false,kAudioDevicePropertyStreamConfiguration,&sz,NULL);
    AudioBufferList *bufferList=(AudioBufferList *)malloc(sz);
    AudioDeviceGetProperty(audioDevices[i],0,false,kAudioDevicePropertyStreamConfiguration,&sz,bufferList);

    // count number of channels
    UInt32 j;
    for(j=0;j<bufferList->mNumberBuffers;++j)
      outputChannelCount += bufferList->mBuffers[j].mNumberChannels;
    
    // free information about AudioDevice
    free(bufferList);

    // skip devices without any output channels
    if(outputChannelCount==0) continue;

    // found one with output channels, so update outputDeviceCount
    outputDeviceCount++;
    
    // set up string
    NSString *s;
    sz=sizeof(CFStringRef);

    if (devNum == 0) {
      // Print out properties
      AudioDeviceGetProperty(audioDevices[i],0,false,kAudioObjectPropertyName,&sz,&s);
      mexPrintf("%i: %s ",outputDeviceCount,[s cString]);
      [s release];
      AudioDeviceGetProperty(audioDevices[i],0,false,kAudioDevicePropertyDeviceUID,&sz,&s);
      mexPrintf("(%s) ",[s cString]);
      [s release];
      mexPrintf("nChannels: %i\n",outputChannelCount);
    }
    else {
      // if we have a match then return the string value
      if (devNum == outputDeviceCount) {
	AudioDeviceGetProperty(audioDevices[i],0,false,kAudioDevicePropertyDeviceUID,&sz,&s);
	return(s);
      }
    }
  }
  return(NULL);
}

#else//__cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
////////////////////////
//   carbonSetSound   //
////////////////////////
void setSound(unsigned long soundNum, char *propertyName, int propertyValue)
{
  mexPrintf("(mglPrivateSetSound) Not implemented\n");
  return(-1);
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
void setSound(unsigned long soundNum, char *propertyName, int propertyValue)
{
  mexPrintf("(mglPrivateSetSound) Not implemented\n");
  return(-1);
}
#endif//__linux__


//-----------------------------------------------------------------------------------///
// ****************************** Windows specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
void setSound(unsigned long soundNum, char *propertyName, int propertyValue)
{
  mexPrintf("(mglPrivateSetSound) Not implemented\n");
  return(-1);
}
#endif

