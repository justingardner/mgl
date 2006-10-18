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
#define TABLESIZE 256
#ifdef __APPLE__
#define SETFIELD(fieldname)\
    mxSetField(plhs[0],0,#fieldname,mxCreateDoubleMatrix(1,1,mxREAL));\
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,#fieldname));\
    *fieldPtr = (double)fieldname
#endif


//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
#ifdef __linux__
  unsigned short *redGammaRamp;
  unsigned short *greenGammaRamp;
  unsigned short *blueGammaRamp;
  int gammaRampSize;
  
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  int screen =XDefaultScreen(dpy);

  XF86VidModeGamma gamma;
  if (!XF86VidModeGetGamma(dpy,screen,&gamma)) {
    mexPrintf("Error getting gamma correction values!");
    return;
  }

  XF86VidModeGetGammaRampSize(dpy,screen,&gammaRampSize);

  // allocate gamma ramps
  redGammaRamp=(unsigned short *) malloc(sizeof(unsigned short)*gammaRampSize);
  greenGammaRamp=(unsigned short *)malloc(sizeof(unsigned short)*gammaRampSize);
  blueGammaRamp=(unsigned short *)malloc(sizeof(unsigned short)*gammaRampSize);

  Bool result=XF86VidModeGetGammaRamp(dpy,screen,gammaRampSize,redGammaRamp,greenGammaRamp,blueGammaRamp);
      
  if (result) {    
    int ndims[] = {1};int nfields = 12;
    const char *field_names[] = {"redMin","redMax","redGamma","greenMin","greenMax","greenGamma","blueMin","blueMax","blueGamma","redTable","greenTable","blueTable"};
    plhs[0] = mxCreateStructArray(1,ndims,nfields,field_names);
    // set all the fields. Note: rewritten to avoid DANGEROUS AND ERROR-PRONE macro.
    double *fieldPtr;
    for (int i=0;i<nfields; i++)
      mxSetField(plhs[0],0,field_names[i],mxCreateDoubleMatrix(1,1,mxREAL));
    *(mxGetPr(mxGetField(plhs[0],0,"redMin")))=0.0;
    *(mxGetPr(mxGetField(plhs[0],0,"greenMin")))=0.0;
    *(mxGetPr(mxGetField(plhs[0],0,"blueMin")))=0.0;
    *(mxGetPr(mxGetField(plhs[0],0,"redMax")))=1.0;
    *(mxGetPr(mxGetField(plhs[0],0,"greenMax")))=1.0;
    *(mxGetPr(mxGetField(plhs[0],0,"blueMax")))=1.0;
    *(mxGetPr(mxGetField(plhs[0],0,"redGamma")))=gamma.red;
    *(mxGetPr(mxGetField(plhs[0],0,"greenGamma")))=gamma.green;
    *(mxGetPr(mxGetField(plhs[0],0,"blueGamma")))=gamma.blue;

    // set the table values
    mxSetField(plhs[0],0,"redTable",mxCreateDoubleMatrix(1,gammaRampSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"redTable"));
    for (int i=0;i<gammaRampSize;i++) fieldPtr[i] = (double)redGammaRamp[i] / 65536;
    mxSetField(plhs[0],0,"greenTable",mxCreateDoubleMatrix(1,gammaRampSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"greenTable"));
    for (int i=0;i<gammaRampSize;i++) fieldPtr[i] = (double)greenGammaRamp[i] / 65536;
    mxSetField(plhs[0],0,"blueTable",mxCreateDoubleMatrix(1,gammaRampSize,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"blueTable"));
    for (int i=0;i<gammaRampSize;i++) fieldPtr[i] = (double)blueGammaRamp[i] / 65536;

  } else {
    mexPrintf("Could not get gamma table values.\n");
  }
  
  free(redGammaRamp);
  free(greenGammaRamp);
  free(blueGammaRamp);
  return;
#endif

#ifdef __APPLE__

  // get globals
  int verbose = (int)mglGetGlobalDouble("verbose");
  int displayNumber;
  if (mglIsGlobal("displayNumber"))
    displayNumber = (int)mglGetGlobalDouble("displayNumber");
  else {
    mexPrintf("(mglGetGammaTable) No display is open\n");
    return;
  }
  
  // check to see if we have an open display
  if (displayNumber < 0) {
    mexPrintf("(mglGetGammaTable) No display is open\n");
    return;
  }
  else {
    // declare variables
    CGLError errorNum;CGDisplayErr displayErrorNum;
    CGDirectDisplayID displays[kMaxDisplays];
    CGDirectDisplayID whichDisplay;
    CGDisplayCount numDisplays;
    int gammaFormula=1;

    // check number of displays
    displayErrorNum = CGGetActiveDisplayList(kMaxDisplays,displays,&numDisplays);
    // see if there was an error getting displays
    if (displayErrorNum) {
      mexPrintf("(mglGetGammaTable) Cannot get displays (%d)\n", displayErrorNum);
      return;
    }

    // get the correct display, making sure that it is in the list
    if (displayNumber > numDisplays) {
      mexPrintf("UHOH (mglGetGammaTable): Display %i out of range (0:%i)\n",displayNumber,numDisplays);
      return;
    }
    // if we are in window mode, use main display
    else if (displayNumber == 0)
      whichDisplay = kCGDirectMainDisplay;
    else
      whichDisplay = displays[displayNumber-1];

    // ok, now we know the displya, get the gamma values
    CGGammaValue redMin,redMax,redGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma;

    // get the formula values
    errorNum = CGGetDisplayTransferByFormula(whichDisplay,&redMin,&redMax,&redGamma,&greenMin,&greenMax,&greenGamma,&blueMin,&blueMax,&blueGamma);

    // if we get an error, assume that the reason is because
    // the gamma table is not set by formula
    if (errorNum) {
      gammaFormula = 0;
    }

    // and get the gamma table
    CGTableCount capacity=TABLESIZE, sampleCount;
    CGGammaValue redTable[TABLESIZE],greenTable[TABLESIZE],blueTable[TABLESIZE];
    errorNum = CGGetDisplayTransferByTable(whichDisplay,TABLESIZE,redTable,greenTable,blueTable,&sampleCount);
    if (errorNum) {
      mexPrintf("(mglGetGammaTable) UHOH: Error getting gamma table (error=%d)\n",errorNum);
    }

    // make the output structure, if we gamma formula values then
    // make the structure with those fields and set them, otherwise
    // only output the gamma tables
    double *fieldPtr;int i;
    if (gammaFormula) {
      int ndims[] = {1};int nfields = 12;
      const char *field_names[] = {"redMin","redMax","redGamma","greenMin","greenMax","greenGamma","blueMin","blueMax","blueGamma","redTable","greenTable","blueTable"};
      plhs[0] = mxCreateStructArray(1,ndims,nfields,field_names);
      // set all the fields, using a macro
      SETFIELD(redMin);SETFIELD(redMax);SETFIELD(redGamma);
      SETFIELD(greenMin);SETFIELD(greenMax);SETFIELD(greenGamma);
      SETFIELD(blueMin);SETFIELD(blueMax);SETFIELD(blueGamma);
    }
    else {
      int ndims[] = {1};int nfields = 3;
      const char *field_names[] = {"redTable","greenTable","blueTable"};
      plhs[0] = mxCreateStructArray(1,ndims,nfields,field_names);
    }
    // set the table values
    mxSetField(plhs[0],0,"redTable",mxCreateDoubleMatrix(1,sampleCount,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"redTable"));
    for (i=0;i<sampleCount;i++) fieldPtr[i] = (double)redTable[i];
    mxSetField(plhs[0],0,"greenTable",mxCreateDoubleMatrix(1,sampleCount,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"greenTable"));
    for (i=0;i<sampleCount;i++) fieldPtr[i] = (double)greenTable[i];
    mxSetField(plhs[0],0,"blueTable",mxCreateDoubleMatrix(1,sampleCount,mxREAL));
    fieldPtr = (double*)mxGetPr(mxGetField(plhs[0],0,"blueTable"));
    for (i=0;i<sampleCount;i++) fieldPtr[i] = (double)blueTable[i];
  }
#endif
}
