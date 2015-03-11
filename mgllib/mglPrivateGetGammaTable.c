#ifdef documentation
=========================================================================

     program: mglGetGammaTable.c
          by: justin gardner
        date: 05/27/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

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
#define GAMMARANGE 65536
#define Bool int
#endif
#ifdef __linux__
#define GAMMAVALUE unsigned short
#define GAMMAVALUESIZE sizeof(unsigned short)
#define GAMMARANGE 65536
#endif
#ifdef __APPLE__
#define GAMMAVALUE CGGammaValue
#define GAMMARANGE 1
#define GAMMAVALUESIZE sizeof(CGGammaValue)
#define Bool int
#endif

/////////////////////////
//   OS Specific calls //
/////////////////////////
// Gets the gamma tbale
Bool getGammaTable(int *gammaTableSize, GAMMAVALUE **redTable,GAMMAVALUE **greenTable,GAMMAVALUE **blueTable);
// Gets the gamma function values
Bool getGammaFormula(GAMMAVALUE *redMin,GAMMAVALUE *redMax,GAMMAVALUE *redGamma,GAMMAVALUE *greenMin,GAMMAVALUE *greenMax,GAMMAVALUE *greenGamma,GAMMAVALUE *blueMin,GAMMAVALUE *blueMax,GAMMAVALUE *blueGamma);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  GAMMAVALUE *redTable, *greenTable, *blueTable;
  int gammaTableSize;
  Bool result,formulaResults;
  int i;
  GAMMAVALUE redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma;

  // get the gamma tbale
  result = getGammaTable(&gammaTableSize, &redTable,&greenTable,&blueTable);
  formulaResults = getGammaFormula(&redMin,&redMax,&redGamma,&greenMin,&greenMax,&greenGamma,&blueMin,&blueMax,&blueGamma);

  if (result) {    
    mwSize ndims[] = {1};int nFormulaFields = 9;int nTableFields = 3;
    const char *formulaFieldNames[] = {"redMin","redMax","redGamma","greenMin","greenMax","greenGamma","blueMin","blueMax","blueGamma","redTable","greenTable","blueTable"};
    const char *tableFieldNames[] = {"redTable","greenTable","blueTable"};
    if (formulaResults)
      plhs[0] = mxCreateStructArray(1,ndims,nFormulaFields+nTableFields,formulaFieldNames);
    else
      plhs[0] = mxCreateStructArray(1,ndims,nTableFields,tableFieldNames);
      
    // set the formula fields if there are any
    double *fieldPtr;
    if (formulaResults) {
      for (i=0;i<nFormulaFields; i++) {
	mxSetField(plhs[0],0,formulaFieldNames[i],mxCreateDoubleMatrix(1,1,mxREAL));
      }
      *(mxGetPr(mxGetField(plhs[0],0,"redMin")))=redMin;
      *(mxGetPr(mxGetField(plhs[0],0,"greenMin")))=greenMin;
      *(mxGetPr(mxGetField(plhs[0],0,"blueMin")))=blueMin;
      *(mxGetPr(mxGetField(plhs[0],0,"redMax")))=redMax;
      *(mxGetPr(mxGetField(plhs[0],0,"greenMax")))=greenMax;
      *(mxGetPr(mxGetField(plhs[0],0,"blueMax")))=blueMax;
      *(mxGetPr(mxGetField(plhs[0],0,"redGamma")))=redGamma;
      *(mxGetPr(mxGetField(plhs[0],0,"greenGamma")))=greenGamma;
      *(mxGetPr(mxGetField(plhs[0],0,"blueGamma")))=blueGamma;
    }
    // set the table fields
    for (i=0;i<nTableFields; i++)
      mxSetField(plhs[0],0,tableFieldNames[i],mxCreateDoubleMatrix(1,1,mxREAL));
    // set the table values
    mxSetField(plhs[0],0,"redTable",mxCreateDoubleMatrix(1,gammaTableSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"redTable"));
    for (i=0;i<gammaTableSize;i++) fieldPtr[i] = (double)redTable[i] / GAMMARANGE;
    mxSetField(plhs[0],0,"greenTable",mxCreateDoubleMatrix(1,gammaTableSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"greenTable"));
    for (i=0;i<gammaTableSize;i++) fieldPtr[i] = (double)greenTable[i] / GAMMARANGE;
    mxSetField(plhs[0],0,"blueTable",mxCreateDoubleMatrix(1,gammaTableSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"blueTable"));
    for (i=0;i<gammaTableSize;i++) fieldPtr[i] = (double)blueTable[i] / GAMMARANGE;

    // free the table
    free(redTable);
    free(greenTable);
    free(blueTable);
  } 
  else {
    mexPrintf("(mglGetGammaTable) Could not get gamma table values.\n");
    // return empty
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
  return;
}

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
///////////////////////
//   getGammaTable   //
///////////////////////
Bool getGammaTable(int *gammaTableSize, GAMMAVALUE **redTable,GAMMAVALUE **greenTable,GAMMAVALUE **blueTable)
{
  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");
  int displayNumber;
  int existDisplayNumber  = mglIsGlobal("displayNumber");
  if (existDisplayNumber){
    displayNumber = (int)mglGetGlobalDouble("displayNumber");
  }
  else {
    mexPrintf("(mglGetGammaTable) No display is open (exist: %i)\n", existDisplayNumber);
    return(0);
  }
  
  // check to see if we have an open display
  if (displayNumber < 0) {
    mexPrintf("(mglGetGammaTable) No display is open ** \n");
    return(0);
  }
  else {
    // declare variables
    CGDisplayErr displayErrorNum;
    CGDirectDisplayID displays[kMaxDisplays];
    CGDirectDisplayID whichDisplay;
    CGDisplayCount numDisplays;
    int gammaFormula=1;

    // check number of displays
    displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
    // see if there was an error getting displays
    if (displayErrorNum) {
      mexPrintf("(mglGetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
      return(0);
    }

    // get the correct display, making sure that it is in the list
    if (displayNumber > numDisplays) {
      mexPrintf("(mglGetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
      return(0);
    }
    // if we are in window mode, use main display
    else if (displayNumber == 0)
      whichDisplay = kCGDirectMainDisplay;
    else
      whichDisplay = displays[displayNumber-1];
    
    // get the size of the gamma table
    *gammaTableSize = (int)CGDisplayGammaTableCapacity(whichDisplay);

    // allocate gamma tables
    *redTable=(GAMMAVALUE *) malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));
    *greenTable=(GAMMAVALUE *)malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));
    *blueTable=(GAMMAVALUE *)malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));

    // and get the gamma table
    uint32_t capacity=*gammaTableSize, sampleCount;

    displayErrorNum = CGGetDisplayTransferByTable(whichDisplay,*gammaTableSize,*redTable,*greenTable,*blueTable,&sampleCount);
    if (displayErrorNum) {
      mexPrintf("(mglGetGammaTable) Error getting gamma table (error=%d)\n",displayErrorNum);
    }
  }
  return(1);
}

