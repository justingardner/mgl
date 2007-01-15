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
#ifdef __linux__
#include <sys/time.h>
#endif

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  int verbose = mglGetGlobalDouble("verbose");

  // mxArray *mxGetCell(const mxArray *pm, mwIndex index);

  int nkeys,i;
  if (nrhs == 1 && (mxGetData(prhs[0]) != NULL) && mxIsCell(prhs[0])) {
    // input is a cell array of chars
    // calculate size of array
    nkeys=mxGetNumberOfElements(prhs[0]);
    for (i=0;i<nkeys;i++) {
      if (!mxIsChar(mxGetCell(prhs[0],i)))
	usageError("mglCharToKeycode");
    }
  } else {
    usageError("mglCharToKeycode");
  }
  plhs[0] = mxCreateDoubleMatrix(1,nkeys,mxREAL);


#ifdef __APPLE__

  // Because Apple is too lazy to provide a reverse KeyTranslate function this code is unnecessarily complex.

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

  char *c;
  for (i=0; i<nkeys; i++) {
    int j;
    c=mxArrayToString(mxGetCell(prhs[0],i));
    
    // Check if correspondence
    *(mxGetPr( plhs[0] )+i)=-1;
    for (j=0; j<128; j++) {      
      if (strncasecmp(c, &(keycode2str[j][0]), 1)==0 || strncasecmp(c, &(keycode2str[j][1]), 1)==0) {
	*(mxGetPr( plhs[0] )+i) = (double) j + 1; // note we add 1-offset to make it correspond to output of mglGetKeys
	break;
      }
    }
    mxFree(c);
  }
  
  

#endif

#ifdef __linux__
  
  Display * dpy;
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }

  double *optr=mxGetPr( plhs[0] );
  char *c;
  for (int i=0; i<nkeys; i++) {
    c=mxArrayToString(mxGetCell(prhs[0],i));    

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
  
#endif 

}

