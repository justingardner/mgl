#ifdef documentation
=========================================================================

  program: mglResolution.c
  by: justin gardner
  date: 12/27/08
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose: set the resolution/refresh rate of a monitor

  $Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This functions sets the resolution of the display (displayNumber is 1 based not 0 based).
// If the asked for dimensions/frameRate/depth are not achievable, it should do something
// reasonable and set the variables to what was actually set.
void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth);
// this function gets the resolution of the asked for display
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth);
// This function should set the number of the default display, i.e. the one that
// should open when the user does mglOpen without any arguments. This should not be
// the main display. The defaultDisplayNum should be 1 based. It also sets
// the number of displays
void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // variables
  int frameRate,screenWidth,screenHeight,bitDepth,displayNumber,numDisplays,defaultDisplayNum,changeResolution = 0;
  int requestedScreenWidth, requestedScreenHeight, requestedFrameRate, requestedBitDepth;
  const char *fieldNames[] = {"displayNumber","numDisplays","screenWidth","screenHeight","frameRate","bitDepth"};
  const mwSize outDims[2] = {1, 1};

  // get how many displays there are at which one is the default.
  getNumDisplaysAndDefault(&numDisplays,&defaultDisplayNum);

  // otherwise interpret the input settings
  if (nrhs>0) {
    // get display number
    if (mxGetPr(prhs[0]) != NULL)
      displayNumber = (int)*mxGetPr(prhs[0]);
    else
      displayNumber = -1;
  }
  
  // if the display number is set to something less than 1 then
  // set it to the last display in the list
  if ((nrhs==0) || (displayNumber < 1))
    displayNumber = defaultDisplayNum;
  else if (displayNumber > numDisplays) {
    mexPrintf("(mglResolution) Display %i out of range (1:%i)\n",displayNumber,numDisplays);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // get the current resolution of the monitor
  getResolution(&displayNumber,&screenWidth,&screenHeight,&frameRate,&bitDepth);

  // set resolution, if more than 1 argument
  if (nrhs>1) {
    // get rest of parameters
    if ((nrhs>=2) && (mxGetPr(prhs[1]) != NULL)) screenWidth=(int)*mxGetPr(prhs[1]);
    if ((nrhs>=3) && (mxGetPr(prhs[2]) != NULL)) screenHeight=(int)*mxGetPr(prhs[2]);
    if ((nrhs>=4) && (mxGetPr(prhs[3]) != NULL)) frameRate=(double)*mxGetPr(prhs[3]);
    if ((nrhs>=5) && (mxGetPr(prhs[4]) != NULL)) bitDepth = (int)*mxGetPr(prhs[4]);
    if (nrhs>5) usageError("mglResolution");
    changeResolution = 1;
  }
  // or see if we have a passed in structure
  if ((nrhs==1) && mxIsStruct(prhs[0])) {
    displayNumber = (int)*(double *)mxGetPr(mxGetField(prhs[0],0,"displayNumber"));
    screenWidth = (int)*(double *)mxGetPr(mxGetField(prhs[0],0,"screenWidth"));
    screenHeight = (int)*(double *)mxGetPr(mxGetField(prhs[0],0,"screenHeight"));
    bitDepth = (int)*(double *)mxGetPr(mxGetField(prhs[0],0,"bitDepth"));
    frameRate = (int)*(double *)mxGetPr(mxGetField(prhs[0],0,"frameRate"));
    changeResolution = 1;
  }
  if (changeResolution) {
    // check to make sure we are not asked to set the resolution of an open display
    if (mglGetGlobalDouble("displayNumber")==displayNumber) {
      mexPrintf("(mglResolution) Cannot set resolution of open display %i\n",displayNumber);
      return;
    }

    // remember what was asked for
    requestedScreenWidth = screenWidth;
    requestedScreenHeight = screenHeight;
    requestedFrameRate = frameRate;
    requestedBitDepth = bitDepth;

    // now set the resolution of the monitor
    setResolution(&displayNumber,&screenWidth,&screenHeight,&frameRate,&bitDepth);

    // check for match with requested
    if ((requestedScreenWidth != screenWidth) || (requestedScreenHeight != screenHeight)||(requestedFrameRate != frameRate) || (requestedBitDepth != bitDepth)) {
      mexPrintf("(mglResolution) Could not set display parameters to [%ix%i], frameRate: %i bitDepth: %i\n                 Display parameters are set to: [%ix%i], frameRate=%i, bitDepth=%i\n",requestedScreenWidth,requestedScreenHeight,requestedFrameRate,requestedBitDepth,screenWidth,screenHeight,frameRate,bitDepth);
    }
  }

  // return info as a struct
  // create the output structure
  plhs[0] = mxCreateStructArray(1,outDims,6,fieldNames);

  // add set the fields
  mxSetField(plhs[0],0,"displayNumber",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"displayNumber")) = (double)displayNumber;
  mxSetField(plhs[0],0,"numDisplays",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"numDisplays")) = (double)numDisplays;
  mxSetField(plhs[0],0,"screenWidth",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"screenWidth")) = (double)screenWidth;
  mxSetField(plhs[0],0,"screenHeight",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"screenHeight")) = (double)screenHeight;
  mxSetField(plhs[0],0,"frameRate",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"frameRate")) = (double)frameRate;
  mxSetField(plhs[0],0,"bitDepth",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"bitDepth")) = (double)bitDepth;
}

