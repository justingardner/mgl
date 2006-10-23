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

#ifdef __APPLE__
  int longNum;int bitNum;int logicalNum = 0;
  //  get the status of the keyboard
  KeyMap theKeys;
  GetKeys( theKeys );
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
      displayKey = (int)*(inptr+i);
      if ((displayKey < 0) || (displayKey > 128)) {
	mexPrintf("(mglGetKeys) Key %i out of range 1:128",displayKey);
	return;
      }
      k=(short)displayKey;

#if (__LITTLE_ENDIAN__)
      // mac intel requires some swapping
      div_t keypos = div(displayKey-1,32);
      UInt32 currkeys =  theKeys[keypos.quot].bigEndianValue; 
      UInt32 keyposrem = keypos.rem;
      *(outptr+i) = (currkeys >> keyposrem ) & 0x1 ;
#else
      // on big-endian OSX there are no problems
      // *(outptr+i) =  (theKeys[keypos.quot] >> keypos.rem ) & 0x1 ;
      *(outptr+i) = ((keybytes[k>>3] & (1 << (k&7))) != 0);
      
#endif
    }
  }
  else {
    // return it in a logical array
    plhs[0] = mxCreateLogicalMatrix(1,128);
    mxLogical *outptr = mxGetLogicals(plhs[0]);
   
    // set the elements of the logical array correctly
    if (verbose) {
      mexPrintf("(mglGetKeys) Keystate = ");
    }
#if (__LITTLE_ENDIAN__)

    for (longNum = 0;longNum<4;longNum++) {
      for (bitNum = 0;bitNum<32;bitNum++) {
	// mac intel requires some swapping
	UInt32 currkeys = theKeys[longNum].bigEndianValue ;
	UInt32 currbitnum = bitNum; 
	*(outptr+logicalNum++) = (currkeys >> currbitnum) & 0x1 ;
	if (verbose) {
	  mexPrintf("%i ",(int) *(outptr+logicalNum++));
	}
      }
    }
#else
    // no problems on big-endian
    for (i=0;i<128;i++) {
      k=(short)i;
      *(loutptr+i)=((keybytes[k>>3] & (1 << (k&7))) != 0);
      if (verbose) {
	mexPrintf("%i ",(int) *(loutptr+i));
      }
    }
    // *(outptr+logicalNum++) = (theKeys[longNum] >> bitNum) & 0x1;
#endif
    if (verbose) {
      mexPrintf("\n");
    }
  }
  
#endif
#ifdef __linux__
  mexPrintf("(mglGetKeys) Not supported yet on linux\n");
  return;
#endif 
}

