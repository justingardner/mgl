#ifdef documentation
=========================================================================

     program: mglPrivateEyelinkEDFRead.c
          by: justin gardner
        date: 04/04/10

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
#include <edf.h>

///////////////////////////////
//   function declarations   //
///////////////////////////////
void dispEventType(int eventType);
void dispEvent(int eventType, ALLF_DATA *event,int verbose);
int isEyeUsedMessage(int eventType, ALLF_DATA *event);
int isMGLV1Message(int eventType, ALLF_DATA *event);
int isMGLV2Message(int eventType, ALLF_DATA *event);
int getMGLV1Message(int eventType, ALLF_DATA *event, int nmsg, double *timePtr,
  double *segmentNumPtr, double *trialNumPtr, double *blockNumPtr, 
  double *phaseNumPtr) ;
int getMGLV2Message(int eventType,ALLF_DATA *event, double *timePtr,
  double *segmentNumPtr, double *trialNumPtr, double *blockNumPtr, 
  double *phaseNumPtr, double *taskIDPtr) ;


////////////////////////
//   define section   //
////////////////////////
#define STRLEN 2048
/* this is a hack, taken from opt.h in the EDF example code */
/* it is undocumented in the EyeLink code */
#define NaN 1e8                  /* missing floating-point values*/

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int err;

  // parse input arguments
  if (nrhs<1) {
    usageError("mglEyelinkEDFRead");
    return;
  }
 
  // get filename
  char filename[STRLEN];
  mxGetString(prhs[0], filename, STRLEN);

  // get verbose
  int verbose = 1;
  if (nrhs >= 2)
    verbose = (int) *mxGetPr(prhs[1]); 

  // open file
  if (verbose) mexPrintf("(mglPrivateEyelinkEDFRead) Opening EDF file %s\n",filename);

  int errval;
  EDFFILE *edf = edf_open_file(filename,verbose,1,1,&errval);
  // and check that we opened correctly
  if (edf == NULL) {
    mexPrintf("(mglPrivateEyelinkEDFRead) Could not open file %s (error %i)\n",filename,errval);
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // initialize some variables
  int i,eventType,numSamples=0,numFix=0,numSac=0,numBlink=0;
  int numMGLTrials=0,numMGLV1Messages=0,numMGLV2Messages=0,mglEyelinkVersion=-1;
  int numMessages = 0;
  int numElements = edf_get_element_count(edf);
  int numTrials = edf_get_trial_count(edf);
  int setGazeCoords = 0;
  ALLF_DATA *data;

  // initialize the output structure
  const char *mglFieldname = "mgl";
  const char *fieldNames[] =  {"filename","numElements","numTrials",
			       "EDFAPI","preamble","gazeLeft","gazeRight",
			       "fixations","saccades","blinks","messages",
			       mglFieldname,"gazeCoords","frameRate"};
  int outDims[2] = {1,1};
  plhs[0] = mxCreateStructArray(1,outDims,14,fieldNames);
  
  // save some info about the EDF file in the output
  mxSetField(plhs[0],0,"filename",mxCreateString(filename));
  mxSetField(plhs[0],0,"numElements",mxCreateDoubleScalar(numElements));
  mxSetField(plhs[0],0,"numTrials",mxCreateDoubleScalar(numTrials));
  mxSetField(plhs[0],0,"EDFAPI",mxCreateString(edf_get_version()));

  // save the preamble
  int preambleLength = edf_get_preamble_text_length(edf);
  char *cbuf = (char *)malloc(preambleLength*sizeof(char));
  edf_get_preamble_text(edf,cbuf,preambleLength);
  mxSetField(plhs[0],0,"preamble",mxCreateString(cbuf));

  // mark beginning of file
  BOOKMARK startOfFile;
  edf_set_bookmark(edf,&startOfFile);

  // count number of samples and events in file
  for (i=0;i<numElements;i++) {
    // get the event type and event pointer
    eventType = edf_get_next_data(edf);
    data = edf_get_float_data(edf);
    if (eventType == SAMPLE_TYPE) numSamples++;
    if (eventType == ENDSACC) numSac++;
    if (eventType == ENDFIX) numFix++;
    if (eventType == ENDBLINK) numBlink++;
    // count MGL messages
    // There are three types of MGL messages
    // version 0 - BEGIN TRIAL only
    // version 1 - BEGIN BLOCK/TRIAL/SEGMENT; NEXT PHASE
    // version 2 - BEGIN with an id vector of BLOCK TRIAL SEGMENT
    if (eventType == MESSAGEEVENT){
      // We'll keep track of all messages in addition to purely MGL ones.
      numMessages++;

      // new style messages
      if (isMGLV2Message(eventType,data)) {
        numMGLV2Messages++;
      }
      // segmented old style messages
      else if (isMGLV1Message(eventType,data)) {
        numMGLV1Messages++;
      }
      // old style messages
      else if (strncmp(&(data->fe.message->c),"MGL BEGIN TRIAL",15) == 0) {
        numMGLTrials++;
      }
    }
  }

  // set to whether to return new or old style MGL messages
  if (numMGLV2Messages>0) {
    mglEyelinkVersion = 2;
  } else if (numMGLV1Messages>0) {
    mglEyelinkVersion = 1;
  } else {
    mglEyelinkVersion = 0;
  }
  
  if (verbose)
    mexPrintf("(mglPrivateEyelinkEDFRead) MGL Version %i messages\n",mglEyelinkVersion);

  // set an output fields for the gaze data
  const char *fieldNamesGaze[] =  {"time","x","y","pupil","pix2degX","pix2degY","velocityX","velocityY","whichEye"};
  int outDims2[2] = {1,1};

  // set gaze left fields
  mxSetField(plhs[0],0,"gazeLeft",mxCreateStructArray(1,outDims2,9,fieldNamesGaze));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"time",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrTimeLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"time"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"x",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrXLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"x"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"y",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrYLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"y"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pupil",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPupilLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pupil"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pix2degX",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPix2DegXLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pix2degX"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pix2degY",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPix2DegYLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"pix2degY"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"velocityX",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrVelXLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"velocityX"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"velocityY",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrVelYLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"velocityY"));
  mxSetField(mxGetField(plhs[0],0,"gazeLeft"),0,"whichEye",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrWhichEyeLeft = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeLeft"),0,"whichEye"));

  // set gaze right fields
  mxSetField(plhs[0],0,"gazeRight",mxCreateStructArray(1,outDims2,9,fieldNamesGaze));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"time",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrTimeRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"time"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"x",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrXRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"x"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"y",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrYRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"y"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"pupil",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPupilRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"pupil"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"pix2degX",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPix2DegXRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"pix2degX"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"pix2degY",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrPix2DegYRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"pix2degY"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"velocityX",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrVelXRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"velocityX"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"velocityY",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrVelYRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"velocityY"));
  mxSetField(mxGetField(plhs[0],0,"gazeRight"),0,"whichEye",mxCreateDoubleMatrix(1,numSamples,mxREAL));
  double *outptrWhichEyeRight = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"gazeRight"),0,"whichEye"));

  // set output fields for fixations
  const char *fieldNamesFix[] =  {"startTime","endTime","aveH","aveV"};
  int outDimsFix[2] = {1,1};
  mxSetField(plhs[0],0,"fixations",mxCreateStructArray(1,outDimsFix,4,fieldNamesFix));
  mxSetField(mxGetField(plhs[0],0,"fixations"),0,"startTime",mxCreateDoubleMatrix(1,numFix,mxREAL));
  double *outptrFixStartTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"fixations"),0,"startTime"));
  mxSetField(mxGetField(plhs[0],0,"fixations"),0,"endTime",mxCreateDoubleMatrix(1,numFix,mxREAL));
  double *outptrFixEndTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"fixations"),0,"endTime"));
  mxSetField(mxGetField(plhs[0],0,"fixations"),0,"aveH",mxCreateDoubleMatrix(1,numFix,mxREAL));
  double *outptrFixAvgH = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"fixations"),0,"aveH"));
  mxSetField(mxGetField(plhs[0],0,"fixations"),0,"aveV",mxCreateDoubleMatrix(1,numFix,mxREAL));
  double *outptrFixAvgV = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"fixations"),0,"aveV"));

  // set output fields for saccades
  const char *fieldNamesSac[] =  {"startTime","endTime","startH","startV","endH","endV","peakVel"};
  int outDimsSac[2] = {1,1};
  mxSetField(plhs[0],0,"saccades",mxCreateStructArray(1,outDimsFix,7,fieldNamesSac));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"startTime",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacStartTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"startTime"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"endTime",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacEndTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"endTime"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"startH",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacStartH = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"startH"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"startV",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacStartV = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"startV"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"endH",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacEndH = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"endH"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"endV",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacEndV = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"endV"));
  mxSetField(mxGetField(plhs[0],0,"saccades"),0,"peakVel",mxCreateDoubleMatrix(1,numSac,mxREAL));
  double *outptrSacPeakVel = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"saccades"),0,"peakVel"));

  // set output fields for blinks
  const char *fieldNamesBlinks[] =  {"startTime","endTime"};
  int outDimsBlinks[2] = {1,1};
  mxSetField(plhs[0],0,"blinks",mxCreateStructArray(1,outDimsBlinks,2,fieldNamesBlinks));
  mxSetField(mxGetField(plhs[0],0,"blinks"),0,"startTime",mxCreateDoubleMatrix(1,numBlink,mxREAL));
  double *outptrBlinkStartTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"blinks"),0,"startTime"));
  mxSetField(mxGetField(plhs[0],0,"blinks"),0,"endTime",mxCreateDoubleMatrix(1,numBlink,mxREAL));
  double *outptrBlinkEndTime = (double *)mxGetPr(mxGetField(mxGetField(plhs[0],0,"blinks"),0,"endTime"));

  // MGL trials
  double *outptrMGLtrial;
  // for version 0, we just have trial markers, and will save those
  if (mglEyelinkVersion == 0) {
    mxSetField(plhs[0],0,mglFieldname,mxCreateDoubleMatrix(2,numMGLTrials,mxREAL));
    outptrMGLtrial = (double *)mxGetPr(mxGetField(plhs[0],0,mglFieldname));
  }
  // for version 1, we have various fields that get set
  else if (mglEyelinkVersion == 1) {
    const char *fieldNamesMGL[] =  {"time","segmentNum","trialNum","blockNum","phaseNum","taskID"};
    int outDims[2] = {1,1};
    mxSetField(plhs[0],0,mglFieldname,mxCreateStructArray(1,outDims,6,fieldNamesMGL));
    // note that we assume sequential task ideas for version 1 and they are provided in v2
  }
  // for version 2, we have various fields that get set
  else if (mglEyelinkVersion == 2){
    const char *fieldNamesMGL[] =  {"time","segmentNum","trialNum","blockNum","phaseNum","taskID"};
    int outDims[2] = {1,1};
    mxSetField(plhs[0],0,mglFieldname,mxCreateStructArray(1,outDims,6,fieldNamesMGL));
  } else { mexErrMsgTxt("Unknown MGL edf version."); }
  
  // Messages
  const char *fieldNamesMessages[] = {"message", "time"};
  int outDimsMessages[2] = {1, numMessages};
  size_t messagesCounter = 0;
  mxArray *messagesStruct = mxCreateStructArray(2, outDimsMessages, 2, fieldNamesMessages);
  mxSetField(plhs[0], 0, "messages", messagesStruct); 

  // gaze coordinates
  mxSetField(plhs[0],0,"gazeCoords",mxCreateDoubleMatrix(1,4,mxREAL));
  double *outptrCoords = (double *)mxGetPr(mxGetField(plhs[0],0,"gazeCoords"));

  // gaze coordinates
  mxSetField(plhs[0],0,"frameRate",mxCreateDoubleMatrix(1,1,mxREAL));
  double *outptrFrameRate = (double *)mxGetPr(mxGetField(plhs[0],0,"frameRate"));

  // go back go beginning of file
  edf_goto_bookmark(edf,&startOfFile);
  
  int currentEye = -1;
  // go through all data in file
  if (verbose) mexPrintf("(mglPrivateEyelinkEDFRead) Looping over samples and events \n");

  for (i=0;i<numElements;i++) {
    // get the event type and event pointer
    eventType = edf_get_next_data(edf);
    data = edf_get_float_data(edf);
    // display event type and info
    if (verbose>3) dispEvent(eventType,data,1); 
    if (verbose>2) dispEventType(eventType);
    if (verbose>1) dispEvent(eventType,data,0); 
    // get samples
    switch(eventType) {
    case SAMPLE_TYPE:
      // copy out left eye
      currentEye = 0;
      *outptrTimeLeft++ = (double)data->fs.time;
      *outptrWhichEyeLeft++ = currentEye;
      if ((int)data->fs.gx[currentEye]==NaN) {
          *outptrXLeft++ = mxGetNaN();
          *outptrYLeft++ = mxGetNaN();
          *outptrPupilLeft++ = mxGetNaN();
          *outptrPix2DegXLeft++ = mxGetNaN();
          *outptrPix2DegYLeft++ = mxGetNaN();
          *outptrVelXLeft++ = mxGetNaN();
          *outptrVelYLeft++ = mxGetNaN();
        }
      else{
        *outptrXLeft++ = (double)data->fs.gx[currentEye];
        *outptrYLeft++ = (double)data->fs.gy[currentEye];
        *outptrPupilLeft++ = (double)data->fs.pa[currentEye];
        *outptrPix2DegXLeft++ = (double)data->fs.rx;
        *outptrPix2DegYLeft++ = (double)data->fs.ry;
        *outptrVelXLeft++ = (double)data->fs.gxvel[currentEye];
        *outptrVelYLeft++ = (double)data->fs.gyvel[currentEye];
      }
      // copy out right eye
      currentEye = 1;
      *outptrTimeRight++ = (double)data->fs.time;
      *outptrWhichEyeRight++ = currentEye;
      if ((int)data->fs.gx[currentEye]==NaN) {
          *outptrXRight++ = mxGetNaN();
          *outptrYRight++ = mxGetNaN();
          *outptrPupilRight++ = mxGetNaN();
          *outptrPix2DegXRight++ = mxGetNaN();
          *outptrPix2DegYRight++ = mxGetNaN();
          *outptrVelXRight++ = mxGetNaN();
          *outptrVelYRight++ = mxGetNaN();
        }
      else{
        *outptrXRight++ = (double)data->fs.gx[currentEye];
        *outptrYRight++ = (double)data->fs.gy[currentEye];
        *outptrPupilRight++ = (double)data->fs.pa[currentEye];
        *outptrPix2DegXRight++ = (double)data->fs.rx;
        *outptrPix2DegYRight++ = (double)data->fs.ry;
        *outptrVelXRight++ = (double)data->fs.gxvel[currentEye];
        *outptrVelYRight++ = (double)data->fs.gyvel[currentEye];
      }
      break;
    case ENDFIX:
      *outptrFixStartTime++ = (double)data->fe.sttime;
      *outptrFixEndTime++ = (double)data->fe.entime;
      *outptrFixAvgH++ = (double)data->fe.gavx;
      *outptrFixAvgV++ = (double)data->fe.gavy;
      break;
    case ENDSACC:
      *outptrSacStartTime++ = (double)data->fe.sttime;
      *outptrSacEndTime++ = (double)data->fe.entime;
      *outptrSacStartH++ = (double)data->fe.gstx;
      *outptrSacStartV++ = (double)data->fe.gsty;
      *outptrSacEndH++ = (double)data->fe.genx;
      *outptrSacEndV++ = (double)data->fe.geny;
      *outptrSacPeakVel++ = (double)data->fe.pvel;
      break;
    case ENDBLINK:
      *outptrBlinkStartTime++ = (double)data->fe.sttime;
      *outptrBlinkEndTime++ = (double)data->fe.entime;
      break;
    case MESSAGEEVENT:
        // Store all messages including MGL specific ones.
        mxSetField(messagesStruct, messagesCounter, "message", mxCreateString(&(data->fe.message->c)));
        mxSetField(messagesStruct, messagesCounter, "time", mxCreateDoubleScalar((double)data->fe.sttime));
        messagesCounter++;
        
      if (mglEyelinkVersion == 0) {
        if (strncmp(&(data->fe.message->c),"MGL BEGIN TRIAL",15) == 0) {
          char *mglMessage = &(data->fe.message->c);
          char *tok;
          tok = strtok(mglMessage," ");
          tok = strtok(NULL," ");
          tok = strtok(NULL," ");
          tok = strtok(NULL," ");
          *outptrMGLtrial++ = (double)data->fe.sttime;
          if (tok != NULL) *outptrMGLtrial++ = (double)atoi(tok);
        }
      }
      if ((strncmp(&(data->fe.message->c),"GAZE_COORDS",11) == 0) && (setGazeCoords == 0)) {
        char *gazeCoords = &(data->fe.message->c);
        char *tok;
        tok = strtok(gazeCoords," ");
        tok = strtok(NULL," ");
        *outptrCoords++ = (double)atoi(tok);
        tok = strtok(NULL," ");
        *outptrCoords++ = (double)atoi(tok);
        tok = strtok(NULL," ");
        *outptrCoords++ = (double)atoi(tok);
        tok = strtok(NULL," ");
        *outptrCoords++ = (double)atoi(tok);
        setGazeCoords = 1;
      }
      if (strncmp(&(data->fe.message->c),"FRAMERATE",9) == 0){
        char *msg = &(data->fe.message->c);
        char *tok;
        tok = strtok(msg, " ");
        tok = strtok(NULL," ");
        *outptrFrameRate++ = (double)atof(tok);
      }
      /* if (strncmp(&(data->fe.message->c),"!CAL",4) == 0){ */
      /*   char *calMessage = &(data->fe.message->c); */
      /*   char *tok; */
      /*   tok = strtok(calMessage, " "); */
      /*   tok = strtok(NULL," "); */
      /*   mexPrintf("%s\n", tok); */
      /* } */
      break;
    }
  }

  // return MGL events for version greater than 0
  if (mglEyelinkVersion >= 1) {
    // display number of MGL messages
    int mglCurrentVersionMessages = (mglEyelinkVersion==1) ? numMGLV1Messages : numMGLV2Messages;
    int nMsg = 0;
    if (verbose>0) mexPrintf("(mglPrivateEyelinkEDFRead) Parsing %i MGL messages.\n",
      mglCurrentVersionMessages);
    
    //    const char *fieldNames[] =  {"time","segmentNum","trialNum","blockNum","phaseNum","taskID"};
    // create an array to hold each message info
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"time",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *timePtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"time"));
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"segmentNum",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *segmentNumPtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"segmentNum"));
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"trialNum",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *trialNumPtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"trialNum"));
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"blockNum",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *blockNumPtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"blockNum"));
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"phaseNum",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *phaseNumPtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"phaseNum"));
    mxSetField(mxGetField(plhs[0],0,mglFieldname),0,"taskID",mxCreateDoubleMatrix(1,mglCurrentVersionMessages,mxREAL));
    double *taskIDPtr = mxGetPr(mxGetField(mxGetField(plhs[0],0,mglFieldname),0,"taskID"));
    
    // go back to beginning of file 
    edf_goto_bookmark(edf,&startOfFile); 
    // now cycle through events again, and pick out MGL messages
    for (i=0;i<numElements;i++) { 
      // get the event type and event pointer 
      eventType = edf_get_next_data(edf); 
      data = edf_get_float_data(edf); 
      // get the MGL message 
      if (mglEyelinkVersion==1) {
        if (isMGLV1Message(eventType,data)) {
          // we need to extract time/seg/trial/etc
          // the big difference is that in V1 we could only have one task active (or the
          // messages were uninterpretable)
          if (getMGLV1Message(eventType,data,nMsg,timePtr,segmentNumPtr,trialNumPtr,blockNumPtr,phaseNumPtr)) {
            // valid message, update pointers
            timePtr++;
            segmentNumPtr++;
            trialNumPtr++;
            blockNumPtr++;
            phaseNumPtr++;
            nMsg++;
          }
        }
      }
      else if (mglEyelinkVersion>=2) {
        if (isMGLV2Message(eventType,data) &&
            getMGLV2Message(eventType,data,timePtr,segmentNumPtr,trialNumPtr,blockNumPtr,phaseNumPtr,taskIDPtr)) {
          // valid message, update pointers
          timePtr++;
          segmentNumPtr++;
          trialNumPtr++;
          blockNumPtr++;
          phaseNumPtr++;
          taskIDPtr++;
          nMsg++;
        }
      }
    }
  }
  
  // free the bookmark
  edf_free_bookmark(edf,&startOfFile);

  // close file
  err = edf_close_file(edf);
  if (err) {
    mexPrintf("(mglPrivateEyelinkEDFRead) Error %i closing file %s\n",err,filename);
  }
}

   
///////////////////////
//   dispEventType   //
///////////////////////
void dispEventType(int dataType)
{
  mexPrintf("(mglPrivateEyelinkEDFRead) DataType is %i: ",dataType); 
  switch(dataType)  {
    case STARTBLINK:
      mexPrintf("start blink");break;
    case STARTSACC:
      mexPrintf("start sacc");break;
    case STARTFIX:
      mexPrintf("start fix");break;
    case STARTSAMPLES:
      mexPrintf("start samples");break;
    case STARTEVENTS:
      mexPrintf("start events");break;
    case STARTPARSE:
      mexPrintf("start parse");break;
    case ENDBLINK:
      mexPrintf("end blink");break;
    case ENDSACC:
      mexPrintf("end sacc");break;
    case ENDFIX:
      mexPrintf("end fix");break;
    case ENDSAMPLES:
      mexPrintf("end samples");break;
    case ENDEVENTS:
      mexPrintf("end events");break;
    case ENDPARSE:
      mexPrintf("end parse");break;
    case FIXUPDATE:
      mexPrintf("fix update");break;
    case BREAKPARSE:
      mexPrintf("break parse");break;
    case BUTTONEVENT:
      mexPrintf("button event");break;
    case INPUTEVENT:
      mexPrintf("input event");break;
    case MESSAGEEVENT:
      mexPrintf("message event");break;
    case SAMPLE_TYPE:
      mexPrintf("sample type");break;
    case RECORDING_INFO:
      mexPrintf("recording info");break;
    case NO_PENDING_ITEMS:
      mexPrintf("no pending items");break;
      break;
  }
  mexPrintf("\n");
}

