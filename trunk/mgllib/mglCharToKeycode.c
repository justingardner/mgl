#ifdef documentation
=========================================================================

     program: mglCharToKeycode.c
          by: Jonas Larsson
        date: 09/12/06
     purpose: return the keycode corresponding to a char
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
// an array of keycodes. If returnAllMatches is set to 1,
// this returns a cell array of arrays of keycodes (since
// some characters like "1" can have multiple keycodes 
// associated with them.
mxArray *charToKeycode(const mxArray *cellArrayOfChars, int returnAllMatches);

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int verbose = (int)mglGetGlobalDouble("verbose");

  // mxArray *mxGetCell(const mxArray *pm, mwIndex index);

  size_t nkeys;
	int i;
  if (((nrhs == 1) || (nrhs == 2))&& mxIsCell(prhs[0])){// && (mxGetPr(prhs[0]) != NULL)) {
    // input is a cell array of chars
    // calculate size of array
    nkeys = mxGetNumberOfElements(prhs[0]);
    for (i=0;i<nkeys;i++) {
      if (!mxIsChar(mxGetCell(prhs[0],i))) {
	usageError("mglCharToKeycode");
	return;
      }
    }
  } else {
    usageError("mglCharToKeycode");
    return;
  }

  // check for a flag to return all keycodes
  int returnAllMatches = 0;
  if (nrhs>1)
    returnAllMatches = (int)mxGetScalar(prhs[1]);

  // convert char cell array to keycodes
  plhs[0] = charToKeycode(prhs[0],returnAllMatches);
}


