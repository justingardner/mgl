#ifdef documentation
=========================================================================

     program: mglPrivateMovie.c
          by: justin gardner
        date: 12/23/08
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: interface for playing movies via using QTKit

$Id: mglPrivateOpen.c,v 1.14 2007/10/25 20:31:43 justin Exp $
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

////////////////////////
//   define section   //
////////////////////////
#define CLOSE 0
#define PLAY 1
#define PAUSE 2
#define GOTO_BEGINNING 3
#define GOTO_END 4
#define STEP_FORWARD 5
#define STEP_BACKWARD 6
#define HIDE 7
#define SHOW 8
#define GET_DURATION 9
#define GET_CURRENT_TIME 10
#define SET_CURRENT_TIME 11

/////////////////////////
//   OS Specific calls //
/////////////////////////
// opens a movie and returns a pointer to a movie structure (for mac this
// is a pointer to the QTMovieView. The window should be positioned at xpos,ypos
// with width and height specified by input arguments
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height);

// does the movie commands, commands are specified as an int with
// numbers specified in the list above. moviePointer is the pointer
// that was returned from openMovie
mxArray *doMovieCommand(int command, unsigned long moviePointer, const mxArray *arg1, const mxArray *arg2);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int command = 0;
  char *filename;

  // check arguments
  if ((nrhs == 2) &&  (mxIsChar(prhs[0]))) {
    // get the filename
    filename = mxArrayToString(prhs[0]);
    double *position = mxGetPr(prhs[1]);
    // open the movie
    unsigned long moviePointer = openMovie(filename,position[0],position[1],position[2],position[3]);
    // free the filename
    mxFree(filename);
    if (moviePointer != 0) {
      // create the output structure
      const char *fieldNames[] =  {"filename","moviePointer"};
      int outDims[2] = {1, 1};
      plhs[0] = mxCreateStructArray(1,outDims,2,fieldNames);
      
      // add the field for filename, but leave it empty since mglMovie will fill it in
      mxSetField(plhs[0],0,"filename",mxCreateDoubleMatrix(0,0,mxREAL));
      // add the field for the movie pointer
      mxSetField(plhs[0],0,"moviePointer",mxCreateDoubleMatrix(1,1,mxREAL));
      *mxGetPr(mxGetField(plhs[0],0,"moviePointer")) = moviePointer;
    }
    else {
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    }
    return;
  }
  else if ((nrhs >= 2) && (nrhs <= 4)) {
    // get the movie pointer
    mxArray *moviePointerField =  mxGetField(prhs[0],0,"moviePointer");
    if (moviePointerField == NULL) {
      usageError("mglMovie");
      return;
    }
    unsigned long moviePointer = (unsigned long)mxGetScalar(moviePointerField);
    // and the command
    int command = (unsigned long)mxGetScalar(prhs[1]);
    // set argument
    const mxArray *arg1 = NULL, *arg2 = NULL;
    if (nrhs >= 3) arg1 = prhs[2];
    if (nrhs >= 4) arg2 = prhs[3];
    
    // do the movie command
    mxArray *retval = doMovieCommand(command,moviePointer,arg1,arg2);
    if (retval != NULL) plhs[0] = retval; else plhs[0]=mxCreateDoubleMatrix(0,0,mxREAL);
  }
  else {
    usageError("mglMovie");
    return;
  }    
}

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
///////////////////
//   openMovie   //
///////////////////
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height)
{
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // see if there is an existing window controller
  NSWindowController *myWindowController = (NSWindowController*)(unsigned long)mglGetGlobalDouble("windowController");

  // init a QTMovie
  NSError *myError = [NSError alloc];
  NSString *NSFilename = [[NSString alloc] initWithCString:filename];
  QTMovie *movie = [[QTMovie alloc] initWithFile:NSFilename error:&myError];
  // release the filename
  [NSFilename release];

  // see if there was an error
  if ([myError code] != 0) {
    mexPrintf("(mglPrivateMovie) Error opening movie %s: %s\n",filename,[[myError localizedDescription] cStringUsingEncoding:NSASCIIStringEncoding]);
    // drain the pool
    [pool drain];
    return(0);
  }

  // make a QT movie view
  QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(xpos,ypos,width,height)];

  // set the movie to display
  [movieView setMovie:movie];
  [movieView setControllerVisible:NO];
  [[[myWindowController window] contentView] addSubview:movieView];
  [[[myWindowController window] contentView] display];

  // release memory
  [myError release];

  // drain the pool
  [pool drain];

  return((unsigned long)movieView);
}
////////////////////////
//   doMovieCommand   //
////////////////////////
mxArray *doMovieCommand(int command, unsigned long moviePointer, const mxArray *arg1, const mxArray *arg2)
{
  mxArray *retval = NULL;
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // convert pointer to QTMovieView
  QTMovieView *movieView = (QTMovieView *)moviePointer;

  // see if there is an existing window controller
  NSWindowController *myWindowController = (NSWindowController*)(unsigned long)mglGetGlobalDouble("windowController");

  switch(command) {
    case CLOSE:
      [movieView removeFromSuperview];
      break;
    case PLAY:
      [movieView play:nil];
      break;
    case PAUSE:
      [movieView pause:nil];
      break;
    case GOTO_BEGINNING:
      [movieView gotoBeginning:nil];
      break;
    case GOTO_END:
      [movieView gotoEnd:nil];
      break;
    case STEP_FORWARD:
      [movieView stepForward:nil];
      break;
    case STEP_BACKWARD:
      [movieView stepBackward:nil];
      break;
    case HIDE:
      [movieView setHidden:YES];
      break;
    case SHOW:
      [movieView setHidden:NO];
      break;
    case GET_DURATION:
      ;
      NSString *durationString = QTStringFromTime([[movieView movie] duration]);
      retval = mxCreateString([durationString cStringUsingEncoding:NSASCIIStringEncoding]);
      break;
    case GET_CURRENT_TIME:
      ;
      NSString *currentTime = QTStringFromTime([[movieView movie] currentTime]);
      retval = mxCreateString([currentTime cStringUsingEncoding:NSASCIIStringEncoding]);
      break;
    case SET_CURRENT_TIME:
      if (arg1 == NULL) 
	mexPrintf("(mglPrivateMovie) Must pass in a time string\n");
      else {
	NSString *setTime = [[NSString alloc] initWithCString:mxArrayToString(arg1)];
	[[movieView movie] setCurrentTime:QTTimeFromString(setTime)];
	[setTime release];
      }
      break;
    default:
      mexPrintf("(mglPrivateMovie) Unknown command %i\n",command);
      break;
  }
  [pool drain];
  return(retval);
}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else //__cocoa__
///////////////////
//   openMovie   //
///////////////////
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height)
{
  mexPrintf("(mglMovie) Not implemented\n");
  return 0;
}
////////////////////////
//   doMovieCommand   //
////////////////////////
mxArray *doMovieCommand(int command, unsigned long moviePointer, const mxArray *arg1, const mxArray *arg2)
{
  mexPrintf("(mglMovie) Not implemented\n");
  return NULL;
}
#endif //_cocoa__
#endif __APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__
///////////////////
//   openMovie   //
///////////////////
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height)
{
  mexPrintf("(mglMovie) Not implemented\n");
  return 0;
}
////////////////////////
//   doMovieCommand   //
////////////////////////
mxArray *doMovieCommand(int command, unsigned long moviePointer, const mxArray *arg1, const mxArray *arg2)
{
  mexPrintf("(mglMovie) Not implemented\n");
  return NULL;
}
#endif //__linux__