//////////////////////////
//   isEyeUsedMessage   //
//////////////////////////
int isEyeUsedMessage(int eventType,ALLF_DATA *event)
{
  if (eventType == MESSAGEEVENT) {
    if (strlen(&(event->fe.message->c)) > 8) {
      if (strncmp(&(event->fe.message->c),"EYE_USED",8) == 0) {
	return 1;
      }
    }
  }
  return 0;
}
////////////////////////
//   isMGLV1Message   //
////////////////////////
int isMGLV1Message(int eventType,ALLF_DATA *event)
{
  if (eventType == MESSAGEEVENT) {
    if ((strncmp(&(event->fe.message->c),"MGL NEXT PHASE",14) == 0) ||
        (strncmp(&(event->fe.message->c),"MGL BEGIN BLOCK ",16) == 0) ||
        (strncmp(&(event->fe.message->c),"MGL BEGIN TRIAL ",16) == 0) ||
        (strncmp(&(event->fe.message->c),"MGL BEGIN SEGMENT ",18) == 0)) {
          return(1);
      }
  }
  return(0);
}
////////////////////////
//   isMGLV2Message   //
////////////////////////
int isMGLV2Message(int eventType,ALLF_DATA *event)
{
  int i;
  if (eventType == MESSAGEEVENT) {
    if ((strlen(&(event->fe.message->c)) > 4) && (strncmp(&(event->fe.message->c),"MGL ",4) == 0)){
      // count how many spaces there are
      int numSpaces = 0;
      char *mglMessage = &(event->fe.message->c);
      while(*mglMessage)
        if (*mglMessage++ == ' ')
          numSpaces++;
          // if we have more than 3 tokens
      if (numSpaces>3) {
        // and the third token is trial, then we should have 7 tokens
        if (strncmp(&(event->fe.message->c),"MGL BEGIN TRIAL",15) == 0) {
          return((numSpaces==6) ? 1 : 0);
        }
        // otherwise we should have 8 tokens
        else {
          return((numSpaces==7) ? 1 : 0);
        }
      }
    }
  }
  return 0;
}