#ifdef __APPLE__
#ifdef __cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
////////////////////////
//   define section   //
////////////////////////
#define kMaxDisplays 8
//#define MACOS106

///////////////////////////////
//   function declarations   //
///////////////////////////////
#ifdef __MAC_10_6
int getBitDepth(CGDisplayModeRef displayMode);
void printDisplayModes(CGDirectDisplayID whichDisplay);
boolean_t setBestMode(CGDirectDisplayID whichDisplay,int screenWidth,int screenHeight,int frameRate,int bitDepth);
#endif

///////////////////////
//   getResolution   //
///////////////////////
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // get all screen array
  NSArray *screens = [NSScreen screens];
  // grab the screen in question
  NSScreen *thisDisplay = [screens objectAtIndex:(*displayNumber-1)];
  // get the display description
  NSDictionary *thisDisplayDescription = [thisDisplay deviceDescription];
  //NSLog(@"test %@",[thisDisplayDescription objectForKey:@"NSDeviceResolution"]);
  // get the display size
  NSSize thisDisplaySize = [[thisDisplayDescription objectForKey:@"NSDeviceSize"] sizeValue];
  *screenWidth = thisDisplaySize.width;
  *screenHeight = thisDisplaySize.height;
  // get the bit depth
  *bitDepth = [[thisDisplayDescription objectForKey:@"NSDeviceBitsPerSample"] integerValue];

  // FIX FIX FIX ok, giving up carbon code to follow here, when I can figure out how to 
  // write cocoa code above to get bitDepth and frameRate then the code
  // below can be removed
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;
  CFDictionaryRef modeInfo;

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglResolution) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  if (verbose)
    mexPrintf("(mglResolution) Found %i displays\n",numDisplays);

  // get the display
  whichDisplay = displays[*displayNumber-1];

#ifdef __MAC_10_6
  // get the display settings
  CGDisplayModeRef displayMode;
  displayMode = CGDisplayCopyDisplayMode(whichDisplay);
  
  // get bit rate
  *bitDepth = getBitDepth(displayMode);
  // get frame rate
  *frameRate = (int)CGDisplayModeGetRefreshRate(displayMode);

  // release the display settings
  CGDisplayModeRelease(displayMode);

  // print the display modes
  //  printDisplayModes(whichDisplay);
#else
  // old way of getting bitDepth
  *bitDepth=(int)CGDisplayBitsPerPixel(whichDisplay);
  
  // old way of getting the refresh rate
  *frameRate = 0;
  modeInfo = CGDisplayCurrentMode(whichDisplay);
  if (modeInfo != NULL) {
      CFNumberRef value = (CFNumberRef)CFDictionaryGetValue(modeInfo, kCGDisplayRefreshRate);
      if (value != NULL)
        CFNumberGetValue(value, kCFNumberIntType, frameRate);
  }
