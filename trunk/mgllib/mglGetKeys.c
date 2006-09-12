#ifdef documentation
=========================================================================

     program: mglGetKeys.c
          by: justin gardner
        date: 09/12/06
     purpose: return state of keyboard

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
  //  get the status of the keyboard
  KeyMap theKeys;
  GetKeys(theKeys);

  // return it in a logical array
  plhs[0] = mxCreateLogicalMatrix(1,128);
  mxLogical *outptr = mxGetLogicals(plhs[0]);
   
  // set the elements of the logical array correctly
  int longNum;int bitNum;int logicalNum = 0;
  for (longNum = 0;longNum<4;longNum++) {
    for (bitNum = 0;bitNum<32;bitNum++) {
      *(outptr+logicalNum++) = (theKeys[longNum] >> bitNum) & 0x1;
    }
  }

  // and display the same if verbose is set
  int verbose = mglGetGlobalDouble("verbose");
  if (verbose) {
    mexPrintf("(mglGetKeys) Keystate = ");
    for (longNum=0;longNum<4;longNum++) {
      for (bitNum = 0;bitNum<32;bitNum++) {
	mexPrintf("%i ",(theKeys[longNum] >> bitNum) & 0x1);
      }
    }
    mexPrintf("\n");
  }
}

