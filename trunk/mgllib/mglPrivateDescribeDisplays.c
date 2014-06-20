#ifdef documentation
=========================================================================

     program: mglDescribeDisplays.c
          by: Christopher Broussard
        date: 10/29/07
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Returns information about available displays.

$Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#ifndef _WIN32
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

////////////////////////
//   define section   //
////////////////////////
#define kMaxDisplays 8
#define kNumDisplayStructFields 17
#define kNumComputerStructFields 9
#define kMaxStrLen 32
#define kSysctlStrLen 256


//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
  CGLError errorNum;
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;
  mxArray *displayStruct, *computerStruct;
  char **displayStructFieldNames, **computerStructFieldNames, sysctlStr[kSysctlStrLen];
  int i, sysctlName[2], sysctlInt;
  unsigned int sysctlUInt;
  size_t sysctlDataLen;
  uint64_t sysctlHugeInt;

  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays, displays, &numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglPrivateDescribeDisplays) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }

  // Initialize the display structure fields.
  displayStructFieldNames = (char**)mxMalloc(kNumDisplayStructFields * sizeof(char*));
  for (i = 0; i < kNumDisplayStructFields; i++) {
    displayStructFieldNames[i] = (char*)mxMalloc(kMaxStrLen * sizeof(char));
  }
  strcpy(displayStructFieldNames[0], "isMain");
  strcpy(displayStructFieldNames[1], "modelNumber");
  strcpy(displayStructFieldNames[2], "screenSizeMM");
  strcpy(displayStructFieldNames[3], "screenSizePixel");
  strcpy(displayStructFieldNames[4], "serialNumber");
  strcpy(displayStructFieldNames[5], "vendorNumber");
  strcpy(displayStructFieldNames[6], "refreshRate");
  strcpy(displayStructFieldNames[7], "openGLacceleration");
  strcpy(displayStructFieldNames[8], "unitNumber");
  strcpy(displayStructFieldNames[9], "isStereo");
  strcpy(displayStructFieldNames[10], "bitsPerPixel");
  strcpy(displayStructFieldNames[11], "bitsPerSample");
  strcpy(displayStructFieldNames[12], "samplesPerPixel");
  strcpy(displayStructFieldNames[13], "isCaptured");
  strcpy(displayStructFieldNames[14], "gammaTableWidth");
  strcpy(displayStructFieldNames[15], "gammaTableLength");
  strcpy(displayStructFieldNames[16], "displayBounds");

  // Initialize the computer structure fields.
  computerStructFieldNames = (char**)mxMalloc(kNumComputerStructFields * sizeof(char*));
  for (i = 0; i < kNumComputerStructFields; i++) {
    computerStructFieldNames[i] = (char*)mxMalloc(kMaxStrLen * sizeof(char));
  }
  strcpy(computerStructFieldNames[0], "machineClass");
  strcpy(computerStructFieldNames[1], "machineModel");
  strcpy(computerStructFieldNames[2], "numCPUs");
  strcpy(computerStructFieldNames[3], "physicalMemory");
  strcpy(computerStructFieldNames[4], "hostName");
  strcpy(computerStructFieldNames[5], "busFrequency");
  strcpy(computerStructFieldNames[6], "cpuFrequency");
  strcpy(computerStructFieldNames[7], "OSType");
  strcpy(computerStructFieldNames[8], "OSRelease");

  // Create the structs.
  displayStruct = mxCreateStructMatrix(1, (mwSize)numDisplays, kNumDisplayStructFields, (const char**)displayStructFieldNames);
  if (displayStruct == NULL) {
    mexPrintf("(mglPrivateDescribeDisplays) cannot create display struct\n");
    return;
  }
  computerStruct = mxCreateStructMatrix(1, 1, kNumComputerStructFields, (const char**)computerStructFieldNames);
  if (computerStruct == NULL) {
    mexPrintf("(mglPrivateDescribeDisplays) cannot create computer struct\n");
    return;
  }

  // Get all the display info.
  for (i = 0; i < numDisplays; i++) {
    CGSize sizeVal;
    CFDictionaryRef modeInfo;
    CFMutableDictionaryRef properties;
    kern_return_t kr;
    mxArray *m;
    double *ptr;
    double bitsPerPixel = 0,bitsPerSample = 0,samplesPerPixel = 0;
    int refreshRate = 60; // Assume LCD screen.

    // Grab the IOKit service for the display.
    io_service_t displayService = CGDisplayIOServicePort(displays[i]);

    //#define MACOS106
#ifdef __MAC_10_6
    // get the displayMode for this display
    CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(displays[i]);

    // get bit depth
    CFStringRef pixelEncoding;
    pixelEncoding = CGDisplayModeCopyPixelEncoding(displayMode);
    // return an appropriate bit depth for each one of these strings
    // defined in IOGraphicsTypes.h
    if (CFStringCompare(pixelEncoding,CFSTR(IO32BitDirectPixels),0)==kCFCompareEqualTo) {
      bitsPerPixel = 32;
      bitsPerSample = 8;
      samplesPerPixel = 3;
    }
    else if (CFStringCompare(pixelEncoding,CFSTR(IO16BitDirectPixels),0)==kCFCompareEqualTo) {
      bitsPerPixel = 16;
      bitsPerSample = 5;
      samplesPerPixel = 3;
    }
    else if (CFStringCompare(pixelEncoding,CFSTR(IO8BitIndexedPixels),0)==kCFCompareEqualTo) {
      bitsPerPixel = 8;
      bitsPerSample = 8;
      samplesPerPixel = 3;
    }
    else if (CFStringCompare(pixelEncoding,CFSTR(kIO30BitDirectPixels),0)==kCFCompareEqualTo) {
      bitsPerPixel = 30;
      bitsPerSample = 10;
      samplesPerPixel = 3;
    }
    else if (CFStringCompare(pixelEncoding,CFSTR(kIO64BitDirectPixels),0)==kCFCompareEqualTo) {
      bitsPerPixel = 64;
      bitsPerSample = 16;
      samplesPerPixel = 3;
    }
    // release the pixel encoding
    CFRelease(pixelEncoding);

    // get refreshRate
    refreshRate = (int)CGDisplayModeGetRefreshRate(displayMode);

    // release the display settings
    CGDisplayModeRelease(displayMode);
#else
    // get number of bits per pixel
    bitsPerPixel = (double)CGDisplayBitsPerPixel(displays[i]);
    // get number of bits per each color
    bitsPerSample = (double)CGDisplayBitsPerSample(displays[i]);
    // get number of colors
    samplesPerPixel = (double)CGDisplaySamplesPerPixel(displays[i]);
    // Get the refresh rate.
    modeInfo = CGDisplayCurrentMode(displays[i]);
    if (modeInfo != NULL) {
      CFNumberRef value = (CFNumberRef)CFDictionaryGetValue(modeInfo, kCGDisplayRefreshRate);
      if (value) CFNumberGetValue(value, kCFNumberIntType, &refreshRate);
    }
#endif

    // Determine if display is the main display.
    mxSetField(displayStruct, i, "isMain", mxCreateDoubleScalar((double)CGDisplayIsMain(displays[i])));

    // Set the model number.
    mxSetField(displayStruct, i, "modelNumber", mxCreateDoubleScalar((double)CGDisplayModelNumber(displays[i])));
		
    // Set the serial number.
    mxSetField(displayStruct, i, "serialNumber", mxCreateDoubleScalar((double)CGDisplaySerialNumber(displays[i])));
		
    // Set the vendor number.
    mxSetField(displayStruct, i, "vendorNumber", mxCreateDoubleScalar((double)CGDisplayVendorNumber(displays[i])));
		
    // Set whether the display uses OpenGL acceleration (Quartz Extreme) to render.
    mxSetField(displayStruct, i, "openGLacceleration", mxCreateDoubleScalar((double)CGDisplayUsesOpenGLAcceleration(displays[i])));
		
    // Set the unit number which represents a particular node in the I/O Kit device tree associated with the display?s frame buffer.
    mxSetField(displayStruct, i, "unitNumber", mxCreateDoubleScalar((double)CGDisplayUnitNumber(displays[i])));
    
    // Set whether a display is running in a stereo graphics mode.
    mxSetField(displayStruct, i, "isStereo", mxCreateDoubleScalar((double)CGDisplayIsStereo(displays[i])));
    
    // Set whether a display is captured.
    mxSetField(displayStruct, i, "isCaptured", mxCreateDoubleScalar((double)CGDisplayIsCaptured(displays[i])));
    
    // Set bits per pixel.
    mxSetField(displayStruct, i, "bitsPerPixel", mxCreateDoubleScalar(bitsPerPixel));
    
    // Set the number of bits used to represent a pixel component in the frame buffer
    mxSetField(displayStruct, i, "bitsPerSample", mxCreateDoubleScalar(bitsPerSample));
    
    // Set the number of color components used to represent a pixel.
    mxSetField(displayStruct, i, "samplesPerPixel", mxCreateDoubleScalar(samplesPerPixel));
    
    // Screen size in millimeters.
    sizeVal = CGDisplayScreenSize(displays[i]);
    m = mxCreateDoubleMatrix(1, 2, mxREAL);
    ptr = mxGetPr(m);
    ptr[0] = (double)sizeVal.width; ptr[1] = (double)sizeVal.height;
    mxSetField(displayStruct, i, "screenSizeMM", m);
    
    // Screen size in pixels.
    m = mxCreateDoubleMatrix(1, 2, mxREAL);
    ptr = mxGetPr(m);
    ptr[0] = (double)CGDisplayPixelsWide(displays[i]); ptr[1] = (double)CGDisplayPixelsHigh(displays[i]);
    mxSetField(displayStruct, i, "screenSizePixel", m);
  
    // set refesh rate, default to 60
    if (refreshRate == 0) refreshRate = 60;
    mxSetField(displayStruct, i, "refreshRate", mxCreateDoubleScalar((double)refreshRate));
#ifndef __cocoa__
    // Get the gamma table width and length.
    kr = IORegistryEntryCreateCFProperties(displayService, &properties, NULL, 0);
    if (kr == kIOReturnSuccess) {
      // If successful, we can query if the device supports the keys we are interested in
      // In this case we are going to check for the kIOFBGammaWidthKey and kIOFBGammaCountKey
      // keys to see what the gamma table's width and size is.
      CFNumberRef cfGammaWidth = (CFNumberRef)CFDictionaryGetValue(properties, CFSTR(kIOFBGammaWidthKey));
      if (cfGammaWidth != NULL) {
        SInt32 width;
        CFNumberGetValue(cfGammaWidth, kCFNumberSInt32Type, &width);
        mxSetField(displayStruct, i, "gammaTableWidth", mxCreateDoubleScalar((double)width));
      }
      CFNumberRef cgGammaLength = (CFNumberRef)CFDictionaryGetValue(properties, CFSTR(kIOFBGammaCountKey));
      if (cgGammaLength != NULL) {
        SInt32 length;
        CFNumberGetValue(cgGammaLength, kCFNumberSInt32Type, &length);
        mxSetField(displayStruct, i, "gammaTableLength", mxCreateDoubleScalar((double)length));
      }
      CFRelease(properties);
    }
#else//__cocoa__
    mxSetField(displayStruct, i, "gammaTableLength", mxCreateDoubleScalar((double)CGDisplayGammaTableCapacity(displays[i])));
#endif
    // get display bounds
    CGRect displayBounds = CGDisplayBounds(displays[i]);
    m = mxCreateDoubleMatrix(1, 4, mxREAL);
    ptr = mxGetPr(m);
    ptr[0] = (double)displayBounds.origin.x;
    ptr[1] = (double)displayBounds.origin.y;
    ptr[2] = (double)displayBounds.size.width;
    ptr[3] = (double)displayBounds.size.height;
    mxSetField(displayStruct, i, "displayBounds", m);

  } // End for (i = 0; i < numDisplays; i++)

  // Get the machine class.
  sysctlDataLen = sizeof(char) * kSysctlStrLen;
  sysctlbyname("hw.machine", sysctlStr, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "machineClass", mxCreateString(sysctlStr));
	
  // Get the machine model.
  sysctlDataLen = sizeof(char) * kSysctlStrLen;
  sysctlbyname("hw.model", sysctlStr, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "machineModel", mxCreateString(sysctlStr));
	
  // Get the number of CPUs.
  sysctlDataLen = sizeof(int);
  sysctlbyname("hw.ncpu", &sysctlInt, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "numCPUs", mxCreateDoubleScalar((double)sysctlInt));
	
  // Get the bus frequency.
  sysctlName[0] = CTL_HW; sysctlName[1] = HW_BUS_FREQ;
  sysctlDataLen = sizeof(int);
  //sysctlbyname("hw.busfrequency", &sysctlInt, &sysctlDataLen, NULL, 0);
  sysctl(sysctlName, 2, &sysctlInt, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "busFrequency", mxCreateDoubleScalar((double)sysctlInt/1000000.0));
	
  // Get the amount of physical memory in megabytes.
  sysctlName[1] = HW_MEMSIZE;
  sysctlDataLen = sizeof(uint64_t);
  sysctl(sysctlName, 2, &sysctlHugeInt, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "physicalMemory", mxCreateDoubleScalar((double)sysctlHugeInt/1024.0/1024.0));

  // Get the cpu frequency in megahertz.
  sysctlName[1] = HW_CPU_FREQ;
  sysctlDataLen = sizeof(unsigned int);
  sysctl(sysctlName, 2, &sysctlUInt, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "cpuFrequency", mxCreateDoubleScalar((double)sysctlUInt/1000000.0));

  // Get the hostname of the system.
  sysctlName[0] = CTL_KERN; sysctlName[1] = KERN_HOSTNAME;
  sysctlDataLen = sizeof(char) * kSysctlStrLen;
  sysctl(sysctlName, 2, sysctlStr, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "hostName", mxCreateString(sysctlStr));

  // Get the OS version.
  sysctlName[1] = KERN_OSTYPE;
  sysctlDataLen = sizeof(char) * kSysctlStrLen;
  sysctl(sysctlName, 2, sysctlStr, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "OSType", mxCreateString(sysctlStr));

  // Get the OS release.
  sysctlName[1] = KERN_OSRELEASE;
  sysctlDataLen = sizeof(char) * kSysctlStrLen;
  sysctl(sysctlName, 2, sysctlStr, &sysctlDataLen, NULL, 0);
  mxSetField(computerStruct, 0, "OSRelease", mxCreateString(sysctlStr));

  plhs[0] = displayStruct;
  plhs[1] = computerStruct;
#else //__APPLE__
  // no info, just return empty
  plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  plhs[1] = mxCreateDoubleMatrix(0,0,mxREAL);
#endif //__APPLE__
}