#endif

  // assume 60, if the above fails
  if (*frameRate == 0) {
    if (verbose)
      mexPrintf("(mglResolution) Assuming refresh rate of display %i is 60Hz\n",*displayNumber);
    *frameRate = 60;
  }

  if (verbose)
    mexPrintf("(mglResolution) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",*screenWidth,*screenHeight,*frameRate,*bitDepth);
  [pool release];
}
///////////////////////
//   setResolution   //
///////////////////////
void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // FIX FIX FIX this is just the carbon code copied from below
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;
  CFDictionaryRef modeInfo;

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglResolution) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  if (verbose)
    mexPrintf("(mglResolution) Found %i displays\n",numDisplays);

  // get the display
  whichDisplay = displays[*displayNumber-1];

  // capture the appropriate display
  //  CGDisplayCapture(whichDisplay);

  // Switch the display mode
  boolean_t success=false;
#ifdef __MAC_10_6
  success = setBestMode(whichDisplay,*screenWidth,*screenHeight,*frameRate,*bitDepth);
#else
  CGDisplaySwitchToMode(whichDisplay,CGDisplayBestModeForParametersAndRefreshRate(whichDisplay,*bitDepth,*screenWidth,*screenHeight,*frameRate,&success));
#endif
  // check to see if it found the right setting
  if (!success) {
    mexPrintf("(mglResolution) Warning: failed to set requested display parameters.\n");
  }

  // get the display settings
  *screenWidth=(int)CGDisplayPixelsWide(whichDisplay);
  *screenHeight=(int)CGDisplayPixelsHigh(whichDisplay);

  int requestedFrameRate = *frameRate;

#ifdef __MAC_10_6
  // get bit and frame rate
  CGDisplayModeRef displayMode;
  displayMode = CGDisplayCopyDisplayMode(whichDisplay);
  // bit depth
  *bitDepth = getBitDepth(displayMode);
  // get frame rate
  *frameRate = (int)CGDisplayModeGetRefreshRate(displayMode);
  CGDisplayModeRelease(displayMode);
#else
  // deprecated way
  *bitDepth=(int)CGDisplayBitsPerPixel(whichDisplay);

  // and the refresh rate
  *frameRate = 0;
  modeInfo = CGDisplayCurrentMode(whichDisplay);
  if (modeInfo != NULL) {
    CFNumberRef value = (CFNumberRef)CFDictionaryGetValue(modeInfo, kCGDisplayRefreshRate);
    if (value != NULL)
      CFNumberGetValue(value, kCFNumberIntType, frameRate);
  }
#endif

  // assume 60, if the above fails
  if (*frameRate == 0) {
    if (verbose)
      mexPrintf("(mglResolution) Assuming refresh rate of display %i has been set to %iHz\n",requestedFrameRate);
    *frameRate = requestedFrameRate;
  }

  if (verbose)
    mexPrintf("(mglResolution) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",*screenWidth,*screenHeight,*frameRate,*bitDepth);

  [pool release];
}
//////////////////////////////////
//   getNumDisplaysAndDefault   //
//////////////////////////////////
void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // return num displays and default display number
  *numDisplays = [[NSScreen screens] count];
  *defaultDisplayNum = *numDisplays;

  [pool release];
}

#ifdef __MAC_10_6
/////////////////////
//   getBitDepth   //
/////////////////////
int getBitDepth(CGDisplayModeRef displayMode)
{
  int bitDepth = 0;

  // get bit depth
  CFStringRef pixelEncoding;
  pixelEncoding = CGDisplayModeCopyPixelEncoding(displayMode);
  // return an appropriate bit depth for each one of these strings
  // defined in IOGraphicsTypes.h
  if (CFStringCompare(pixelEncoding,CFSTR(IO32BitDirectPixels),0)==kCFCompareEqualTo)
    bitDepth = 32;
  else if (CFStringCompare(pixelEncoding,CFSTR(IO16BitDirectPixels),0)==kCFCompareEqualTo)
    bitDepth = 16;
  else if (CFStringCompare(pixelEncoding,CFSTR(IO8BitIndexedPixels),0)==kCFCompareEqualTo)
    bitDepth = 8;
  else if (CFStringCompare(pixelEncoding,CFSTR(kIO30BitDirectPixels),0)==kCFCompareEqualTo)
    bitDepth = 30;
  else if (CFStringCompare(pixelEncoding,CFSTR(kIO64BitDirectPixels),0)==kCFCompareEqualTo)
    bitDepth = 64;
  // release the pixel encoding
  CFRelease(pixelEncoding);
  return(bitDepth);
}