///////////////////
//   dispEvent   //
///////////////////
void dispEvent(int eventType,ALLF_DATA *event,int verbose)
{
  if (isMGLV2Message(eventType,event))
    mexPrintf("%i:%s\n",event->fe.sttime,&(event->fe.message->c));
  else if (isMGLV1Message(eventType,event)) 
    mexPrintf("NOT IMPLEMENTED YET");
  else if (eventType == SAMPLE_TYPE) {
    if (verbose) {
	mexPrintf("(mglPrivateEyelinkEDFRead) Sample eye 0 is %i: pupil [%f %f] head [%f %f] screen [%f %f] pupil size [%f]\n",event->fs.time,event->fs.px[0],event->fs.py[0],event->fs.hx[0],event->fs.hy[0],event->fs.gx[0],event->fs.gy[0],event->fs.pa[0]);
	mexPrintf("(mglPrivateEyelinkEDFRead) Sample eye 1 is %i: pupil [%f %f] head [%f %f] screen [%f %f] pupil size [%f]\n",event->fs.time,event->fs.px[1],event->fs.py[1],event->fs.hx[1],event->fs.hy[1],event->fs.gx[1],event->fs.gy[1],event->fs.pa[1]);
      }
  }
}


/////////////////////////
//   getMGLV2Message   //
/////////////////////////
int getMGLV2Message(int eventType,ALLF_DATA *event, double *timePtr,double *segmentNumPtr, double *trialNumPtr, double *blockNumPtr, double *phaseNumPtr, double *taskIDPtr) 
{
  char *mglMessage = &(event->fe.message->c);
  char *tok;
  tok = strtok(mglMessage," ");
  tok = strtok(NULL," ");
  tok = strtok(NULL," ");
  // set the event time
  *timePtr = (double)event->fe.sttime;
  if (strncmp(tok,"TRIAL",5) == 0) { 
    // set 0 for the 0th segment 
    *segmentNumPtr = 0; 
  } 
  else if (strncmp(tok,"SEGMENT",7) == 0){ 
    // set the segmentPtr to have the correct segment 
    tok = strtok(NULL," "); 
    if (tok != NULL) *segmentNumPtr = (double)atoi(tok); 
  } 
  else if (strncmp(tok,"PHASE",5) == 0){ 
    // phase marker, nothing to do. 
    return(0); 
  }    
  else { 
    mexPrintf("(mglPrivateEyelinkEDFRead) Unknown MGL message %s\n",mglMessage); 
    return(0); 
  } 
  // get the trial umber
  tok = strtok(NULL," ");
  if (tok != NULL) *trialNumPtr = (double)atoi(tok);
  // get the block number 
  tok = strtok(NULL," "); 
  if (tok != NULL) *blockNumPtr = (double)atoi(tok); 
  // get the phase number 
  tok = strtok(NULL," "); 
  if (tok != NULL) *phaseNumPtr = (double)atoi(tok); 
  // get the task ID 
  tok = strtok(NULL," "); 
  if (tok != NULL) *taskIDPtr = (double)atoi(tok); 
  return(1);
}

