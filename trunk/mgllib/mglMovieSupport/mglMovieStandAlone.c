#ifdef documentation
=========================================================================

     program: mglMovieStandAlone.c
          by: justin gardner
        date: 12/31/12

=========================================================================
#endif

///////////////////////////
//    include section    //
///////////////////////////
// Cocoa specific imports.
#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>
#import <QTKit/QTKit.h>

#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdlib.h>

//////////////////////////
//    define section    //
//////////////////////////
#define BUFLEN 4096

/////////////////////////////////
//    function declarations    //
/////////////////////////////////
NSWindow *initWindow(int);
QTMovieView *initMovie(char *, NSWindow *, int);
int openSocketAndWaitForCommands(char *,NSWindow *);
NSOpenGLView *addOpenGLContext(NSWindow *myWindow, int setRatherThanAdd);
NSOpenGLView *addLayerBackedOpenGLContext(NSWindow *);
int parseArgs(int, char *[]);
char *isValidMoviename(char *);

/////////////////////////
//    main function    //
/////////////////////////
int main(int argc, char *argv[])
{
  // flag to show contorls
  int showControls = 0;

  // parse input arguments
  if (!parseArgs(argc, argv)) return 0;

  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Bring up the window
  NSWindow *myWindow = initWindow(showControls);
  if (myWindow == NULL) { [pool drain]; return; }

  // add openGl view
  //  NSOpenGLView *myOpenGLView = addOpenGLContext(myWindow,0);
  //  addLayerBackedOpenGLContext(myWindow);

  // open the socket and wait for commands  
  openSocketAndWaitForCommands(".mglMovieSocket",myWindow);

  // close window, drain pool, return
  //  [[movieView movie] release];
  [myWindow close];
  [pool drain];
}

/////////////////////
//    parseArgs    //
/////////////////////
int parseArgs(int argc, char *argv[])
{
  // check input arguments
  if ((argc != 1)) {
    printf("(mglMovieStandAlone) Usage: mglMovieStandAlone\n");
    return 0;
  }

  return 1;
}

////////////////////////////
//    isValidMoviename    //
////////////////////////////
char *isValidMoviename(char *filename)
{
  // declare variables
  static char buf[BUFLEN];
  FILE *fptr;

  // check if it is a valid file
  fptr = fopen(filename,"r");fclose(fptr);
  // valid if fptr is not null
  if (fptr != NULL) return(filename);

  // if not valid, see if adding the extension helps
  sprintf(buf,"%s.mov",strtok(filename,"."));
  fptr = fopen(buf,"r");fclose(fptr);
  if (fptr != NULL) return buf;

  // if we got here, then we could not open the file
  printf("(mglMovieStandAlone) Could not open file: %s\n",filename);
  return NULL;
}