//////////////////////////
//   printDisplayModes  //
//////////////////////////
void printDisplayModes(CGDirectDisplayID whichDisplay)
{
  CGDisplayModeRef mode;
  CFArrayRef modeList;
  CFIndex index, count;

  mexPrintf("(mglResolution) Available video modes\n");

  // get all available display modes
  modeList = CGDisplayCopyAllDisplayModes(whichDisplay, NULL);
  count = CFArrayGetCount(modeList);

  // cycle through each available mode
  for (index = 0; index < count; index++) {
    // display info about each mode
    mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeList, index);
    mexPrintf("%i: %i x %i %i bits\n",index,CGDisplayModeGetWidth(mode),CGDisplayModeGetHeight(mode),getBitDepth(mode));
  }
  CFRelease(modeList);
}
/////////////////////
//   setBestMode   //
/////////////////////
boolean_t setBestMode(CGDirectDisplayID whichDisplay,int screenWidth,int screenHeight,int frameRate,int bitDepth)
{
  CGDisplayModeRef mode;
  CFArrayRef modeList;
  CFIndex index, count;
  int bestWidth, bestHeight, bestBitDepth, thisBitDepth, bestFrameRate, thisFrameRate;
  boolean_t retval = false;

  // get all available display modes
  modeList = CGDisplayCopyAllDisplayModes(whichDisplay, NULL);
  count = CFArrayGetCount(modeList);

  // check for closest match in width, height
  double minDifference = DBL_MAX,thisDifference;
  for (index = 0; index < count; index++) {
    // get the mode
    mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeList, index);
    // check how close the pixel match is
    thisDifference = pow(((double)CGDisplayModeGetWidth(mode)-(double)screenWidth),2)+pow(((double)CGDisplayModeGetHeight(mode)-(double)screenHeight),2);
    if (thisDifference<minDifference) {
      bestWidth = (int)CGDisplayModeGetWidth(mode);
      bestHeight = (int)CGDisplayModeGetHeight(mode);
      minDifference = thisDifference;
    }
  }
  
  // now that we found the mode with the closest width/height match
  // check for best match in number of bits
  minDifference = DBL_MAX;
  for (index = 0; index < count; index++) {
    // get the mode
    mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeList, index);
    // check that the width/height are matched to the best
    if ((bestWidth == (int)CGDisplayModeGetWidth(mode)) && (bestHeight == (int)CGDisplayModeGetHeight(mode))) {
      thisBitDepth = getBitDepth(mode);
      if (abs((double)bitDepth-(double)thisBitDepth) < minDifference) {
	minDifference = abs((double)bitDepth-(double)thisBitDepth);
	bestBitDepth = thisBitDepth;
      }
    }
  }

  // now that we found the mode with the closest width/height match
  // and the best number of bits, choose the best refresh rate
  minDifference = DBL_MAX;
  for (index = 0; index < count; index++) {
    // get the mode
    mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeList, index);
    // check that the width/height and bitDepth are matched to the best
    if ((bestWidth == (int)CGDisplayModeGetWidth(mode)) && (bestHeight == (int)CGDisplayModeGetHeight(mode)) && (bestBitDepth == getBitDepth(mode))) {
      thisFrameRate = (int)CGDisplayModeGetRefreshRate(mode);
      if (thisFrameRate == 0) thisFrameRate = 60;
      if (abs((double)frameRate-(double)thisFrameRate) < minDifference) {
	minDifference = abs((double)frameRate-(double)thisFrameRate);
	bestFrameRate = thisFrameRate;
      }
    }
  }

  // now go set the best matching mode
  for (index = 0; index < count; index++) {
    // get the mode
    mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeList, index);
    thisFrameRate = (int)CGDisplayModeGetRefreshRate(mode);
    if (thisFrameRate == 0) thisFrameRate = bestFrameRate;
    // check that the width/height and bitDepth are matched to the best
    if ((bestWidth == (int)CGDisplayModeGetWidth(mode)) && (bestHeight == (int)CGDisplayModeGetHeight(mode)) && (bestBitDepth == getBitDepth(mode)) && (bestFrameRate == thisFrameRate))  {
      // set the video mode
      CGDisplaySetDisplayMode(whichDisplay,mode,NULL);
      retval = true;
    }
  }
  // releast the mode list
  CFRelease(modeList);

  if ((bestWidth != screenWidth) || (bestHeight != screenHeight) || (bestBitDepth != bitDepth) || (bestFrameRate != frameRate)) {
    printDisplayModes(whichDisplay);
    mexPrintf("(mglResolution:setBestMode) No exact mode match found (see avaliable modes printed above). Using closest match: %ix%i %i bits %iHz\n",bestWidth,bestHeight,bestBitDepth,bestFrameRate);
  }

  return(retval);
}


