#ifdef documentation
=========================================================================

     program: mglPrivateSound.c
          by: justin gardner
        date: 08/05/2015
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to play arbitrary waveform sounds
       usage: mglSound()

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
// This function takes the buffer pointed to by sound
// the sample rate, device number and time and plays it
void playSound(unsigned char* sound, int sampleRate, int playTime, int deviceNumber);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  unsigned char *duh;
  playSound(duh,8192,0,1);
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
#include <CoreAudio/CoreAudio.h>
////////////////////////
//   cocoaPlaySound   //
////////////////////////
void playSound(unsigned char* xxxsound, int xxxsampleRate, int playTime, int deviceNumber)
{
#if 0
  NSString *filenameString = [[NSString alloc] initWithUTF8String:"/System/Library/Sounds/Purr.aiff"];
  NSSound *mySound;
  mySound = [[NSSound alloc] initWithContentsOfFile:filenameString byReference:NO];
  if ([mySound play] == NO) {
    mexPrintf("No\n");
  }
  else {
    mexPrintf("Yes\n");
  }
#endif

#if 0
UInt32 sz;
AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,&sz,NULL);
AudioDeviceID *audioDevices=(AudioDeviceID *)malloc(sz);
AudioHardwareGetProperty(kAudioHardwarePropertyDevices,&sz,audioDevices);
UInt32 deviceCount = (sz / sizeof(AudioDeviceID));

UInt32 i;
for(i=0;i<deviceCount;++i)
{
    NSString *s;

    // get buffer list
    UInt32 outputChannelCount=0;
    {
        AudioDeviceGetPropertyInfo(
            audioDevices[i],0,false,
            kAudioDevicePropertyStreamConfiguration,
            &sz,NULL
            );
        AudioBufferList *bufferList=(AudioBufferList *)malloc(sz);
        AudioDeviceGetProperty(
            audioDevices[i],0,false,
            kAudioDevicePropertyStreamConfiguration,
            &sz,&bufferList
            );

        UInt32 j;
        for(j=0;j<bufferList->mNumberBuffers;++j)
            outputChannelCount += bufferList->mBuffers[j].mNumberChannels;

        free(bufferList);
    }

    // skip devices without any output channels
    if(outputChannelCount==0)
        continue;

    // output some device info
    {
        sz=sizeof(CFStringRef);

        AudioDeviceGetProperty(
            audioDevices[i],0,false,
            kAudioDevicePropertyDeviceUID,
            &sz,&s
            );
        NSLog(@"DeviceUID: [%@]",s);
        [s release];

        AudioDeviceGetProperty(
            audioDevices[i],0,false,
            kAudioObjectPropertyName,
            &sz,&s
            );
        NSLog(@"    Name: [%@]",s);
        [s release];

        NSLog(@"    OutputChannels: %d",outputChannelCount);
    }
}
#endif
  // Header for AIFF file
  struct aiffFile {
    /* FORM chunk */
    unsigned int formID;
    int formChunkSize;
    unsigned int formType;
                
    /* COMM chunk */
    unsigned int commID;
    int commChunkSize;
    short numChannels;
    unsigned int numSampleFrames;
    short sampleSize;
    extended80 sampleRate;
                
    /* SSND chunk */
    unsigned int ssndID;
    int ssndChunkSize;
    unsigned int offset;
    unsigned int blockSize;
    int soundData[];
  } __attribute__ ((__packed__));
        

  // some constants 
  const unsigned int sampleRate = 48000;
  const unsigned int channels = 1;
  const unsigned int bytesPerFrame = channels * sizeof(unsigned int);
  const unsigned int seconds = 4;
        
  const unsigned int dataSize = seconds * sampleRate * channels * bytesPerFrame;
  const unsigned int totalSize = dataSize + sizeof(struct aiffFile);
        
  unsigned int i;

  // allocate memory for aiff file
  struct aiffFile* aiff = malloc(totalSize);

  if (! aiff) {
    mexPrintf("(mglPrivateSound) Could not allocate %lu bytes for sound\n", totalSize);
    return;
  }

  // set up header. Note that we have to endian swap since the format
  // is specified in f*$*ing little endian
  aiff->formID = CFSwapInt32('FORM');
  aiff->formChunkSize = CFSwapInt32(totalSize - offsetof(struct aiffFile, formType));
  aiff->formType = CFSwapInt32('AIFF');
  
  // comm chunk has info about the sound samples
  aiff->commID = CFSwapInt32('COMM');
  aiff->commChunkSize = CFSwapInt32(18);
  aiff->numChannels = CFSwapInt16(1);
  aiff->numSampleFrames = CFSwapInt32(seconds * sampleRate);
  aiff->sampleSize = CFSwapInt16(32);
        
  // set bizarre extended 80 type (10 bytes?)
  double sampleRateDouble = (double)sampleRate;
  dtox80(&sampleRateDouble, &aiff->sampleRate);
                
  // Sound chunck will actually contain data
  aiff->ssndID = CFSwapInt32('SSND');
  aiff->ssndChunkSize = CFSwapInt32(dataSize + 8);
  aiff->offset = CFSwapInt32(0);
  aiff->blockSize = CFSwapInt32(0);
        
  // set up sound
  double frequency = 500;        
  for (i=0; i < seconds * sampleRate * channels; i++) {
    aiff->soundData[i] =  CFSwapInt32((unsigned int) (INT_MAX * sin((double)i * M_PI * 2. * (frequency / (double)sampleRate) )));

  }

  // DEBUG code. Write to file
  FILE *f;
  f=fopen("/Users/justin/Desktop/test.aif","w");
  fwrite(aiff,1,totalSize,f);
  fclose(f);
  
  // start autorelease pool
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  // set up a data structure with pointer to data
  NSData* data = [[NSData alloc] initWithBytesNoCopy:aiff length:totalSize];
  
  // and sound structure
  NSSound* sound = [[NSSound alloc] initWithData:data];

  // data is no longer needed. 
  [data release];

  // debug print out
  mexPrintf("Device: %s\n",[[sound playbackDeviceIdentifier] UTF8String]);
  if ([sound play] == NO) {
    mexPrintf("Sound NOT playing\n");
  }
  else {
    mexPrintf("Sound is playing\n");
  }

  // release free memory
  [sound release];
  [pool release];
}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else//__carbon__
////////////////////////
//   carbonPlaySound  //
////////////////////////
void playSound(unsigned long soundID)
{
  mexPrintf("(mglPrivateSound) Not implemented for Mac carbon\n");
}
#endif//__carbon__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
void playSound(unsigned long soundID)
{
  mexPrintf("(mglPrivateSound) Not implemented for linux\n");
}
#endif//__linux__
