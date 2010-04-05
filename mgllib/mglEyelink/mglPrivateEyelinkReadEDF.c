#ifdef documentation
=========================================================================

     program: mglPrivateEyelinkReadEDF.c
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
void dispEvent(int eventType,ALLF_DATA *event);
int isEyeUsedMessage(int eventType,ALLF_DATA *event);

////////////////////////
//   define section   //
////////////////////////
#define STRLEN 2048

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int err;

  // parse input arguments
  if (nrhs<2) {
    usageError("mglEyelinkReadEDF");
    return;
  }
 
  // get filename
  char filename[STRLEN];
  mxGetString(prhs[0], filename, STRLEN);

  // get verbose
  int verbose = (int)*(double*)mxGetPr(prhs[1]);

  if (verbose)
    mexPrintf("(mglPrivateEyelinkReadEDF) Opening EDF file %s\n",filename);
  
  // open file
  int errval;
  EDFFILE *edf = edf_open_file(filename,verbose,1,1,&errval);
  // and check that we opened correctly
  if (edf == NULL) {
    mexPrintf("(mglPrivateEyelinkReadEDF) Could not open file %s (error %i)\n",filename,errval);
    return;
  }

  // read preamble
  if (verbose) {
    int preambleLength = edf_get_preamble_text_length(edf);
    char *cbuf = (char *)malloc(preambleLength*sizeof(char));
    edf_get_preamble_text(edf,cbuf,preambleLength);
    mexPrintf("(mglPrivateEyelinkReadEDF) Preamble text:\n%s",cbuf);
    free(cbuf);
  }
  
  int i,eventType,numSamples = 0;
  int numElements = edf_get_element_count(edf);
  int numTrials = edf_get_trial_count(edf);
  ALLF_DATA *data;

  // display version
  if (verbose)
    mexPrintf("(mglPrivateEyelinkReadEDF) EDFAPI version %s.\n",edf_get_version());

  // display element count
  if (verbose)
    mexPrintf("(mglPrivateEyelinkReadEDF) File has %i elements.\n",numElements);

  // display number of trials
  if (verbose)
    mexPrintf("(mglPrivateEyelinkReadEDF) File has %i trials.\n",numTrials);

  // mark beginning of file
  BOOKMARK startOfFile;
  edf_set_bookmark(edf,&startOfFile);

  // count number of samples in file
  for (i=0;i<numElements;i++) {
    // get the event type and event pointer
    eventType = edf_get_next_data(edf);
    if (eventType == SAMPLE_TYPE) numSamples++;
  }
  if (verbose) mexPrintf("(mglPrivateEyelinkReadEDF) Number of samples %i\n",numSamples);
  
  // go back go beginning of file
  edf_goto_bookmark(edf,&startOfFile);
  edf_free_bookmark(edf,&startOfFile);

  // allocate space for data
  plhs[0] = mxCreateDoubleMatrix(5,numSamples,mxREAL);
  double *outptr = (double *)mxGetPr(plhs[0]);
  int currentEye = -1;

  // go through all data in file
  for (i=0;i<numElements;i++) {
    // get the event type and event pointer
    eventType = edf_get_next_data(edf);
    data = edf_get_float_data(edf);
    // display event type and info
    if (verbose>1) dispEventType(eventType);
    if (verbose==1) dispEvent(eventType,data);
    // grab which eye we are recording from
    if (isEyeUsedMessage(eventType,data)) currentEye = (int)data->fe.eye;
    // get samples
    if (eventType == SAMPLE_TYPE){
      *outptr++ = (double)data->fs.gx[currentEye];
      *outptr++ = (double)data->fs.gy[currentEye];
      *outptr++ = (double)data->fs.pa[currentEye];
      *outptr++ = (double)currentEye;
      *outptr++ = (double)data->fs.time;
    }
  }
  
  // close file
  err = edf_close_file(edf);
  if (err) {
    mexPrintf("(mglPrivateEyelinkReadEDF) Error %i closing file %s\n",err,filename);
  }
}

   
///////////////////////
//   dispEventType   //
///////////////////////
void dispEventType(int dataType) 
{
  mexPrintf("(mglPrivateEyelinkReadEDF) DataType is %i: ",dataType);
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

///////////////////
//   dispEvent   //
///////////////////
void dispEvent(int eventType,ALLF_DATA *event)
{
  if (eventType == MESSAGEEVENT) {
    if (!isEyeUsedMessage(eventType,event))
      mexPrintf("%i:%s\n",event->fe.sttime,&(event->fe.message->c));
  }
  else if (eventType == SAMPLE_TYPE) {
    //    fprintf(fid,"(mglPrivateEyelinkReadEDF) Sample eye 0 is %i: pupil [%f %f] head [%f %f] screen [%f %f] pupil size [%f]\n",event->fs.time,event->fs.px[0],event->fs.py[0],event->fs.hx[0],event->fs.hy[0],event->fs.gx[0],event->fs.gy[0],event->fs.pa[0]);
    //    fprintf(fid,"(mglPrivateEyelinkReadEDF) Sample eye 1 is %i: pupil [%f %f] head [%f %f] screen [%f %f] pupil size [%f]\n",event->fs.time,event->fs.px[1],event->fs.py[1],event->fs.hx[1],event->fs.hy[1],event->fs.gx[1],event->fs.gy[1],event->fs.pa[1]);
  }
}



