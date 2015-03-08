#ifdef documentation
=========================================================================

     program: mglPrivateSetGammaTable.c
          by: justin gardner. Bug fixes and X support by Jonas Larsson
        date: 05/27/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: set the gamma table

$Id$
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
#ifdef _WIN32
#define GAMMAVALUE WORD
#define GAMMAVALUESIZE sizeof(WORD)
#define MAXGAMMAVALUE 65535

// We need to make sure the Windows values are rounded to the nearest integer value
// otherwise when the the passed values are converted to type WORD, they'll be merely
// floored since a integer type cast of a double typically just slices off the decimal part.
// We can simulate rounding by adding 0.5 and flooring via type conversion.
#define ROUND(x) x + 0.5
#endif

#ifdef __linux__
#define GAMMAVALUE unsigned short
#define GAMMAVALUESIZE sizeof(unsigned short)
#define MAXGAMMAVALUE 65535

// Defined to satisfy interworkings with Windows.  It might be useful
// to round properly in Linux, but I'll leave that up to the Linux coder. (CGB)
#define ROUND(x) x
#endif

#ifdef __APPLE__
#define GAMMAVALUE CGGammaValue
#define GAMMAVALUESIZE sizeof(CGGammaValue)
#define MAXGAMMAVALUE 1

// Does nothing, only defined because it's needed for
// Windows and possibly Linux.
#define ROUND(x) x
#endif