#endif
#else // __cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
////////////////////////
//   define section   //
////////////////////////
#define kMaxDisplays 8

///////////////////////
//   getResolution   //
///////////////////////
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;
  CFDictionaryRef modeInfo;

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglResolution) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  if (verbose)
    mexPrintf("(mglResolution) Found %i displays\n",numDisplays);

  // get the display
  whichDisplay = displays[*displayNumber-1];

  // get the display settings
  *screenWidth=(int)CGDisplayPixelsWide(whichDisplay);
  *screenHeight=(int)CGDisplayPixelsHigh(whichDisplay);
  *bitDepth=(int)CGDisplayBitsPerPixel(whichDisplay);

  // and the refresh rate
  *frameRate = 0;
  modeInfo = CGDisplayCurrentMode(whichDisplay);
  if (modeInfo != NULL) {
    CFNumberRef value = (CFNumberRef)CFDictionaryGetValue(modeInfo, kCGDisplayRefreshRate);
    if (value != NULL)
      CFNumberGetValue(value, kCFNumberIntType, frameRate);
  }
  // assume 60, if the above fails
  if (*frameRate == 0) {
    if (verbose)
      mexPrintf("(mglResolution) Assuming refresh rate of display %i is 60Hz\n",*displayNumber);
    *frameRate = 60;
  }

  if (verbose)
    mexPrintf("(mglResolution) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",*screenWidth,*screenHeight,*frameRate,*bitDepth);
}

///////////////////////
//   setResolution   //
///////////////////////
void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;
  CFDictionaryRef modeInfo;

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglResolution) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  if (verbose)
    mexPrintf("(mglResolution) Found %i displays\n",numDisplays);

  // get the display
  whichDisplay = displays[*displayNumber-1];

  // capture the appropriate display
  //  CGDisplayCapture(whichDisplay);

  // Switch the display mode
  boolean_t success=false;
  CGDisplaySwitchToMode(whichDisplay,CGDisplayBestModeForParametersAndRefreshRate(whichDisplay,*bitDepth,*screenWidth,*screenHeight,*frameRate,&success));

  // check to see if it found the right setting
  if (!success) {
    mexPrintf("(mglResolution) Warning: failed to set requested display parameters.\n");
  }

  // get the display settings
  *screenWidth=(int)CGDisplayPixelsWide(whichDisplay);
  *screenHeight=(int)CGDisplayPixelsHigh(whichDisplay);
  *bitDepth=(int)CGDisplayBitsPerPixel(whichDisplay);

  // and the refresh rate
  int requestedFrameRate = *frameRate;
  *frameRate = 0;
  modeInfo = CGDisplayCurrentMode(whichDisplay);
  if (modeInfo != NULL) {
    CFNumberRef value = (CFNumberRef)CFDictionaryGetValue(modeInfo, kCGDisplayRefreshRate);
    if (value != NULL)
      CFNumberGetValue(value, kCFNumberIntType, frameRate);
  }
  // assume 60, if the above fails
  if (*frameRate == 0) {
    if (verbose)
      mexPrintf("(mglResolution) Assuming refresh rate of display %i has been set to %iHz\n",requestedFrameRate);
    *frameRate = requestedFrameRate;
  }

  if (verbose)
    mexPrintf("(mglResolution) Current display parameters: screenWidth=%i, screenHeight=%i, frameRate=%i, bitDepth=%i\n",*screenWidth,*screenHeight,*frameRate,*bitDepth);

}