///////////////////////////////////////
//    openSocketAndWaitForCommands    //
////////////////////////////////////////
int openSocketAndWaitForCommands(char *socketName, NSWindow *myWindow)
{
  struct sockaddr_un socketAddress;
  char buf[BUFLEN], *commandName, *movieIDStr, *filename, *extraParams;
  int socketDescriptor,connectionDescriptor,readCount, movieID;
  int numMovies = 0;
  int verbose = 0;
  // init movie
  QTMovieView *movieViews[BUFLEN], *movieView;;

  // create socket and check for error
  if ((socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    perror("(mglMovieStandAlone) Could not create socket to communicate between matlab and mglMovieStandAlone");
    return 0;
  }

  // set up socket address
  memset(&socketAddress, 0, sizeof(socketAddress));
  socketAddress.sun_family = AF_UNIX;
  strncpy(socketAddress.sun_path, socketName, sizeof(socketAddress.sun_path)-1);

  // unlink (make sure that it doesn't already exist)
  unlink(socketName);

  // bind the socket to the address, this could fail if you don't have
  // write permission to the directory where the socket is being made
  if (bind(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
    printf("(mglMovieStandAlone) Could not bind socket to name %s. This prevents communication between matlab and mglMovieStandAlone. This might have happened because you do not have permission to write the file %s",socketName,socketName);
    perror(NULL);
    close(socketDescriptor);
    return 0;
  }

  // listen to the socket (accept up to 500 connects)
  if (listen(socketDescriptor, 500) == -1) {
    printf("(mglMovieStandAlone) Could not listen to socket %s, which is used to communicate between matlab and mglMovieStandAlone.",socketName);
    perror(NULL);
    close(socketDescriptor);
    return 0;
  }

  // sit in loop accepting commands
  while (1) {
    if ( (connectionDescriptor = accept(socketDescriptor, NULL, NULL)) == -1) {
     perror("(mglMovieStandAlone) Error accepting a connection on socket. This prevents communication between matlab and mglMovieStandAlone");
      continue;
    }

    // clear command buffer
    memset(buf,0,BUFLEN);

    // read command
    if ((readCount=read(connectionDescriptor,buf,sizeof(buf))) > 0) {
      // pull out command
      commandName = strtok(buf," \n\0");

      // check commands
      //++++++++++++++++++++++++++++++++
      // Open
      //++++++++++++++++++++++++++++++++
      if (strcmp(commandName,"open")==0) {
	// get filename and validate
	filename = isValidMoviename(strtok(NULL," \n\0"));
	if (filename == NULL) continue;
	if (verbose) printf("(mglMovieStandAlone) Open: %s\n",filename);
	// open the movie
	movieViews[numMovies] = initMovie(filename,myWindow,0);
	// if it was successful, then increment movie count
	if (movieViews[numMovies] != NULL) numMovies++;
	if (numMovies >= BUFLEN) 
	  printf("(mglMovieStandAlone) Exceeded number of movies allowed in buffer %i\n",numMovies--);
	else {
	  if (verbose) printf("(mglMovieStandAlone) movieID: %i\n",numMovies-1);
	  // return ID
	  sprintf(buf,"%i",numMovies);
	  if (write(connectionDescriptor,buf,strlen(buf)) != strlen(buf))
	    printf("(mglMovieStandAlone) Could not write duration string to scoket\n");
	}
      }
      //++++++++++++++++++++++++++++++++
      // closeWindow
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"closeWindow")==0) {
	if (verbose) printf("(mglMovieStandAlone) Close window\n");
	// Closes app
	close(socketDescriptor);
	close(connectionDescriptor);
	return 0;
      }
      //++++++++++++++++++++++++++++++++
      // orderFront
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"orderFront")==0) {
	if (verbose) printf("(mglMovieStandAlone) Order front\n");
	// order the mgl window to the front
	[myWindow orderFront:nil];
	[myWindow orderFrontRegardless];
	[myWindow display];
      }
      //++++++++++++++++++++++++++++++++
      // setBackground
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"setBackground")==0) {
	// get the position to size
	double r,g,b;
	extraParams = strtok(NULL,"");
	r = strtod(extraParams,&extraParams);
	g = strtod(extraParams,&extraParams);
	b = strtod(extraParams,&extraParams);
	if (verbose) printf("(mglMovieStandAlone) Set background: %f %f %f\n",r,g,b);
	// set the background color
	[myWindow setBackgroundColor:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0f]];
	[myWindow display];
      }
      //++++++++++++++++++++++++++++++++
      // openWindow
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"openWindow")==0) {
	if (verbose) printf("(mglMovieStandAlone) Open window\n");
	// send acknowledge
	sprintf(buf,"open ack");
	if (write(connectionDescriptor,buf,strlen(buf)) != strlen(buf))
	  printf("(mglMovieStandAlone) Could not write ack to scoket\n");
      }
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"moveWindow")==0) {
	// get the position to move to
	int x,y;
	extraParams = strtok(NULL,"");
	x = (int)strtod(extraParams,&extraParams);
	y = (int)strtod(extraParams,&extraParams);
	if (verbose) printf("(mglMovieStandAlone) Move window %i %i\n",x,y);
	// get current frame rect
	NSRect frameRect = [myWindow frame];
	// change origin
	frameRect.origin.x = (CGFloat)x;
	frameRect.origin.y = (CGFloat)y;
	if (verbose) printf("(mglMovieStandAlone) Move window %i %i\n",x,y);
	// and move
	[myWindow setFrame:frameRect display:YES];
      }
      //++++++++++++++++++++++++++++++++
      else if (strcmp(commandName,"moveAndResizeWindow")==0) {
	// get the position to size
	int x,y,width,height;
	extraParams = strtok(NULL,"");
	x = (int)strtod(extraParams,&extraParams);
	y = (int)strtod(extraParams,&extraParams);
	width = (int)strtod(extraParams,&extraParams);
	height = (int)strtod(extraParams,&extraParams);
	if (verbose) printf("(mglMovieStandAlone) Move and resize window %i %i %i %i \n",x,y,width,height);
	// and move
	[myWindow setFrame:NSMakeRect(x,y,width,height) display:YES];
      }
      else {
	// These following commands all require a movieID. 
	// read the ID number, if left off, then default to 1
	movieIDStr = strtok(NULL," \n\0");
	extraParams = strtok(NULL,"");
	if (movieIDStr == NULL)
	  movieID = numMovies-1;
	else 
	  movieID = (int)strtod(movieIDStr,NULL)-1;
	if (verbose) printf("(mglMovieStandAlone) Got command: %s for movie: %i\n",commandName,movieID);
	if ((movieID > BUFLEN)||(movieID<0)) continue;
	// get movieView associated with movie ID
	movieView = movieViews[movieID];
	if (movieView == NULL) continue;
	//++++++++++++++++++++++++++++++++
	if (strcmp(commandName,"play")==0) {
	  // make sure movie is playable
	  if ([[[movieView movie] attributeForKey:QTMovieLoadStateAttribute] longValue] >= QTMovieLoadStatePlayable) {
	    // play movie
	    //[myWindow orderFrontRegardless];
	    //[myWindow orderFront:nil];
	    //[myWindow setAlphaValue:1];
	    [[movieView movie] play];
	  }
	  else {
	    printf("(mglMovieStandAlone) Movie is still loading, not playable yet\n");
	  }
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"close")==0) {
	  // pause movie
	  [movieView pause:nil];
	  // remove it from the contentView if it is not already there
	  if ([movieView superview] == [myWindow contentView]) {
	    [movieView removeFromSuperview];
	  }
	  // hide movie
	  [movieView setAlphaValue:0];
	  [[myWindow contentView] display];
	  [myWindow display];
	  // dealloc (does this dealloc the QTMovie as well?
	  [movieView dealloc];
	  movieViews[movieID] = NULL;
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"pause")==0) {
	  // pause movie
	  [movieView pause:nil];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"gotoBeginning")==0) {
	  // goto beginning
	  [movieView gotoBeginning:nil];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"gotoEnd")==0) {
	  // goto end
	  [movieView gotoEnd:nil];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"stepForward")==0) {
	  // forward one step
	  [movieView stepForward:nil];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"stepBackward")==0) {
	  // backward one step
	  [movieView stepBackward:nil];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"hide")==0) {
	  // remove it from the contentView if it is not already there
	  if ([movieView superview] == [myWindow contentView]) {
	    [movieView removeFromSuperview];
	  }
	  // hide movie
	  [movieView setAlphaValue:0];
	  [[myWindow contentView] display];
	  [myWindow display];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"show")==0) {
	  // add move to contentView if it is not already there
	  if ([movieView superview] != [myWindow contentView]) {
	    [[myWindow contentView] addSubview:movieView];
	  }
	  // display it
	  [movieView setAlphaValue:1];
	  [movieView display];
	  [[myWindow contentView] display];
	  [myWindow display];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"getDuration")==0) {
	  // get duration
	  NSString *durationString = QTStringFromTime([[movieView movie] duration]);
	  // write it to socket
	  if (write(connectionDescriptor,[durationString cStringUsingEncoding:NSASCIIStringEncoding],[durationString length]) != [durationString length])
	    printf("(mglMovieStandAlone) Could not write duration string to scoket\n");
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"getCurrentTime")==0) {
	  // get current time
	  NSString *currentTimeString = QTStringFromTime([[movieView movie] currentTime]);
	  // write it to socket
	  if (write(connectionDescriptor,[currentTimeString cStringUsingEncoding:NSASCIIStringEncoding],[currentTimeString length]) != [currentTimeString length])
	    printf("(mglMovieStandAlone) Could not write currentTime string to scoket\n");
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"setCurrentTime")==0) {
	  if (write(connectionDescriptor,"sendTime",8) != 8)
	    printf("(mglMovieStandAlone) Could not write acknowledge string to scoket\n");
	  // get time to set to
	  if ((readCount=read(connectionDescriptor,buf,sizeof(buf))) > 0) {
	    NSString *setTime = [[NSString alloc] initWithCString:buf];
	    [[movieView movie] setCurrentTime:QTTimeFromString(setTime)];
	    [setTime release];
	  }
	  else {
	    printf("(mglMovieStandAlone) Could not read time string from scoket\n");
	  }
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"getFrame")==0) { 
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
	
	  // get width and height for sending
	  uint32 widthAndHeight[2];
	  widthAndHeight[0] = (uint32)width;
	  widthAndHeight[1] = (uint32)height;

	  // send width and height
	  write(connectionDescriptor,(char *)widthAndHeight,sizeof(uint32)*2);

	  // copy data into a convenient structure to send across socket
	  uint8 *outputPtr = (uint8 *)malloc(width*height*3);
	  int i,j;
	  for (i=0;i<width;i++){
	    for (j=0;j<height;j++) {
	      outputPtr[i*height+j] = (uint8)bitmapData[(i+j*width)*bytesPerPixel];
	      outputPtr[i*height+j+width*height] = (uint8)bitmapData[(i+j*width)*bytesPerPixel+1];
	      outputPtr[i*height+j+2*width*height] = (uint8)bitmapData[(i+j*width)*bytesPerPixel+2];
	    }
	  }
	  // wait for acknowledge before sending
	  if ((readCount=read(connectionDescriptor,buf,sizeof(buf))) > 0)  {
	    // write the data
	    write(connectionDescriptor,outputPtr,width*height*3);
	  }
	  else {
	    // write error message
	    printf("(mglMovieStandAlone) Could not read acknowledge string from socket\n");
	  }
	  free(outputPtr);
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"getPosition")==0) {
	  // get position
	  NSRect frameRect = [movieView frame];
	  sprintf(buf,"%f %f %f %f",frameRect.origin.x,frameRect.origin.y,frameRect.size.width,frameRect.size.height);
	  if (verbose) printf("(mglMovieStandAlone) Sending size: %s\n",buf);
	  // write it to socket
	  if (write(connectionDescriptor,buf,strlen(buf)) != strlen(buf))
	    printf("(mglMovieStandAlone) Could not write framerate string to scoket\n");
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"getFramerate")==0) {
	  // get current time
	  // FIX, FIX, FIX: This always seems to return 0 - needs to be debugged
	  double frameRate = [[movieView movie] rate];
	  printf("(mglMovieStandAlone) The feature to return frameRate may not be working. Needs debugging. Read a rate: %f\n",(double)frameRate);
	  sprintf(buf,"%f",frameRate);
	  // write it to socket
	  if (write(connectionDescriptor,buf,strlen(buf)) != strlen(buf))
	    printf("(mglMovieStandAlone) Could not write framerate string to scoket\n");
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"setFramerate")==0) {
	  double frameRate;
	  frameRate = strtod(extraParams,&extraParams);
	  //	FIX, FIX, FIX, actually set frame rate
	  printf("(mglMovieStandAlone) The feature to set frameRate is not yet implemented. Needs debugging. Got rate to set of: %f\n",(double)frameRate);
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"move")==0) {
	  // get the position to move to
	  int x,y;
	  x = (int)strtod(extraParams,&extraParams);
	  y = (int)strtod(extraParams,&extraParams);
	  if (verbose) printf("move: %i %i\n",x,y);
	  // get current frame rect
	  NSRect frameRect = [movieView frame];
	  // change origin
	  frameRect.origin.x = (CGFloat)x;
	  frameRect.origin.y = (CGFloat)y;
	  // and move
	  [movieView setFrame:frameRect];
	  [movieView display];
	}
	//++++++++++++++++++++++++++++++++
	else if (strcmp(commandName,"moveAndResize")==0) {
	  // get the position to size
	  int x,y,width,height;
	  x = (int)strtod(extraParams,&extraParams);
	  y = (int)strtod(extraParams,&extraParams);
	  width = (int)strtod(extraParams,&extraParams);
	  height = (int)strtod(extraParams,&extraParams);
	  // and move
	  [movieView setFrame:NSMakeRect(x,y,width,height)];
	  [movieView display];
	}
	//++++++++++++++++++++++++++++++++
	else {
	  printf("(mglMovieStandAlone) Unknown command: %s\n",buf);
	}
      }
      if (readCount == -1) {
      perror("(mglMovieStandAlone) Error reading from socket. This prevents communication between matlab and mglMovieStandAlone");
      break;
      }
    }
    // close connection
    close(connectionDescriptor);
  }
}