/////////////////////////
//   getGammaFormula   //
/////////////////////////
Bool getGammaFormula(GAMMAVALUE *redMin,GAMMAVALUE *redMax,GAMMAVALUE *redGamma,GAMMAVALUE *greenMin,GAMMAVALUE *greenMax,GAMMAVALUE *greenGamma,GAMMAVALUE *blueMin,GAMMAVALUE *blueMax,GAMMAVALUE *blueGamma)
{
  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");
  int displayNumber;
  int existDisplayNumber  = mglIsGlobal("displayNumber");
  if (existDisplayNumber){
    displayNumber = (int)mglGetGlobalDouble("displayNumber");
  }
  else {
    return(0);
  }
  
  // check to see if we have an open display
  if (displayNumber < 0) {
    return(0);
  }
  else {
    // declare variables
    CGDisplayErr displayErrorNum;
    CGDirectDisplayID displays[kMaxDisplays];
    CGDirectDisplayID whichDisplay;
    CGDisplayCount numDisplays;
    int gammaFormula=1;

    // check number of displays
    displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
    // see if there was an error getting displays
    if (displayErrorNum) {
      return(0);
    }

    // get the correct display, making sure that it is in the list
    if (displayNumber > numDisplays) {
      return(0);
    }
    // if we are in window mode, use main display
    else if (displayNumber == 0)
      whichDisplay = kCGDirectMainDisplay;
    else
      whichDisplay = displays[displayNumber-1];

    // get the formula values
    displayErrorNum = CGGetDisplayTransferByFormula(whichDisplay,redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);

    // if we get an error, assume that the reason is because
    // the gamma table is not set by formula
    if (displayErrorNum) {
      return(0);
    }

  }
  return(1);
}
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////////
//   getGammaTable   //
///////////////////////
Bool getGammaTable(int *gammaTableSize, GAMMAVALUE **redTable,GAMMAVALUE **greenTable,GAMMAVALUE *mgl*blueTable)
{
  int gammaTableSize;
  
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);

  XF86VidModeGetGammaRampSize(dpy,screen,&gammaTableSize);

  // allocate gamma ramps
  *redTable=(GAMMAVALUE *) malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));
  *greenTable=(GAMMAVALUE *)malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));
  *blueTable=(GAMMAVALUE *)malloc(sizeof(GAMMAVALUE)*(*gammaTableSize));

  Bool result=XF86VidModeGetGammaRamp(dpy,screen,*gammaTableSize,*redTable,*greenTable,*blueTable);

  return(result);
}      
/////////////////////////
//   getGammaFormula   //
/////////////////////////
Bool getGammaFormula(GAMMAVALUE *redMin,GAMMAVALUE *redMax,GAMMAVALUE *redGamma,GAMMAVALUE *greenMin,GAMMAVALUE *greenMax,GAMMAVALUE *greenGamma,GAMMAVALUE *blueMin,GAMMAVALUE *blueMax,GAMMAVALUE *blueGamma)
{
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);

  XF86VidModeGamma gamma;
  if (!XF86VidModeGetGamma(dpy,screen,&gamma)) {
    mexPrintf("Error getting gamma correction values!");
    return(0);
  }

  // set function values
  *redMin = 0;*redMax = 1.0;*redGamma = gamma.red;
  *greenMin = 0;*greenMax = 1.0;*greenGamma = gamma.green;
  *blueMin = 0;*blueMax = 1.0;*blueGamma = gamma.blue.;
  return(1);
}
#endif//__linux__


