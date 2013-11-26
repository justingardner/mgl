#ifdef documentation
=========================================================================

     program: mglPrivateKeycodeToChar.c
          by: Jonas Larsson
        date: 09/12/06
     purpose: return the (first) char corresponding to a keycode.  
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////////////////
//   OS Specific calls //
/////////////////////////
// This function converts the cell array of chars into
// an array of keycodes
mxArray *keycodeToChar(const mxArray *arrayOfKeycodes);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  int verbose = (int)mglGetGlobalDouble("verbose");

  size_t nkeys;
	int i;

  if ((nrhs == 1) && (mxGetPr(prhs[0]) != NULL)) {
    nkeys = mxGetNumberOfElements(prhs[0]);
  }
  else if ((nrhs==1) && (mxGetPr(prhs[0]) == NULL)) {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
  else {
    usageError("mglKeycodeToChar");
    return;
  }

  plhs[0] = keycodeToChar(prhs[0]);
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
///////////////////////
//   keycodeToChar   //
///////////////////////
mxArray *keycodeToChar(const mxArray *arrayOfKeycodes)
{
  UInt32 keyboard_type = 0;
  const void *chr_data = NULL;
  UInt32 deadKeyState = 0;
  UniCharCount maxStringLength = 8,actualStringLength;
  UniChar unicodeString[8];
  int nkeys,keyNum;

  // init the output array
  nkeys=mxGetNumberOfElements(arrayOfKeycodes);
  mxArray *out=mxCreateCellMatrix(1,nkeys);

  // get the current keyboard "layout input source"
  TISInputSourceRef currentKeyLayoutRef = TISCopyCurrentKeyboardLayoutInputSource();
  // and the keyboard type
  keyboard_type = LMGetKbdType ();
  // now get the unicode key layout data
  if (currentKeyLayoutRef) {
    CFDataRef currentKeyLayoutDataRef = (CFDataRef )TISGetInputSourceProperty(currentKeyLayoutRef,kTISPropertyUnicodeKeyLayoutData);
    // release the input source
    CFRelease(currentKeyLayoutRef);
    if (currentKeyLayoutDataRef)  
      chr_data = CFDataGetBytePtr(currentKeyLayoutDataRef);
    else {
      mexPrintf("(mglCharToKeycode) Could not get UnicodeKeyLayoutData\n");
      for (keyNum=0; keyNum<nkeys; keyNum++) {
	mexPrintf("keycode: %i\n",(int)*(mxGetPr(arrayOfKeycodes)+keyNum) - 1);
      }
      return(out);
    }
  }
  else {
    mexPrintf("(mglCharToKeycode) Could not get Current Keyboard Layout Input Source\n");
    return(out);
  }

  for (keyNum=0; keyNum<nkeys; keyNum++) {
    // convert double to keycode. We ignore all modifiers.
    UInt16 keycode=(UInt16)*(mxGetPr(arrayOfKeycodes)+keyNum) - 1; // remove 1-offset  

    if ((keycode>=0) && (keycode<=128)) {
      // get the keycode using UCKeyTranslate
      UCKeyTranslate(chr_data,keycode,kUCKeyActionDown,0,keyboard_type,0,&deadKeyState,maxStringLength,&actualStringLength,unicodeString);
    
      mxSetCell(out, keyNum, mxCreateString( (char*)unicodeString ));
    }
  }
  return (out);

}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else //__cocoa__
///////////////////////
//   keycodeToChar   //
///////////////////////
mxArray *keycodeToChar(const mxArray *arrayOfKeycodes)
{

  /*
    Converts a virtual key code to a character code based on a 'KCHR' resource.
    
    UInt32 KeyTranslate (
    const void * transData,
    UInt16 keycode,
    UInt32 * state
    );

    Parameters

    transData

    A pointer to the 'KCHR' resource that you want the KeyTranslate function to use when converting the key code to a character code. 
    keycode

    A 16-bit value that your application should set so that bits 0?6 contain the virtual key code and bit 7 contains either 1 to indicate an up stroke or 0 to indicate a down stroke of the key. Bits 8?15 have the same interpretation as the high byte of the modifiers field of the event structure and should be set according to the needs of your application. 
    state

    A pointer to a value that your application should set to 0 the first time it calls KeyTranslate or any time your application calls KeyTranslate with a different 'KCHR' resource. Thereafter, your application should pass the same value in the state parameter as KeyTranslate returned in the previous call. 

    Return Value
    Discussion

    The KeyTranslate function returns a 32-bit value that gives the character code for the virtual key code specified by the keycode parameter.

    The KeyTranslate function returns the values that correspond to one or possibly two characters that are generated by the specified virtual key code. For example, a given virtual key code might correspond to an alphabetic character with a separate accent character. For example, when the user presses Option-E followed by N, you can map this through the KeyTranslate function using the U.S. 'KCHR' resource to produce ?n, which KeyTranslate returns as two characters in the bytes labeled Character code 1 and Character code 2. If KeyTranslate returns only one character code, it is always in the byte labeled Character code 2. However, your application should always check both bytes labeled Character code 1 and Character code 2 for possible values that map to the virtual key code.

   */

  void *kchr;
  UInt32 state=0;
  KeyboardLayoutRef layout;
  int nkeys,i;


  // init the output array
  nkeys=mxGetNumberOfElements(arrayOfKeycodes);
  mxArray *out=mxCreateCellMatrix(1,nkeys);

  if (KLGetCurrentKeyboardLayout(&layout) != noErr) {
    mexPrintf("Error retrieving current layout\n");
    mxFree(out);
    return;
  }

  //  if (KLGetKeyboardLayoutProperty(layout, kKLKCHRData, const_cast<const void**>(&kchr)) != noErr) {
  if (KLGetKeyboardLayoutProperty(layout, kKLKCHRData, (const void **) (&kchr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    mxFree(out);
    return;
  }

  int bullshitFromSystem=1;
  const void * bullshitFromSystemptr=(void *)&bullshitFromSystem;
  if (KLGetKeyboardLayoutProperty(layout, kKLKind, (&bullshitFromSystemptr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    mxFree(out);
    return;
  }

  char c[2];
  c[1]=0;
  for (i=0; i<nkeys; i++) {
    // convert double to keycode. We ignore all modifiers.
    UInt16 keycode=(UInt16)*(mxGetPr(arrayOfKeycodes)+i) - 1; // remove 1-offset  

    UInt32 charcode=KeyTranslate( kchr, keycode, &state );

    // get byte corresponding to character
    c[0] = (char) (charcode);
    
    mxSetCell(out, i, mxCreateString( c ));
  }
  return (out);
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////
//   keycodeToChar   //
///////////////////////
mxArray *keycodeToChar(const mxArray *arrayOfKeycodes)
{
  
  // Compare the beautiful simplicity of the following code with the Mac horrors above. 
  // Amazing considering that X was developed *before* Apple's API. 

  int nkeys,i;
  Display * dpy;

  // init the output array
  nkeys=mxGetNumberOfElements(arrayOfKeycodes);
  mxArray *out=mxCreateCellMatrix(1,nkeys);


  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }
  
  for (i=0; i<nkeys; i++) {
    KeySym keysym=XKeycodeToKeysym(dpy, (int)*(mxGetPr(arrayOfKeycodes)+i)-1, 0);// remove 1-offset  
    if (keysym!=NoSymbol) 
      mxSetCell(out, i, mxCreateString( XKeysymToString(keysym)));
  }

  if (dpyptr<=0) {
    XCloseDisplay(dpy);
  }
  
  return(out);
}
#endif //__linux__


//---------------------------------------------------------------------------//
// Windows code
//---------------------------------------------------------------------------//
#ifdef _WIN32
mxArray* keycodeToChar(const mxArray *arrayOfKeycodes)
{
	// Initialize the output array.
  size_t nkeys = mxGetNumberOfElements(arrayOfKeycodes);
  mxArray *convertedChars = mxCreateCellMatrix(1, (int)nkeys);

	// Get the data pointer from the mxArray.
	double *data = mxGetPr(arrayOfKeycodes);

	// Get the current keyboard layout.
	HKL keyboardLayout = GetKeyboardLayout(0);

	// Convert all inputed virtual keys into characters.  We subtract the
	// 1 offset assumed by other mgl functions.
	UINT charCode;
	char charString[] = "x";
	for (int i = 0; i < nkeys; i++) {
		charCode = MapVirtualKeyEx((UINT)(data[i] - 1), MAPVK_VK_TO_CHAR, keyboardLayout);

		// Set the output value.
		charString[0] = (char)charCode;
    mxSetCell(convertedChars, i, mxCreateString(charString));
  }

	return convertedChars;
}
#endif