/////////////////////
//    initMovie    //
/////////////////////
QTMovieView *initMovie(char *filename, NSWindow *myWindow, int showControls)
{
  // init a QTMovie
  NSError *myError = [NSError alloc];
  NSString *NSFilename = [[NSString alloc] initWithCString:filename];
  QTMovie *movie = [QTMovie movieWithURL: [NSURL fileURLWithPath:NSFilename] error:&myError];
  [NSFilename release];

  // see if there was an error
  if ([myError code] != 0) {
    printf("(mglMovieStandAlone) Error opening movie %s: %s\n",filename,[[myError localizedDescription] cStringUsingEncoding:NSASCIIStringEncoding]);

    // release memory
    [movie release];

    // return 
    return NULL;
  }

  // wait until movie has attributes
  while ([[movie attributeForKey:QTMovieLoadStateAttribute] longValue] < QTMovieLoadStateLoaded) usleep(100);

  //  get size of movie
  NSSize movieSize = [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];

  // init the movieView
  QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(0,0,movieSize.width,movieSize.height)];
  
  // set alpha to 0
  [movieView setAlphaValue:0];
  
  // set the movie view up with the movie
  [movieView setMovie:movie];
  [movieView setControllerVisible:(showControls)?YES:NO];

  // get the current frame size, so that we can center the movie
  NSRect myWindowFrame = [myWindow frame];

  // connect to the window and display
  //  [[myWindow contentView] addSubview:movieView];
  [movieView setFrame:NSMakeRect((myWindowFrame.size.width-movieSize.width)/2,(myWindowFrame.size.height-movieSize.height)/2,movieSize.width,movieSize.height)];

  // return the movieView
  return movieView;
}


