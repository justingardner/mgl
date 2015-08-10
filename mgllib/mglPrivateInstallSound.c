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
// Similar to above, except takes a buffer with sound samples
// sound samples are organized as an array of sound samples
// in rows (1 row for each channel). Number of samples in columns
// the sample rate and other parameters are set by calling
// mglSetSound. Data should be an int array which contains the
// samples in order of samples, interleaved by channel e.g.:
// for data with 2 channels, 3 samples
// d = [s1c1 s1c2 s2c1 s2c2 s3c1 s3c2];
unsigned long installSoundFromData(int *d,unsigned int nChannels,unsigned int nSamples);
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
  // with a single argument
  else {
    if (mxIsChar(prhs[0])) {
      // set sound to the file that is passed in if it is a string
      char soundFilePath[2048];
      mxGetString(prhs[0],soundFilePath,2048);
      soundID = installSound(soundFilePath);
    }
    else {
      // array, means to install from data
      // First get dimensions. Number of rows corresponds to channels
      // Number of columns to number of samples
      unsigned int nChannels = mxGetM(prhs[0]);
      unsigned int nSamples = mxGetN(prhs[0]);
      // install the sound
      soundID = installSoundFromData((int *)mxGetPr(prhs[0]),nChannels,nSamples);
    }
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

///////////////////////////////////
//   cocoaInstallSoundFromData   //
///////////////////////////////////
unsigned long installSoundFromData(int *d, unsigned int nChannels, unsigned int nSamples)
{
  // index variable
  int i;

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
  const unsigned int sampleRate = 8192;
  const unsigned int bytesPerFrame = nChannels * sizeof(unsigned int);
  const unsigned int dataSize = nSamples * bytesPerFrame;
  const unsigned int totalSize = dataSize + sizeof(struct aiffFile);
        
  // allocate memory for aiff file
  struct aiffFile* aiff = malloc(totalSize);

  // check proper allocation of aiff
  if (! aiff) {
    mexPrintf("(mglPrivateSound) Could not allocate %lu bytes for sound\n", totalSize);
    return(0);
  }

  // set up header. Note that we have to endian swap since the format
  // is specified in f*$*ing little endian
  aiff->formID = CFSwapInt32('FORM');
  aiff->formChunkSize = CFSwapInt32(totalSize - offsetof(struct aiffFile, formType));
  aiff->formType = CFSwapInt32('AIFF');
  
  // comm chunk has info about the sound samples
  aiff->commID = CFSwapInt32('COMM');
  aiff->commChunkSize = CFSwapInt32(18);
  aiff->numChannels = CFSwapInt16(nChannels);
  aiff->numSampleFrames = CFSwapInt32(nSamples);
  aiff->sampleSize = CFSwapInt16(32);
        
  // set bizarre extended 80 type (10 bytes?)
  double sampleRateDouble = (double)sampleRate;
  dtox80(&sampleRateDouble, &aiff->sampleRate);
                
  // Sound chunk will actually contain data
  aiff->ssndID = CFSwapInt32('SSND');
  aiff->ssndChunkSize = CFSwapInt32(dataSize + 8);
  aiff->offset = CFSwapInt32(0);
  aiff->blockSize = CFSwapInt32(0);
        
  // copy sound
  memcpy(aiff->soundData,d,dataSize);

  // start autorelease pool
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  // set up a data structure with pointer to data
  NSData* data = [[NSData alloc] initWithBytesNoCopy:aiff length:totalSize];
  
  // and sound structure
  NSSound* sound = [[NSSound alloc] initWithData:data];

  // data is no longer needed. 
  [data release];
  
  // drain the pool
  [pool drain];

  //return pointer
  return((unsigned long)sound);
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

//////////////////////////////
//   installSoundFromData   //
//////////////////////////////
unsigned long installSoundFromData(int *data)
{
  mexPrintf("(mglPrivateInstallSound:installSoundFromData) Not implemented\n");
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

unsigned long installSoundFromData(int *data)
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
unsigned long installSoundFromData(int *data)
{
  mexPrintf("(mglInstallSound) Not implemented on linux\n");
  return 0;
}
void removeSound(unsigned long soundID)
{
  mexPrintf("(mglInstallSound) Not implemented on Windows\n");
}
#endif