/////////////////////////
//   OS Specific calls //
/////////////////////////
// sets the gamma table with a formula (this is there because the cards offer it, but I suspect
// noone uses this feature? -jg)
void setGammaTableWithFormula(int displayNumber, int verbose, double redMin, double redMax, double redGamma, double greenMin,double greenMax,double greenGamma,double blueMin,double blueMax, double blueGamma);
// This method is the more used one, sets the table with table values.
void setGammaTableWithTable(int displayNumber, int verbose, int gammaTableSize, int numTableEntries, GAMMAVALUE *redTable,GAMMAVALUE *greenTable,GAMMAVALUE *blueTable);
// this function returns how big the gamma table is
int getGammaTableSize(int displayNumber);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // default to return false
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
  *(double*)mxGetPr(plhs[0]) = 0;

  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");
  int displayNumber;
  int existDisplayNumber = mglIsGlobal("displayNumber");
  if (existDisplayNumber)
    displayNumber = (int)mglGetGlobalDouble("displayNumber");
  else {
    mexPrintf("(mglPrivateSetGammaTable) No display is open\n");
    return;
  }

  // and some variables
  double redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma;
  int useFormula = 0;
  double *redInputTable,*greenInputTable,*blueInputTable,*inputTable;
  int numTableEntries = 0,i,rowOffset,tableEntrySize = 0;
  int gammaTableSize;
  int isColumnOrdered;

  // get the size of the gamma table
  gammaTableSize = getGammaTableSize(displayNumber);
  
  // with no inputs just returns size of gamma table
  // for use with the m file that will check the input
  // table against the size and interpolate if necessary
  if (nrhs == 0) {
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *(double*)mxGetPr(plhs[0]) = (double)gammaTableSize;
    return;
  }

  if (verbose)
    mexPrintf("(mglPrivateSetGammaTable) Setting gamma table for display %i\n",displayNumber);

  GAMMAVALUE *redTable=(GAMMAVALUE *)malloc(GAMMAVALUESIZE*gammaTableSize);
  GAMMAVALUE *greenTable=(GAMMAVALUE *)malloc(GAMMAVALUESIZE*gammaTableSize);
  GAMMAVALUE *blueTable=(GAMMAVALUE *)malloc(GAMMAVALUESIZE*gammaTableSize);

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
      // Get values from struct
      if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using input structure\n");
      mxArray *redInputArray, *greenInputArray, *blueInputArray;
      redInputArray = mxGetField(prhs[0],0,"redTable");
      greenInputArray = mxGetField(prhs[0],0,"greenTable");
      blueInputArray = mxGetField(prhs[0],0,"blueTable");
      // now check to see if everything is ok.
      if ((redInputArray == NULL) || (greenInputArray == NULL) || (blueInputArray == NULL)) {
        mexPrintf("(mglPrivateSetGammaTable) Table structure must have redTable, greenTable and blueTable\n");
        return;
      }
      numTableEntries = mxGetN(redInputArray);
      // and check that they are the right length
      if ((mxGetN(greenInputArray)!=numTableEntries) || (mxGetN(blueInputArray)!=numTableEntries)) {
        mexPrintf("(mglPrivateSetGammaTable) Tables in structure must all have have the same %i elements\n",numTableEntries);
        return;
      }
      // now get the ponters
      redInputTable = (double *)mxGetPr(redInputArray);
      greenInputTable = (double *)mxGetPr(greenInputArray);
      blueInputTable = (double *)mxGetPr(blueInputArray);
      // now set the table
      for (i=0;i<numTableEntries;i++) {
        redTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*redInputTable[i]);
        greenTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*greenInputTable[i]);
        blueTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*blueInputTable[i]);
      }
    } // if (mxIsStruct(prhs[0]))
    else {  // Not a struct.
      // Get values from vector/array input
      // get size of table and table pointer
      // allow the user o pass either a row or column vector
      numTableEntries = mxGetN(prhs[0]);
      tableEntrySize = mxGetM(prhs[0]);
      rowOffset = 3;
      isColumnOrdered = 0; // Row ordered gamma.
      if (numTableEntries < tableEntrySize) {
        numTableEntries = mxGetM(prhs[0]);
        rowOffset = numTableEntries;
        tableEntrySize = mxGetN(prhs[0]);
        isColumnOrdered = 1; // Column ordered gamma.
      }
        
      if (verbose)
        mexPrintf("(mglPrivateSetGammaTable) %ix%i\n",numTableEntries,tableEntrySize);
      inputTable = (double *)mxGetPr(prhs[0]);
      // if the table size is 9 then this means that we are setting
      // by formula
      if ((tableEntrySize == 1) && (numTableEntries == 9)) {
        useFormula = 1;
        // set the function values
        redMin = inputTable[0];redMax = inputTable[1];redGamma = inputTable[2];
        greenMin = inputTable[3];greenMax = inputTable[4];greenGamma = inputTable[5];
        blueMin = inputTable[6];blueMax = inputTable[7];blueGamma = inputTable[8];
      }
      // looks like it is not a formula, see what kind of table it is
      else {
        if (tableEntrySize == 1) {
          if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using same table for RGB\n");
          if (verbose) mexPrintf("(mglPrivateSetGammaTable) numTableEntries = %i\n",numTableEntries);
          if (numTableEntries != gammaTableSize) {
            mexPrintf("(mglPrivateSetGammaTable) System is reporting a gamma table with %i etnries and you set one with %i entries. Not setting gamma table\n",gammaTableSize,numTableEntries);
            return;
          }
          // and set the tables from the input table
          for (i=0;i<numTableEntries;i++) {
            redTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i]);
            greenTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i]);
            blueTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i]);
          }
        }
        else if (tableEntrySize == 3) {          
          if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using different tables for RGB\n");
          if (verbose) mexPrintf("(mglPrivateSetGammaTable) numTableEntries = %i\n",numTableEntries);
          if (numTableEntries != gammaTableSize) {
            mexPrintf("(mglPrivateSetGammaTable) System is reporting a gamma table with %i etnries and you set one with %i entries. Not setting gamma table\n",gammaTableSize,numTableEntries);
            return;
          }
          
          // Set the individual RGB tables from the input table.  How things are indexed 
          // out of the input table depends on if the input table is column or row ordered.
          if (isColumnOrdered) { // Column ordered
            for (i=0;i<numTableEntries;i++) {
              redTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i]);
              greenTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i+rowOffset]);
              blueTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i+2*rowOffset]);
            }
          }
          else { // Row ordered
            for (i=0; i < numTableEntries; i++) {
              redTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i*rowOffset]);
              greenTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i*rowOffset + 1]); 
              blueTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*inputTable[i*rowOffset + 2]);
            }
          }
        }
        else {
          mexPrintf("(mglPrivateSetGammaTable) Gamma table should be %ix1 or %ix3 (%ix%i)\n",\
            gammaTableSize,gammaTableSize,mxGetM(prhs[0]),mxGetN(prhs[0]));
          return;
        }
      } // if ((tableEntrySize == 1) && (numTableEntries == 9))
    } // if (mxIsStruct(prhs[0]))
  } // if (nrhs == 1)
  else if (nrhs == 3) {
    if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using different tables for RGB\n");
    // get size of table
    numTableEntries = mxGetN(prhs[0]);
    if ((numTableEntries != mxGetN(prhs[1])) || (numTableEntries != mxGetN(prhs[2]))) {
      mexPrintf("(mglPrivateSetGammaTable) All three tables should be of same length\n");
      return;
    }
    // display some info
    if (verbose) mexPrintf("(mglPrivateSetGammaTable) numTableEntries = %i\n",numTableEntries);
    if (numTableEntries != gammaTableSize) {
      mexPrintf("(mglPrivateSetGammaTable) System is reporting a gamma table with %i etnries and you set one with %i entries. Not setting gamma table\n",gammaTableSize,numTableEntries);
      return;
    }
    // get table pointer
    redInputTable = (double *)mxGetPr(prhs[0]);
    greenInputTable = (double *)mxGetPr(prhs[1]);
    blueInputTable = (double *)mxGetPr(prhs[2]);
    // and set the tables fom the input tables
    for (i=0;i<numTableEntries;i++) {
      redTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*redInputTable[i]);
      greenTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*greenInputTable[i]);
      blueTable[i] = (GAMMAVALUE)ROUND(MAXGAMMAVALUE*blueInputTable[i]);
    }
  }
  
  // display information about formula if we are using one
  if (verbose && useFormula) 
    mexPrintf("(mglPrivateSetGammaTable) Using function %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f %0.2f\n",redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);

  // check to see if we have an open display
  if (displayNumber < 0) {
    mexPrintf("(mglPrivateSetGammaTable) No display is open\n");
    return;
  }
  
  // Now, actually set the gamma table with the OS specific calls
  if (useFormula)
    setGammaTableWithFormula(displayNumber, verbose, redMin, redMax, redGamma, greenMin, greenMax, greenGamma, blueMin, blueMax, blueGamma);
  else
    setGammaTableWithTable(displayNumber, verbose, gammaTableSize, numTableEntries, redTable, greenTable, blueTable);

  // free storage
  free(redTable);
  free(greenTable);
  free(blueTable);
  
  // retun true
  *(double*)mxGetPr(plhs[0]) = 1;
}