//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
// Here is the new version, same idea, but slightly different, annoyingly opaque mac OS
// system calls to get keyboard layout (works in 64bit) -j.
///////////////////////
//   charToKeycode   //
///////////////////////
mxArray *charToKeycode(const mxArray *cellArrayOfChars, int returnAllMatches)
{
  UInt32 keyboard_type = 0;
  const void *chr_data = NULL;
  UInt32 deadKeyState = 0;
  UniCharCount maxStringLength = 8,actualStringLength;
  UniChar unicodeString[8];
  int nkeys,keyNum;
  UniChar c;

  nkeys = mxGetNumberOfElements(cellArrayOfChars);

  // allocate space for the output array. If we returning all matches,
  // we need a cell array, otherwise we use a single array
  mxArray *keycodeArray;
  if (returnAllMatches)  {
    const mwSize dims[2] = {1,nkeys};
    keycodeArray = mxCreateCellArray(2,dims);
  }
  else
    keycodeArray = mxCreateDoubleMatrix(1,nkeys,mxREAL);
    
  // get the current keyboard "layout input source"
  TISInputSourceRef currentKeyLayoutRef = TISCopyCurrentKeyboardLayoutInputSource();
  // and the keyboard type
  keyboard_type = LMGetKbdType ();
  // now get the unicode key layout data
  if (currentKeyLayoutRef) {
    CFDataRef currentKeyLayoutDataRef = (CFDataRef )TISGetInputSourceProperty(currentKeyLayoutRef,kTISPropertyUnicodeKeyLayoutData);
    CFRelease(currentKeyLayoutRef);
    if (currentKeyLayoutDataRef) 
      chr_data = CFDataGetBytePtr(currentKeyLayoutDataRef);
    else {
      mexPrintf("(mglCharToKeycode) Could not get UnicodeKeyLayoutData\n");
      return(keycodeArray);
    }
  }
  else {
    mexPrintf("(mglCharToKeycode) Could not get Current Keyboard Layout Input Source\n");
    return(keycodeArray);
  }
  unsigned short virtualKeyCode;

  // allocate space for key matches array, which stores what keys have matched
  unsigned short **matches;
  // need a pointer for each key
  matches = (unsigned short **)malloc(nkeys*sizeof(unsigned short *));
  for (keyNum = 0;keyNum < nkeys; keyNum++){
    // and the maximum possible number of matches is 128 
    matches[keyNum] = (unsigned short *)malloc(129*sizeof(unsigned short));
    // in the first element here, we keep the number of matches
    matches[keyNum][0] = 0;
  }

  // Now lookup all virtual key codes from 0 to 127
  for (virtualKeyCode=0;virtualKeyCode<128;virtualKeyCode++) {
    // This is the key function that does the lookup of what unicodeString 
    // is specified by the virtualKeyCode.
    UCKeyTranslate(chr_data,virtualKeyCode,kUCKeyActionDown,0,keyboard_type,0,&deadKeyState,maxStringLength,&actualStringLength,unicodeString);
    // and see if they match any one of our keys
    for (keyNum=0;keyNum<nkeys;keyNum++) {
      // get the passed in character
      c = tolower((UniChar)*mxArrayToString(mxGetCell(cellArrayOfChars,keyNum)));
      // and check match
      if (c==unicodeString[0]){
	// keep record of all matches
	matches[keyNum][++matches[keyNum][0]] = virtualKeyCode+1;
      }
    }
  }

  // return all the matches
  mxArray *thisMatch;
  int matchNum;
  if (returnAllMatches) {
    for (keyNum = 0;keyNum < nkeys; keyNum++) {
      // create the output array for this key
      thisMatch = mxCreateDoubleMatrix(1,matches[keyNum][0],mxREAL);
      // now put into the output array all the matching codes
      for (matchNum = 0;matchNum < matches[keyNum][0]; matchNum++)
	*(mxGetPr(thisMatch)+matchNum)=(double)(matches[keyNum][matchNum+1]);
      // and put the matching array into the output cell array
      mxSetCell(keycodeArray,keyNum,thisMatch);
	
    }
  }
  else {
    // return just the first match
    for (keyNum = 0;keyNum < nkeys; keyNum++) {
      // see if there was a match
      if (matches[keyNum][0])
	// then return that
	*(mxGetPr( keycodeArray )+keyNum) = (double)(matches[keyNum][1]);
      else
	// otherwise return 0
	*(mxGetPr( keycodeArray )+keyNum) = 0;
    }
  }

   
  // clean up space for key matches
  for (keyNum = 0;keyNum < nkeys; keyNum++)
    free(matches[keyNum]);
  free(matches);


  return(keycodeArray);
}
#else// __cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
///////////////////////
//   charToKeycode   //
///////////////////////
mxArray *charToKeycode(const mxArray *cellArrayOfChars, int returnAllMatches)
{

  // Because Apple is too lazy to provide a reverse KeyTranslate function this code is unnecessarily complex.
  int i,nkeys;
  char keycode2str[128][2]; // conversion table
  void *kchr;
  UInt32 state=0;
  KeyboardLayoutRef layout;
  if (KLGetCurrentKeyboardLayout(&layout) != noErr) {
    mexPrintf("Error retrieving current layout\n");
    return;
  }

  if (KLGetKeyboardLayoutProperty(layout, kKLKCHRData, (const void **) (&kchr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    return;
  }

  int kl=1;
  const void * klptr=(void *)&kl;
  if (KLGetKeyboardLayoutProperty(layout, kKLKind, (&klptr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    return;
  }

  for (i=0; i<128; i++) {
    // convert double to keycode. We ignore all modifiers.
    UInt16 keycode=(UInt16)i;
    UInt32 charcode=KeyTranslate( kchr, keycode, &state );

    // get bytes corresponding to character
    keycode2str[i][0] = (char) (charcode & 0x000000FF);
    keycode2str[i][1] = (char) ((charcode & 0x00FF0000) >> 16);
  
  }
  nkeys = mxGetNumberOfElements(cellArrayOfChars);

  // allocate space for the output array. If we returning all matches,
  // we need a cell array, otherwise we use a single array
  mxArray *keycodeArray;
  if (returnAllMatches)  {
    const mwSize dims[2] = {1,nkeys};
    keycodeArray = mxCreateCellArray(2,dims);
  }
  else
    keycodeArray = mxCreateDoubleMatrix(1,nkeys,mxREAL);

  // allocate space for key matches array, this is for when we return all matches
  unsigned short **matches;
  int keyNum;
  if (returnAllMatches) {
    // need a pointer for each key
    matches = (unsigned short **)malloc(nkeys*sizeof(unsigned short *));
    for (keyNum = 0;keyNum < nkeys; keyNum++){
      // and the maximum possible number of matches is 128 
      matches[keyNum] = (unsigned short *)malloc(129*sizeof(unsigned short));
      // in the first element here, we keep the number of matches
      matches[keyNum][0] = 0;
    }
  }

  char *c;
  for (i=0; i<nkeys; i++) {
    int j;
    c=mxArrayToString(mxGetCell(cellArrayOfChars,i));
    
    // Check if correspondence
    *(mxGetPr( keycodeArray )+i)=-1;
    for (j=0; j<128; j++) {      
      if (strncasecmp(c, &(keycode2str[j][0]), 1)==0 || strncasecmp(c, &(keycode2str[j][1]), 1)==0) {
	if (returnAllMatches) {
	  // keep record of all matches
	  matches[i][++matches[i][0]] = (unsigned short)(j+1);
	}
	else {
	  *(mxGetPr( keycodeArray )+i) = (double) j + 1; // note we add 1-offset to make it correspond to output of mglGetKeys
	  break;
	}
      }
    }
    mxFree(c);
  }

  // return all the matches
  mxArray *thisMatch;
  int matchNum;
  if (returnAllMatches) {
    for (keyNum = 0;keyNum < nkeys; keyNum++) {
      // create the output array for this key
      thisMatch = mxCreateDoubleMatrix(1,matches[keyNum][0],mxREAL);
      // now put into the output array all the matching codes
      for (matchNum = 0;matchNum < matches[keyNum][0]; matchNum++)
	*(mxGetPr(thisMatch)+matchNum)=matches[keyNum][matchNum+1];
      // and put the matching array into the output cell array
      mxSetCell(keycodeArray,keyNum,thisMatch);
	
    }
    // clean up space for key matches
    for (keyNum = 0;keyNum < nkeys; keyNum++)
      free(matches[keyNum]);
    free(matches);
  }

  return(keycodeArray);
}  
#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////
//   charToKeycode   //
///////////////////////
mxArray *charToKeycode(const mxArray *cellArrayOfChars, int returnAllMatches)
{
  Display * dpy;
  int i,nkeys;
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }

  // create output array
  nkeys = mxGetNumberOfElements(cellArrayOfChars);
  mxArray *keycodeArray = mxCreateDoubleMatrix(1,nkeys,mxREAL);
  double *optr=mxGetPr( keycodeArray );
  char *c;
  for (int i=0; i<nkeys; i++) {
    c=mxArrayToString(mxGetCell(cellArrayOfChars,i));    

    // This conversion doesn't work for ASCII characters, uses key names in keysymdef.h which is not platform indep.
    //    KeySym keysym=(KeySym) c[0];
    KeySym keysym=XStringToKeysym( c );
    //    mexPrintf("%i\n",keysym);
    KeyCode keycode=XKeysymToKeycode(dpy, keysym);
    
    if (keycode>0)
      optr[i] = (double) keycode + 1; // note we add 1-offset to make it correspond to output of mglGetKeys
    else
      optr[1]=0;

    mxFree(c);

  }

  if (dpyptr<=0) {
    XCloseDisplay(dpy);
  }
  return(keycodeArray);
}
#endif//__linux__

//---------------------------------------------------------------------------//
// Windows code
//---------------------------------------------------------------------------//
#ifdef _WIN32
mxArray *charToKeycode(const mxArray *cellArrayOfChars, int returnAllMatches)
{
	SHORT vkChar;

  // Get the current keyboard layout.
  HKL keyboardLayout = GetKeyboardLayout(0);
   
  // Get the number of input keys to be converted.
  size_t nkeys = mxGetNumberOfElements(cellArrayOfChars);

	// Allocate the memory for the output array.
  mxArray *keycodeArray = mxCreateDoubleMatrix(1, nkeys, mxREAL);
  double *kaPtr = mxGetPr(keycodeArray);

	// For every input key, convert it to its virtual key representation.
  char *c;
	mxArray *cellEntry;
  for (int i = 0; i < nkeys; i++) {
		// Grab the cell element.
		cellEntry = mxGetCell(cellArrayOfChars, i);
		
		// Get a pointer to the char array in the cell entry.
		c = mxArrayToString(cellEntry);

		// Try to convert the character to the virtual key.
		vkChar = VkKeyScanEx(c[0], keyboardLayout);
		
		// Look for the keycode in the lower byte of the return value.
		vkChar = vkChar & 0x00FF;

	  // Add a 1 offset to correspond to the output of mglGetKeys.
		kaPtr[i] = (double)vkChar + 1.0;

		mxFree(c);
  }

	return keycodeArray;
}
#endif