/////////////////////////
//   getMGLV1Message   //
/////////////////////////
int getMGLV1Message(int eventType, ALLF_DATA *event, int nmsg, double *timePtr, 
  double *segmentNumPtr, double *trialNumPtr, double *blockNumPtr, 
  double *phaseNumPtr) 
{
  char *mglMessage = &(event->fe.message->c);
  char *tok;
  tok = strtok(mglMessage," "); // MGL
  tok = strtok(NULL," "); // BEGIN
  tok = strtok(NULL," "); // [TYPE]
  // set the event time
  *timePtr = (double)event->fe.sttime;
  
  // Everything will be 0 indexed and the arrays are 0 filled
  // the big difference between v1 and v2 is that we need to persist values
  // forward. We also have to check for the base case
  // set 0 for the 0th segment 
  // set the segmentPtr to have the correct segment 
  if (strncmp(tok,"PHASE",5) == 0) {
    // we don't get the phase num and therefor there can be an initial condition
    // problem
    *phaseNumPtr = (nmsg==0) ? 1 : *(phaseNumPtr-1)+1;
    *blockNumPtr = 0;
    *trialNumPtr = 0;
    *segmentNumPtr = 0;
    
  } 
  else if (strncmp(tok,"BLOCK",5) == 0) {
    tok = strtok(NULL," "); 
    if (tok != NULL) {
      *blockNumPtr = (double)atoi(tok);
    }
    else {
      mexPrintf("(mglPrivateEyelinkEDFRead) Unknown MGL message %s\n",mglMessage);
      return(0);
    }
    *phaseNumPtr = (nmsg==0) ? 0 : *(phaseNumPtr-1);
    *trialNumPtr = 0;
    *segmentNumPtr = 0;
  } 
  else if (strncmp(tok,"TRIAL",5) == 0) {
    tok = strtok(NULL," "); 
    if (tok != NULL) {
       *trialNumPtr = (double)atoi(tok);
    }
    else {
      mexPrintf("(mglPrivateEyelinkEDFRead) Unknown MGL message %s\n",mglMessage);
      return(0);
    }
    *phaseNumPtr = (nmsg==0) ? 0 : *(phaseNumPtr-1);
    *blockNumPtr = *(blockNumPtr-1);
    *segmentNumPtr = 0;
  }    
  else if (strncmp(tok,"SEGMENT",7) == 0) {
    tok = strtok(NULL," "); 
    if (tok != NULL) {
      *segmentNumPtr = (double)atoi(tok);
    }
    else {
      mexPrintf("(mglPrivateEyelinkEDFRead) Unknown MGL message %s\n",mglMessage);
      return(0);
    }
    *phaseNumPtr = (nmsg==0) ? 0 : *(phaseNumPtr-1);
    *blockNumPtr = *(blockNumPtr-1);
    *trialNumPtr = *(trialNumPtr-1);
  }    
  else { 
    mexPrintf("(mglPrivateEyelinkEDFRead) Unknown MGL message %s\n",mglMessage); 
    return(0); 
  }
  return(1);
}