//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
///////////////////////////////////
//   setGammatTableWithFormula   //
///////////////////////////////////
void setGammaTableWithFormula(int displayNumber, int verbose, double redMin, double redMax, double redGamma, double greenMin,double greenMax,double greenGamma,double blueMin,double blueMax, double blueGamma)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglPrivateSetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }
  // get the correct display, making sure that it is in the list
  else if (displayNumber > numDisplays) {
    mexPrintf("(mglPrivateSetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
    return;
  }
  else if (displayNumber == 0)
    whichDisplay = kCGDirectMainDisplay;
  else
    whichDisplay = displays[displayNumber-1];
    

  // now, we have found the display, set gamma table by formula
  if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using formula\n");
  displayErrorNum = CGSetDisplayTransferByFormula(whichDisplay,redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);

  if (displayErrorNum) {
    mexPrintf("(mglPrivateSetGammaTable) Error setting gamma table (%s num=%i)\n",CGLErrorString(displayErrorNum),displayErrorNum);
  }
}
////////////////////////////////
//   setGammaTableWithTable   //
////////////////////////////////
void setGammaTableWithTable(int displayNumber, int verbose, int gammaTableSize, int numTableEntries, GAMMAVALUE *redTable,GAMMAVALUE *greenTable,GAMMAVALUE *blueTable)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglPrivateSetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
    return;
  }
  // get the correct display, making sure that it is in the list
  else if (displayNumber > numDisplays) {
    mexPrintf("(mglPrivateSetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
    return;
  }
  else if (displayNumber == 0)
    whichDisplay = kCGDirectMainDisplay;
  else
    whichDisplay = displays[displayNumber-1];
    
  if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using table\n");
  displayErrorNum = CGSetDisplayTransferByTable(whichDisplay,numTableEntries,redTable,greenTable,blueTable);

  if (displayErrorNum) {
    mexPrintf("(mglPrivateSetGammaTable) Error setting gamma table (%s num=%i)\n",CGLErrorString(displayErrorNum),displayErrorNum);
  }
}
///////////////////////////
//   getGammaTableSize   //
///////////////////////////
int getGammaTableSize(int displayNumber)
{
  CGDisplayErr displayErrorNum;
  CGDirectDisplayID displays[kMaxDisplays];
  CGDirectDisplayID whichDisplay;
  CGDisplayCount numDisplays;

  // check number of displays
  displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
  if (displayErrorNum) {
    mexPrintf("(mglPrivateSetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
    return(0);
  }
  // get the correct display, making sure that it is in the list
  else if (displayNumber > numDisplays) {
    mexPrintf("(mglPrivateSetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
    return(0);
  }
  else if (displayNumber == 0)
    whichDisplay = kCGDirectMainDisplay;
  else
    whichDisplay = displays[displayNumber-1];
    
  return(CGDisplayGammaTableCapacity(whichDisplay));
}
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////////////////
//   setGammatTableWithFormula   //
///////////////////////////////////
void setGammaTableWithFormula(int displayNumber, int verbose, double redMin, double redMax, double redGamma, double greenMin,double greenMax,double greenGamma,double blueMin,double blueMax, double blueGamma)
{
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);

  if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using formula\n");
  XF86VidModeGamma gamma;
  gamma.red=redGamma;
  gamma.green=greenGamma;
  gamma.blue=blueGamma;
  if (!XF86VidModeSetGamma(dpy,screen,&gamma)) {
    mexPrintf("(mglPrivateSetGammaTable) Error setting gamma table.\n");
  }
  // seems necessary to call this function to update settings
  XFlush(dpy);
}
////////////////////////////////
//   setGammaTableWithTable   //
////////////////////////////////
void setGammaTableWithTable(int displayNumber, int verbose, int gammaTableSize, int numTableEntries, GAMMAVALUE *redTable,GAMMAVALUE *greenTable,GAMMAVALUE *blueTable)
{
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);
  if (verbose) mexPrintf("(mglPrivateSetGammaTable) Using table\n");
  if (!XF86VidModeSetGammaRamp(dpy,screen,gammaTableSize,redTable,greenTable,blueTable)) {
    mexPrintf("(mglPrivateSetGammaTable) Error setting gamma table.\n");
  }
}