//////////////////////////////////
//   getNumDisplaysAndDefault   //
//////////////////////////////////
void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDisplayCount displayCount;
  int i;

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&displayCount);
  *numDisplays = (int)displayCount;

  // check error
  if (displayErrorNum) {
    mexPrintf("(mglResolution) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  // set the defaultDiplayNum to the last in the list of displays
  *defaultDisplayNum = *numDisplays;

  // if the display is the main display, then go look for another one, but
  // make sure to stop at displayNum = 1
  while (CGDisplayIsMain(displays[*defaultDisplayNum-1]) && (*defaultDisplayNum>1))
    *defaultDisplayNum--;
}
#endif //__APPLE__
#endif //__cocoa__


//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////
//   getResolution   //
///////////////////////
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
}
///////////////////////
//   setResolution   //
///////////////////////
void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
}
//////////////////////////////////
//   getNumDisplaysAndDefault   //
//////////////////////////////////
void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum)
{
}
#endif //__linux__


//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32

//BOOL CALLBACK MonitorEnumProc(__in  HMONITOR hMonitor, __in  HDC hdcMonitor,
//  __in  LPRECT lprcMonitor, __in  LPARAM dwData);

//static int displayCount;
//static HMONITOR *monitorList;

// Gets a specified display resolution, frame rate, and bit depth.
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  DISPLAY_DEVICE dd;
  DEVMODE dv;
  int numMonitors, i;

  dd.cb = sizeof(DISPLAY_DEVICE);
  dv.dmSize = sizeof(DEVMODE);
  //displayCount = 0;
  //numMonitors = GetSystemMetrics(SM_CMONITORS);
  //monitorList = (HMONITOR*)malloc(numMonitors * sizeof(HMONITOR));

  if (EnumDisplayDevices(NULL, *displayNumber - 1, &dd, 0x00000001) == FALSE) {
    mexPrintf("(mglResolution) Could not enumerate displays.\n");
    return;
  }

  if (EnumDisplaySettings(dd.DeviceName, ENUM_CURRENT_SETTINGS, &dv) == FALSE) {
    mexPrintf("(mglResolution) Enum display settings failed.\n");
    return;
  }

  *screenWidth = dv.dmPelsWidth;
  *screenHeight = dv.dmPelsHeight;
  *bitDepth = dv.dmBitsPerPel;

  // Set the frame rate to something sensible if we get a crap value.  0 or 1 is returned
  // via the Windows API if the monitor is using the "default" frame rate.
  if (dv.dmDisplayFrequency <= 1) {
    *frameRate = 60;
  }
  else {
    *frameRate = dv.dmDisplayFrequency;
  }
  
//   EnumDisplayMonitors(NULL, NULL, MonitorEnumProc, NULL);
//   
//   for (i = 0; i < displayCount; i++) {
//     MONITORINFOEX mi;
//     
//     mi.cbSize = sizeof(MONITORINFOEX);
//     
//     if (GetMonitorInfo(monitorList[i], ) == FALSE) {
//       mexPrintf("(mglResolution) Cannot get monitor info.\n");
//     }
//     else {
//     }
//   }
//   
//   free(monitorList);
}

// Sets the display resolution.
void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  mexPrintf("(mglResolution) setResolution not implemented for Windows.\n");
  return;
}

// Gets the number of displays and which one is the default.
void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum)
{
  // Get the number of visible displays.
  *numDisplays = GetSystemMetrics(SM_CMONITORS);

  // Set the default display to be the last one.
  *defaultDisplayNum = *numDisplays;
}

// BOOL CALLBACK MonitorEnumProc(__in  HMONITOR hMonitor, __in  HDC hdcMonitor,
//   __in  LPRECT lprcMonitor, __in  LPARAM dwData)
// {
//   mexPrintf("called\n");
//   
//   monitorList[displayCount++] = hMonitor;
//   
//   return TRUE;
// }

#endif // _WIN32