//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef _WIN32
Bool getGammaTable(int *gammaTableSize, GAMMAVALUE **redTable, GAMMAVALUE **greenTable, GAMMAVALUE **blueTable)
{
  HDC hDC;
  MGL_CONTEXT_PTR ref;
  int i;
  GAMMAVALUE ramp[256*3];
  
  *gammaTableSize = 256;
  
  // Allocate the memory for the gamma ramps.
  *redTable = (GAMMAVALUE*) malloc(sizeof(GAMMAVALUE) * (*gammaTableSize));
  *greenTable = (GAMMAVALUE*)malloc(sizeof(GAMMAVALUE) * (*gammaTableSize));
  *blueTable = (GAMMAVALUE*)malloc(sizeof(GAMMAVALUE) * (*gammaTableSize));
  
  // Grab the current device context.
  ref = (MGL_CONTEXT_PTR)mglGetGlobalDouble("winDeviceContext");
  hDC = (HDC)ref;
  
  if (GetDeviceGammaRamp(hDC, ramp) == TRUE) {
    for (i = 0; i < 256; i++) {
      (*redTable)[i] = ramp[i];
      (*blueTable)[i] = ramp[i+256];
      (*greenTable)[i] = ramp[i+512];
    }
  }
  else {
    mexPrintf("(mglGetGammaTable) Could not get gamma table.\n");
    return 0;
  }
  
  return 1;
}

Bool getGammaFormula(GAMMAVALUE *redMin,GAMMAVALUE *redMax,GAMMAVALUE *redGamma,GAMMAVALUE *greenMin,GAMMAVALUE *greenMax,GAMMAVALUE *greenGamma,GAMMAVALUE *blueMin,GAMMAVALUE *blueMax,GAMMAVALUE *blueGamma)
{
  return 0;
}
#endif //_WIN32
