#ifdef documentation
=========================================================================

  program:
  mglResolution.c
  by:
  justin gardner
  date:
  12/27/08
  copyright:
  (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose:
  set the resolution/refresh rate of a monitor

  $Id:
  mglPrivateOpen.c,v 1.14 2007/10/25 20:
  31:
  43 justin Exp $
  =========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

///////////////////////////////
//   function declarations   //
///////////////////////////////
    void mglPrivateOpenOnExit(void);

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
  int outDims[2] = {1, 1};

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
      mexPrintf("(mglPrivateOpen) Could not set display parameters to [%ix%i], frameRate: %i bitDepth: %i\n                 Display parameters are set to: [%ix%i], frameRate=%i, bitDepth=%i\n",requestedScreenWidth,requestedScreenHeight,requestedFrameRate,requestedBitDepth,screenWidth,screenHeight,frameRate,bitDepth);
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

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
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
    mexPrintf("(mglPrivateOpen) Warning: failed to set requested display parameters.\n");
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
#ifdef __WINDOWS__
void getResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
  DISPLAY_DEVICE dd;
  DEVMODE dv;

  dd.cb = sizeof(DISPLAY_DEVICE);
  dv.dmSize = sizeof(DEVMODE);

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
}

void setResolution(int *displayNumber, int *screenWidth, int *screenHeight, int *frameRate, int *bitDepth)
{
}

void getNumDisplaysAndDefault(int *numDisplays, int *defaultDisplayNum)
{
  // Get the number of visible displays.
  *numDisplays = GetSystemMetrics(SM_CMONITORS);

  // Set the default display to be the last one.
  *defaultDisplayNum = *numDisplays;
}
#endif // __WINDOWS__
