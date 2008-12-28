#ifdef documentation
=========================================================================

     program: mglGetKeys.c
          by: justin gardner
        date: 09/12/06
     purpose: return state of keyboard
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id$
=========================================================================
#endif



/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int returnAllKeys = 1,i,n,displayKey;
  double *inptr,*outptr;
  // get which key we want
  if (nrhs == 1) {
    inptr = mxGetPr(prhs[0]);
    if (inptr != NULL)
      returnAllKeys = 0;
  }
  else if (nrhs != 0) {
    usageError("mglGetKeys");
    return;
  }
  int verbose = mglGetGlobalDouble("verbose");

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
  int longNum;int bitNum;int logicalNum = 0;
  //  get the status of the keyboard
  KeyMap theKeys;
  GetKeys(theKeys);
  unsigned char *keybytes;
  short k;
  keybytes = (unsigned char *) theKeys;

  if (!returnAllKeys) {
    // figure out how many elements are desired
    n = mxGetN(prhs[0]);
    // and create an output matrix
    plhs[0] = mxCreateDoubleMatrix(1,n,mxREAL);
    outptr = mxGetPr(plhs[0]);
    // now go through and get each key
    for (i=0; i<n; i++) {
      displayKey = (int)*(inptr+i)-1; // 1-offset input
      if ((displayKey < 0) || (displayKey > 128)) {
	mexPrintf("(mglGetKeys) Key %i out of range 1:128",displayKey);
	return;
      }
      k=(short)displayKey;
      *(outptr+i) = ((keybytes[k>>3] & (1 << (k&7))) != 0);
    }
  }
  else {
    // return it in a logical array
    plhs[0] = mxCreateLogicalMatrix(1,128);
    mxLogical *loutptr = mxGetLogicals(plhs[0]);
   
    // set the elements of the logical array correctly
    if (verbose) {
      mexPrintf("(mglGetKeys) Keystate = ");
    }
    for (i=0;i<128;i++) {
      k=(short)i;
      *(loutptr+i)=((keybytes[k>>3] & (1 << (k&7))) != 0);
      if (verbose) {
	mexPrintf("%i ",(int) *(loutptr+i));
      }
    }
    if (verbose) {
      mexPrintf("\n");
    }
  }


#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
  Display * dpy;
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }
  char keys_return[32];

  XQueryKeymap(dpy, keys_return);
  
  if (!returnAllKeys) {
    // figure out how many elements are desired
    n = mxGetN(prhs[0]);
    // and create an output matrix
    plhs[0] = mxCreateDoubleMatrix(1,n,mxREAL);
    outptr = mxGetPr(plhs[0]);
    // now go through and get each key
    for (i=0; i<n; i++) {
      displayKey = (int)*(inptr+i)-1; // input is 1-offset
      if ((displayKey < 0) || (displayKey > 256)) {
	mexPrintf("(mglGetKeys) Key %i out of range 1:256",displayKey);
	return;
      }
      int keypos=(int) floor(displayKey/8);
      int keyshift=displayKey%8;

      *(outptr+i) = (double) (( keys_return[keypos] >> keyshift) & 0x1);
    }
  } else {
    plhs[0] = mxCreateLogicalMatrix(1,256);
    mxLogical *loutptr = mxGetLogicals(plhs[0]);
    
    for (int n=0; n<32; n++) {
      for (int m=0; m<8; m++) {
	*(loutptr+n*8+m) = (double) (( keys_return[n] >> m ) & 0x1);
      }
    }
    if (verbose) {
      mexPrintf("(mglGetKeys) Keystate = ");
      for (int n=0; n<32; n++) {
	for (int m=0; m<8; m++) {
	  mexPrintf("%i ", ( keys_return[n] >> m ) & 0x1 );
	}
      }
      mexPrintf("\n");
    }
  }

  if (dpyptr<=0) {
    XCloseDisplay(dpy);
  }
  


#endif 
}