//////////////////////
//    initWindow    //
//////////////////////
NSWindow *initWindow(int showControls)
{
  int verbose = 1;
  NSWindow *myWindow;
  int screenWidth = 800,screenHeight = 600;

  // start the application -- i.e. connect our code to the window server
  if (NSApplicationLoad() == NO) {
    printf("(mglMovieStandAlone:initWindow) NSApplicationLoad returned NO\n");
    return NULL;
  }

  // set initial size and location
  NSRect contentRect = NSMakeRect(100,100+screenHeight,screenWidth,screenHeight);

  // create the window
  if (showControls)
    myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:false];
  else
    myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:false];
    
  // check for error
  if (myWindow==nil) {
    printf("(mglMovieStandAlone:initWindow) Could not create window\n");
    return NULL;
  }

  // center the window
  [myWindow center];
  [myWindow setAlphaValue:1];

  // set background
  //  [myWindow setOpaque:NO];
  //  [myWindow setBackgroundColor:[NSColor clearColor]];
  [myWindow setOpaque:YES];
  [myWindow setBackgroundColor:[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];

  // sleep for 5000 micro seconds. The window manager appears to need a little bit of time
  // to create the window. There should be a function call to check the window status
  // but, I don't know what it is. The symptom is that if we don't wait here, then
  // the screen comes up in white and then doesn't have the GLContext set properly.
  usleep(5000);

  // show window
  [myWindow orderFront:nil];
  [myWindow display];
  [myWindow orderFrontRegardless];

  // return the window
  return(myWindow);
}

