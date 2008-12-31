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
#define GET_FRAME 12

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
#ifdef __x86_64__ // We make these only for 64bit because on 32bit we are getting 
///////////////////
//   openMovie   //
///////////////////
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height)
{
  // check for cocoa window
  if (!mglGetGlobalDouble("isCocoaWindow")) {
    mexPrintf("(mglPrivateMovie) mglMovie is only available for cocoa based windows. On the desktop this means you have to open with mglOpen(0). If you want to use movies with a full screen context, try running matlab -nodesktop on -nojvm\n");
    return 0;
  }

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // These two lines have been commented out:
  //
  //EnterMoviesOnThread(0);
  //CSSetComponentsThreadMode(kCSAcceptAllComponentsMode);
  //
  // Don't think these are necessary; there is some issue on 32 bit versionds
  // about QTKit and threads. This code is recommended but does not fix the 
  // problem. Essentially, it seems that QTKit is not thread safe and has
  // to be initialized on the "main thread". I am not sure why this isn't the
  // main thread, but the line below where we allocate QTMovie alloc causes:
  // 2008-12-28 14:38:39.558 MATLAB[24504:3307] AppKitJava: uncaught exception QTMovieInitializedOnWrongThread (QTMovie class must be initialized on the main thread.)
  // 2008-12-28 14:38:39.559 MATLAB[24504:3307] AppKitJava: exception = QTMovie class must be initialized on the main thread.
  // 2008-12-28 14:38:39.559 MATLAB[24504:3307] AppKitJava: terminating.
  // But this code does appear to work on 64bit, so maybe QT has become more
  // thread safe in 64bit mode?

  // see if there is an existing window
  NSWindow *myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("window");

  // init a QTMovie
  NSError *myError = [NSError alloc];//NULL;
  NSString *NSFilename = [[NSString alloc] initWithCString:filename];
  QTMovie *movie = [[QTMovie alloc] initWithFile:NSFilename error:&myError];

  // release the filename
  [NSFilename release];

  // see if there was an error
  //  if (myError != NULL) {
  if ([myError code] != 0) {
    mexPrintf("(mglPrivateMovie) Error opening movie %s: %s\n",filename,[[myError localizedDescription] cStringUsingEncoding:NSASCIIStringEncoding]);
    // release memory
    [movie release];
    // drain the pool
    [pool drain];
    return(0);
  }

  // make a QT movie view
  QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(xpos,ypos,width,height)];

  // set the movie to display
  [movieView setMovie:movie];
  [movieView setControllerVisible:NO];
  [[myWindow contentView] addSubview:movieView];
  [[myWindow contentView] display];

  // release memory
  [movie release];

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
    case GET_FRAME:
      ;
      // get the frame as a bitmap
      NSImage *frameImage = [[movieView movie] currentFrameImage];
      NSData *tiffData = [frameImage TIFFRepresentation];
      NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:tiffData];

      // get the size info
      NSSize frameSize = [frameImage size];
      int width = (int)frameSize.width,height = (int)frameSize.height;
      int bytesPerPlane = (int)[bitmap bytesPerPlane];
      int bytesPerRow = (int)[bitmap bytesPerRow];
      int numPlanes = (int)[bitmap numberOfPlanes];
      int bytesPerPixel = bytesPerRow/width;

      // get the bitmapData
      unsigned char *bitmapData = [bitmap bitmapData];
      
      // create output structure
      mwSize dims[3] = {height,width,3};
      retval = mxCreateNumericArray(3,dims,mxDOUBLE_CLASS,mxREAL);
      double *outputPtr = mxGetPr(retval);
      // copy data into output structure
      int i,j;
      for (i=0;i<width;i++){
	for (j=0;j<height;j++) {
	  outputPtr[i*height+j] = (double)bitmapData[(i+j*width)*bytesPerPixel]/256.0;
	  outputPtr[i*height+j+width*height] = (double)bitmapData[(i+j*width)*bytesPerPixel+1]/256.0;
	  outputPtr[i*height+j+2*width*height] = (double)bitmapData[(i+j*width)*bytesPerPixel+2]/256.0;
	}
      }
      break;
    default:
      mexPrintf("(mglPrivateMovie) Unknown command %i\n",command);
      break;
  }
  [pool drain];
  return(retval);
}
/////////////////////////////
//   openMovieWithWindow   //
////////////////////////////
unsigned long openMovieWithWindow(char *filename, int xpos, int ypos, int width, int height)
{

  // This function is an attempt to just open the movie in its own window, but I
  // can't get it to display at a level above the openGL context...
  NSWindow *myWindow;
  NSWindowController *myWindowController;

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // These two lines have been commented out:
  //
  //  EnterMoviesOnThread(0);
  //  CSSetComponentsThreadMode(kCSAcceptAllComponentsMode);
  //
  // Don't think these are necessary; there is some issue on 32 bit versionds
  // about QTKit and threads. This code is recommended but does not fix the 
  // problem. Essentially, it seems that QTKit is not thread safe and has
  // to be initialized on the "main thread". I am not sure why this isn't the
  // main thread, but the line below where we allocate QTMovie alloc causes:
  // 2008-12-28 14:38:39.558 MATLAB[24504:3307] AppKitJava: uncaught exception QTMovieInitializedOnWrongThread (QTMovie class must be initialized on the main thread.)
  // 2008-12-28 14:38:39.559 MATLAB[24504:3307] AppKitJava: exception = QTMovie class must be initialized on the main thread.
  // 2008-12-28 14:38:39.559 MATLAB[24504:3307] AppKitJava: terminating.
  // But this code does appear to work on 64bit, so maybe QT has become more
  // thread safe in 64bit mode?

    // init a QTMovie
  NSError *myError = NULL;
  NSString *NSFilename = [[NSString alloc] initWithCString:filename];
  QTMovie *movie = [[QTMovie alloc] initWithFile:NSFilename error:&myError];

  // release the filename
  [NSFilename release];

  // see if there was an error
  if (myError != NULL) {
    mexPrintf("(mglPrivateMovie) Error opening movie %s: %s\n",filename,[[myError localizedDescription] cStringUsingEncoding:NSASCIIStringEncoding]);
    // release memory
    [movie release];
    // drain the pool
    [pool drain];
    return(0);
  }

  // make a QT movie view
  QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(xpos,ypos,width,height)];

  // set the movie to display
  [movieView setMovie:movie];
  [movieView setControllerVisible:NO];

  // start the application -- i.e. connect our code to the window server
  NSApplicationLoad();

  // set initial size and location
  NSRect contentRect = NSMakeRect(xpos,ypos,width,height);

  // create the window
  myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:false];
  if (myWindow==nil){mexPrintf("(mglPrivateOpen) Could not create window\n");return;}

  // set the movie as the content view
  [myWindow setContentView:movieView];
  [myWindow setLevel:kCGMaximumWindowLevel];
  [myWindow makeKeyAndOrderFront: nil];
  [myWindow display];

  // release memory
  [movie release];
  [pool drain];
  return((unsigned long)movieView);
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
  mexPrintf("(mglMovie) Not implemented for 32 bit Mac.\n");
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
