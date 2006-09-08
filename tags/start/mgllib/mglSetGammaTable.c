#ifdef documentation
=========================================================================

     program: mglSetGammaTable.c
          by: justin gardner
        date: 05/27/06

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

////////////////////////
//   define section   //
////////////////////////
#define kMaxDisplays 8
#define TABLESIZE 256

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");
  int displayNumber;
  if (mglIsGlobal("displayNumber"))
    displayNumber = (int)mglGetGlobalDouble("displayNumber");
  else {
    mexPrintf("(mglSetGammaTable) No display is open\n");
    return;
  }

  if (verbose)
    mexPrintf("(mglSetGammaTable) Setting gamma table for display %i\n",displayNumber);

  // and some variables
  double redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma;
  int useFormula = 0;
  CGGammaValue redTable[TABLESIZE],greenTable[TABLESIZE],blueTable[TABLESIZE];
  double *redInputTable,*greenInputTable,*blueInputTable,*inputTable;
  int tableSize = 0,i;

  // nine arguments means to set formula
  if (nrhs == 9) {
    useFormula = 1;
    // get formula values
    redMin = *(double*)mxGetPr(prhs[0]);
    redMax = *(double*)mxGetPr(prhs[1]);
    redGamma = *(double*)mxGetPr(prhs[2]);
    greenMin = *(double*)mxGetPr(prhs[3]);
    greenMax = *(double*)mxGetPr(prhs[4]);
    greenGamma = *(double*)mxGetPr(prhs[5]);
    blueMin = *(double*)mxGetPr(prhs[6]);
    blueMax = *(double*)mxGetPr(prhs[7]);
    blueGamma = *(double*)mxGetPr(prhs[8]);
  }
  // one argument means that there is one table for
  // all three colors, or if it is a 9 vector then a vector for 
  // formula or if it nx3 then a table for all three colors
  // if it is as struct then see if it is the one returned
  // from mxGetGammaTable and use the red, green, and blue tables
  // form that
  else if (nrhs == 1) {
    if (mxIsStruct(prhs[0])) {
      if (verbose) mexPrintf("(mglSetGammaTable) Using input structure\n");
      mxArray *redInputArray, *greenInputArray, *blueInputArray;
      redInputArray = mxGetField(prhs[0],0,"redTable");
      greenInputArray = mxGetField(prhs[0],0,"greenTable");
      blueInputArray = mxGetField(prhs[0],0,"blueTable");
      // now check to see if everything is ok.
      if ((redInputArray == NULL) || (greenInputArray == NULL) || (blueInputArray == NULL)) {
	mexPrintf("(mglSetGammaTable) Table structure must have redTable, greenTable and blueTable\n");
	return;
      }
      tableSize = mxGetN(redInputArray);
      // and check that they are the right length
      if ((mxGetN(greenInputArray)!=tableSize) || (mxGetN(blueInputArray)!=tableSize)) {
	mexPrintf("(mglSetGammaTable) Tables in structure must all have have the same %i elements\n",tableSize);
	return;
      }
      // now get the ponters
      redInputTable = (double *)mxGetPr(redInputArray);
      greenInputTable = (double *)mxGetPr(greenInputArray);
      blueInputTable = (double *)mxGetPr(blueInputArray);
      // now set the table
      for (i=0;i<tableSize;i++) {
	redTable[i] = (CGGammaValue)redInputTable[i];
	greenTable[i] = (CGGammaValue)greenInputTable[i];
	blueTable[i] = (CGGammaValue)blueInputTable[i];
      }
    }
    else {
      // get size of table and table pointer
      tableSize = mxGetM(prhs[0]);
      inputTable = (double *)mxGetPr(prhs[0]);
      // if the table size is 9 then this means that we are setting
      // by formula
      if ((mxGetM(prhs[0]) == 1) && (mxGetN(prhs[0]) == 9)) {
	useFormula = 1;
	// set the function values
	redMin = inputTable[0];redMax = inputTable[1];redGamma = inputTable[2];
	greenMin = inputTable[3];greenMax = inputTable[4];greenGamma = inputTable[5];
	blueMin = inputTable[6];blueMax = inputTable[7];blueGamma = inputTable[8];
      }
      // looks like it is not a formula, see what kind of table it is
      else {
	if (mxGetN(prhs[0]) == 1) {
	  if (verbose) mexPrintf("(mglSetGammaTable) Using same table for RGB\n");
	  if (verbose) mexPrintf("(mglSetGammaTable) tableSize = %i\n",tableSize);
	  if (tableSize > TABLESIZE) {
	    mexPrintf("(mglSetGammaTable) UHOH: Table size too large (n=%i)\n",tableSize);
	    return;
	  }
	  // and set the tables from the input table
	  for (i=0;i<tableSize;i++) {
	    redTable[i] = (CGGammaValue)inputTable[i];
	    greenTable[i] = (CGGammaValue)inputTable[i];
	    blueTable[i] = (CGGammaValue)inputTable[i];
	  }
	}
	else if (mxGetN(prhs[0]) == 3) {
	  if (verbose) mexPrintf("(mglSetGammaTable) Using different tables for RGB\n");
	  if (verbose) mexPrintf("(mglSetGammaTable) tableSize = %i\n",tableSize);
	  if (tableSize > TABLESIZE) {
	    mexPrintf("(mglSetGammaTable) UHOH: Table size too large (n=%i)\n",tableSize);
	    return;
	  }
	  // and set the tables from the input table
	  for (i=0;i<tableSize;i++) {
	    redTable[i] = (CGGammaValue)inputTable[i];
	    greenTable[i] = (CGGammaValue)inputTable[i+tableSize];
	    blueTable[i] = (CGGammaValue)inputTable[i+2*tableSize];
	  }
	}
	else {
	  mexPrintf("(mglSetGammaTable) UHOH: Gamma table should be nx1 or nx3 (%ix%i)\n",mxGetM(prhs[0]),mxGetN(prhs[0]));
	  return;
	}
      }
    }
  }
  else if (nrhs == 3) {
    if (verbose) mexPrintf("(mglSetGammaTable) Using differnet tables for RGB\n");
    // get size of table
    tableSize = mxGetN(prhs[0]);
    if ((tableSize != mxGetN(prhs[1])) || (tableSize != mxGetN(prhs[2]))) {
      mexPrintf("(mglSetGammaTable) UHOH: All three tables should be of same length\n");
      return;
    }
    // display some info
    if (verbose) mexPrintf("(mglSetGammaTable) tableSize = %i\n",tableSize);
    if (tableSize > TABLESIZE) {
      mexPrintf("(mglSetGammaTable) UHOH: Table size too large (n=%i)\n",tableSize);
      return;
    }
    // get table pointer
    redInputTable = (double *)mxGetPr(prhs[0]);
    greenInputTable = (double *)mxGetPr(prhs[1]);
    blueInputTable = (double *)mxGetPr(prhs[2]);
    // and set the tables fom the input tables
    for (i=0;i<tableSize;i++) {
      redTable[i] = (CGGammaValue)redInputTable[i];
      greenTable[i] = (CGGammaValue)greenInputTable[i];
      blueTable[i] = (CGGammaValue)blueInputTable[i];
    }
  }
  
  // display information about formula if we are using one
  if (verbose && useFormula) 
    mexPrintf("(mglSetGammaTable) Using function %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f\n",redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);

  ////////////////////////////////////////////////////////////
  // Here on is the code that actually sets the gamma table
  // This needs to be OS specific
  ////////////////////////////////////////////////////////////
  // check to see if we have an open display
  if (displayNumber < 0) {
    mexPrintf("(mglSetGammaTable) No display is open\n");
    return;
  }
  else {
#ifdef __APPLE__
    CGLError errorNum;CGDisplayErr displayErrorNum;
    CGDirectDisplayID displays[kMaxDisplays];
    CGDirectDisplayID whichDisplay;
    CGDisplayCount numDisplays;

    // check number of displays
    displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
    if (displayErrorNum) {
      mexPrintf("(mglSetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
      return;
    }
    // get the correct display, making sure that it is in the list
    else if (displayNumber > numDisplays) {
      mexPrintf("UHOH (mglSetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
      return;
    }
    else if (displayNumber == 0)
      whichDisplay = kCGDirectMainDisplay;
    else
      whichDisplay = displays[displayNumber-1];
    

    // now, we have found the display, set gamma table by formula or table
    if (useFormula) {
      if (verbose) mexPrintf("(mglSetGammaTable) Using formula\n");
      errorNum = CGSetDisplayTransferByFormula(whichDisplay,redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);
    }
    else {
      if (verbose) mexPrintf("(mglSetGammaTable) Using table\n");
      errorNum = CGSetDisplayTransferByTable(whichDisplay,tableSize,redTable,greenTable,blueTable);
    }

    if (errorNum) {
      mexPrintf("(mglSetGammaTable) UHOH: Error setting gamma table (%s num=%i)\n",CGLErrorString(errorNum),errorNum);
    }
#endif
  }
}