////////////////////////////
//    addOpenGLContext    //
////////////////////////////
NSOpenGLView *addOpenGLContext(NSWindow *myWindow, int setRatherThanAdd) 
{
  int verbose = 1;
  NSOpenGLView *myOpenGLView;
  NSOpenGLContext *myOpenGLContext;

  // set up a pixel format for the openGL context
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 32,
    NSOpenGLPFAStencilSize, 8,
      0
  };
  NSOpenGLPixelFormat* myPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
  if (myPixelFormat==nil) {
    printf("(mglPrivateOpen) Could not create pixel format\n");
    return NULL;
  }

  // Create the openGLview
  myOpenGLView = [[NSOpenGLView alloc] initWithFrame:NSMakeRect(0,0,800,600) pixelFormat:myPixelFormat];
  if (myOpenGLView==nil) {
    printf("(mglPrivateOpen) Could not create openGLView\n");
    return NULL;
  }
  [myPixelFormat release];

  // add as a subview
  if (setRatherThanAdd) 
    // add as contentView
    [myWindow setContentView:myOpenGLView];
  else
    [[myWindow contentView] addSubview:myOpenGLView];

  // get openGL context
  myOpenGLContext = [myOpenGLView openGLContext];
  [myOpenGLContext makeCurrentContext];

  // set it to display
  [myOpenGLView prepareOpenGL];
  [[myWindow contentView] display];
  [myWindow display];

  // set the openGL context to be transparent so that we can see the movie below
  const GLint alphaValue = 0;
  [myOpenGLContext setValues:&alphaValue forParameter:NSOpenGLCPSurfaceOpacity];

  // set the swap interval so that it waits for "vertical refresh"
  const GLint swapInterval = 1;
  [myOpenGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

  // test
  CGLContextObj contextObj = (CGLContextObj)[myOpenGLContext CGLContextObj];
  printf("Test flush\n");
  glClearColor(0,0,0,0);
  glClear(GL_COLOR_BUFFER_BIT);
  glEnable (GL_LINE_SMOOTH);
  glEnable (GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glHint (GL_LINE_SMOOTH_HINT, GL_DONT_CARE);
  glColor4f(0.4,0.7,0.2,1.0); 
  glBegin(GL_LINES);

  
  glVertex2f(-0.1,0);
  glVertex2f(0.1,0);
  glVertex2f(0,0);
  glVertex2f(0,0.1);
  glVertex2f(0,-0.1);
  glVertex2f(0,0);

  glVertex2f(-1,0);
  glVertex2f(1,0);
  glVertex2f(0,0);
  glVertex2f(0,1);
  glVertex2f(0,-1);
  glVertex2f(0,0);

  glEnd();

  glDisable (GL_LINE_SMOOTH);

  glLineWidth(2);
  CGLFlushDrawable(contextObj); 
  printf("Flushed\n");

  return myOpenGLView;
}

////////////////////////////////////////
//    addLayerBackedOpenGLContext     //
////////////////////////////////////////
// TESTING - this does not work
NSOpenGLView *addLayerBackedOpenGLContext(NSWindow *myWindow) 
{
  int verbose = 1;
  NSOpenGLView *myOpenGLView;
  NSOpenGLContext *myOpenGLContext;

  // set up a pixel format for the openGL context
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 32,
    NSOpenGLPFAStencilSize, 8,
      0
  };
  NSOpenGLPixelFormat* myPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
  if (myPixelFormat==nil) {
    printf("(mglPrivateOpen) Could not create pixel format\n");
    return NULL;
  }

  // Create the openGLview
  myOpenGLView = [[NSOpenGLView alloc] initWithFrame:NSMakeRect(0,0,300,200) pixelFormat:myPixelFormat];
  if (myOpenGLView==nil) {
    printf("(mglPrivateOpen) Could not create openGLView\n");
    return NULL;
  }
  [myOpenGLView setWantsLayer:YES];

  // add as a subview
  [[myWindow contentView] addSubview:myOpenGLView];

  // get openGL context
  //  myOpenGLContext = [myOpenGLView openGLContext];
  [myOpenGLContext makeCurrentContext];

  // set it to display
  [myOpenGLView prepareOpenGL];
  [[myWindow contentView] display];
  [myWindow display];

  // set the openGL context to be transparent so that we can see the movie below
  const GLint alphaValue = 0;
  [myOpenGLContext setValues:&alphaValue forParameter:NSOpenGLCPSurfaceOpacity];

  // set the swap interval so that it waits for "vertical refresh"
  const GLint swapInterval = 1;
  [myOpenGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

  CAOpenGLLayer *myOpenGLLayer = (CAOpenGLLayer *)myOpenGLView.layer;
  CGLContextObj myContextObj = [myOpenGLLayer copyCGLContextForPixelFormat:[myPixelFormat CGLPixelFormatObj]];
  [myPixelFormat release];

  printf("Test flush\n");
  glClearColor(0.8,0.4,0.2,0.5);
  glClear(GL_COLOR_BUFFER_BIT);
  CGLFlushDrawable(myContextObj); 
  printf("Flushed\n");
  
  return NULL;

  // test
  CGLContextObj contextObj = (CGLContextObj)[myOpenGLContext CGLContextObj];
  printf("Test flush\n");
  glClearColor(0.2,0.4,0.8,0.5);
  glClear(GL_COLOR_BUFFER_BIT);
  CGLFlushDrawable(contextObj); 
  printf("Flushed\n");


}