///////////////////////////
//   getGammaTableSize   //
///////////////////////////
int getGammaTableSize(int displayNumber)
{    
  int gammaTableSize;
  // On Linux/X, we can query the hardware for gamma table to be safe
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);
  XF86VidModeGetGammaRampSize(dpy,screen,&gammaTableSize);
  return(gammaTableSize);
}
#endif//__linux__


//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
void setGammaTableWithTable(int displayNumber, int verbose, int gammaTableSize, int numTableEntries,
                            GAMMAVALUE *redTable, GAMMAVALUE *greenTable, GAMMAVALUE *blueTable)
{
  int i;
  MGL_CONTEXT_PTR ref;
  HDC hDC;
  GAMMAVALUE ramp[256*3];
  
  // Grab the current device context.
  ref = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winDeviceContext");
  hDC = (HDC)ref;
  
  // Copy the gamma components into the giant data structure we'll pass to the Windows API.
  for (i = 0; i < 256; i++) {
    //mexPrintf("rval %d: %d\n", i, redTable[i]);
    ramp[i] = redTable[i];
    ramp[i+256] = blueTable[i];
    ramp[i+512] = greenTable[i];
  }
  
  if (SetDeviceGammaRamp(hDC, ramp) == FALSE) {
    mexPrintf("(mglPrivateSetGammaTable) Failed to set gamma table.\n");
  }
}

void setGammaTableWithFormula(int displayNumber, int verbose, double redMin, double redMax, double redGamma, double greenMin,double greenMax,double greenGamma,double blueMin,double blueMax, double blueGamma)
{
  mexPrintf("(mglSetGammaRamp) Setting gamma with a formula is not supported at this time.\n");
}

int getGammaTableSize(int displayNumber)
{
  return 256;
}
#endif
