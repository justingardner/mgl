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
#define OPEN 777
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
#define MOVE 13
#define GET_POSITION 14
#define GET_FRAMERATE 15
#define SET_FRAMERATE 16
#define OPENWINDOW 101
#define CLOSEWINDOW 102
#define MOVEWINDOW 103
#define MOVEWINDOWBEHIND 104
#define ORDERFRONT 105
#define SETBACKGROUND 106

#define BUFLEN 4096
#define NANMOVIEPOINTER 99999999

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
  mxArray *retval;

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
    // set arguments
    const mxArray *arg1 = NULL, *arg2 = NULL;
    if (nrhs >= 3) arg1 = prhs[2];
    if (nrhs >= 4) arg2 = prhs[3];
    // check if this is a movie window command
    if (mxIsNaN(*mxGetPr(prhs[0]))) {
      int command = (unsigned long)mxGetScalar(prhs[1]);
      retval = doMovieCommand(command,NANMOVIEPOINTER,arg1,arg2);
    }
    else {
      // get the movie pointer
      mxArray *moviePointerField =  mxGetField(prhs[0],0,"moviePointer");
      if (moviePointerField == NULL) {
	usageError("mglMovie");
	return;
      }
      unsigned long moviePointer = (unsigned long)mxGetScalar(moviePointerField);
      // and the command
      int command = (unsigned long)mxGetScalar(prhs[1]);
    
      // do the movie command
      retval = doMovieCommand(command,moviePointer,arg1,arg2);
    }
    if (retval != NULL) plhs[0] = retval; else plhs[0]=mxCreateDoubleMatrix(0,0,mxREAL);
  }
  else {
    usageError("mglMovie");
    plhs[0]=mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }    
}

//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
///////////////////
//   openMovie   //
///////////////////
unsigned long openMovie(char *filename, int xpos, int ypos, int width, int height)
{
  // verbose
  int verbose = (int)mglGetGlobalDouble("verbose");

  // this is now implemented in doMovieCommand - which sends a command
  // to the separately open app to load the movie up. But need to rework
  // the call to fit the format for doMovieCommand
  mxArray *mxFilename = mxCreateString(filename);
  mxArray *mxMovieNum = doMovieCommand(OPEN,0,mxFilename,NULL);

  // free up memory
  mxDestroyArray(mxFilename);
  
  // get returned value
  unsigned long movieID = -1;
  if (mxMovieNum != NULL)
    movieID = (unsigned long)*(mxGetPr(mxMovieNum));
  mxDestroyArray(mxMovieNum);
  if (verbose) mexPrintf("(mglPrivateMovie) Returned movieID: %i\n",movieID);

  // return the movie identifier
  return(movieID);
}
////////////////////////
//   doMovieCommand   //
////////////////////////
mxArray *doMovieCommand(int command, unsigned long moviePointer, const mxArray *arg1, const mxArray *arg2)
{
  // return value
  mxArray *retval = NULL;

  // verbose
  int verbose = (int)mglGetGlobalDouble("verbose");

  // try to open socket to movie
  struct sockaddr_un socketAddress;
  char buf[BUFLEN];
  int socketDescriptor,readCount;
  char filename[BUFLEN];

  // open the socket
  if ( (socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    perror("(mglPrivateMovie) Could not open socket to communicate with mglMovieStandAlone");
    return retval;
  }

  // set the address
  memset(&socketAddress, 0, sizeof(socketAddress));
  socketAddress.sun_family = AF_UNIX;
  strncpy(socketAddress.sun_path, ".mglMovieSocket", sizeof(socketAddress.sun_path)-1);

  // connect to the socket
  if (connect(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
    // if couldn't connect, means we might need to run stand alone command, but only
    // do this if this is an open
    if ((command == OPEN) || (command == OPENWINDOW)){
      // get where the mgl directory is
      mxArray *callInput[] = {mxCreateString("mglMovie.m")}, *callOutput[1];
      char commandName[BUFLEN];
      mexCallMATLAB(1,callOutput,1,callInput,"which");
      mxGetString(callOutput[0],buf,BUFLEN);
      // make the command name which should be mgl/mgllib/mglMovieSupport/mglMovieStandAlone &
      if (strlen(buf) > 2) {
	buf[strlen(buf)-2] = 0;
	sprintf(commandName,"%sSupport/mglMovieStandAlone &",buf);
	if (verbose) mexPrintf("(mglPrivateMovie) Running: %s\n",commandName);
	system(commandName);
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not run supporting command: mglMovieStandAlone\n");
	close(socketDescriptor);
	return retval;
      }
      // give it a second to start up
      sleep(1);
      // try again to connect to the socket
      if (connect(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
	mexPrintf("(mglPrivateMovie) Could not start mglMovieStandAlone which handles display of movies\n");
	close(socketDescriptor);
	return retval;
      }
    }
    else {
      // Give a warning if we could not connect, but not if this is a closeWindow command
      if (command != CLOSEWINDOW)
	mexPrintf("(mglPrivateMovie) Could not connect to socket %s to communicate with mglMovieStandAlone. Perhaps you did not open any mglMovies yet.\n");
      close(socketDescriptor);
      return retval;
    }
  }
  
  switch(command) {
    //++++++++++++++++++++++++++++++++
    case OPENWINDOW:
      // create command
      sprintf(buf,"openWindow");
      // write command
      if (verbose) mexPrintf("(mglPrivateMovie) Running command: %s\n", buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back ack
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) <= 0) {
	mexPrintf("(mglPrivateMovie) Could not read movieID from mglMovieStandAlone - perhaps socket has closed\n");
      }
      close(socketDescriptor);
      return retval;
      break;
    //++++++++++++++++++++++++++++++++
    case CLOSEWINDOW:
      sprintf(buf,"closeWindow");
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case ORDERFRONT:
      sprintf(buf,"orderFront");
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    case SETBACKGROUND:
      // check arguments
      if ((arg1 == NULL) || mxIsCell(arg1) || ((mxGetN(arg1) != 3)))
	mexPrintf("(mglPrivateMovie) Must pass in a vector of length 3 [r g b]\n");
      else {
	// get color to set to
        double *colorValue = mxGetPr(arg1);
	// send color
	sprintf(buf,"setBackground %f %f %f",colorValue[0],colorValue[1],colorValue[2]);
	if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
	write(socketDescriptor,buf,strlen(buf));
      }
      break;
    //++++++++++++++++++++++++++++++++
    case MOVEWINDOWBEHIND:
      // get the MGL window
      if ((!mglGetGlobalDouble("isCocoaWindow")) || (!mglIsGlobal("displayNumber"))) {
	mexPrintf("(mglPrivateMovie) Can only put movie window behind a cocoa mgl window. Make sure to open the MGL window with mglSetParam(''movieMode'',1); set\n");
      }
      else {
	// get myWindow pointer
	NSWindow *myWindow = (NSWindow*)(unsigned long)mglGetGlobalDouble("cocoaWindowPointer");
	// get the position and size of the MGL window
	NSRect frameRect = [myWindow frame];

	// move the movie window to the same location
	sprintf(buf,"moveAndResizeWindow %0.0f %0.0f %0.0f %0.0f",frameRect.origin.x,frameRect.origin.y,frameRect.size.width,frameRect.size.height);
	if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
	write(socketDescriptor,buf,strlen(buf));

	// order front
	sprintf(buf,"orderFront");
	if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
	write(socketDescriptor,buf,strlen(buf));

	// order the mgl window to the front
	[myWindow orderFront:nil];
	[myWindow orderFrontRegardless];
	[myWindow display];
      }
      break;
    //++++++++++++++++++++++++++++++++
    case MOVEWINDOW:
      // check arguments
      if ((arg1 == NULL) || mxIsCell(arg1) || ((mxGetN(arg1) != 2) && (mxGetN(arg1) != 4)))
	mexPrintf("(mglPrivateMovie) Must pass in a vector of length 2 [x y] or 4 [x y width height]\n");
      else {
	// get position to move to
        double *position = mxGetPr(arg1);
	uint32 positionLen = mxGetN(arg1);
	if (mxGetN(arg1) == 2) {
	  // send position
	  sprintf(buf,"moveWindow %0.0f %0.0f",position[0],position[1]);
	  if (verbose) mexPrintf("(mglPrivateMovie) %s\n",buf);
	  write(socketDescriptor,buf,strlen(buf));
	}
	else {
	  // send position and size
	  sprintf(buf,"moveAndResizeWindow %i %i %i %i",(int)position[0],(int)position[1],(int)position[2],(int)position[3]);
	  if (verbose) mexPrintf("(mglPrivateMovie) %s\n",buf);
	  write(socketDescriptor,buf,strlen(buf));
	}
      }
      break;
    //++++++++++++++++++++++++++++++++
    case OPEN:
      // get filename
      mxGetString(arg1,filename,BUFLEN);
      // create command
      sprintf(buf,"open %s",filename);
      // write command
      if (verbose) mexPrintf("(mglPrivateMovie) Running command: %s\n", buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back id
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) {
	close(socketDescriptor);
	return mxCreateDoubleScalar(strtod(buf,NULL));
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not read movieID from mglMovieStandAlone - perhaps socket has closed\n");
	close(socketDescriptor);
	return retval;
      }
      break;
    //++++++++++++++++++++++++++++++++
    case CLOSE:
      sprintf(buf,"close %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case PLAY:
      sprintf(buf,"play %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case PAUSE:
      sprintf(buf,"pause %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case GOTO_BEGINNING:
      sprintf(buf,"gotoBeginning %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case GOTO_END:
      sprintf(buf,"gotoEnd %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case STEP_FORWARD:
      sprintf(buf,"stepForward %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case STEP_BACKWARD:
      sprintf(buf,"stepBackward %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case HIDE:
      sprintf(buf,"hide %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case SHOW:
      sprintf(buf,"show %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      break;
    //++++++++++++++++++++++++++++++++
    case GET_DURATION:
      sprintf(buf,"getDuration %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back the duration string
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) {
	retval = mxCreateString(buf);
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not read duration string from mglMovieStandAlone - perhaps socket has closed\n");
      }
      break;
    //++++++++++++++++++++++++++++++++
    case GET_CURRENT_TIME:
      sprintf(buf,"getCurrentTime %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back the current time
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) {
	retval = mxCreateString(buf);
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not read current time string from mglMovieStandAlone - perhaps socket has closed\n");
      }

      break;
    //++++++++++++++++++++++++++++++++
    case SET_CURRENT_TIME:
      if ((arg1 == NULL) || (!mxIsChar(arg1)))
	mexPrintf("(mglPrivateMovie) Must pass in a time string\n");
      else {
	// write command
	sprintf(buf,"setCurrentTime %i",(int)moviePointer);
	if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
	write(socketDescriptor,buf,strlen(buf));
	// wait for confirmation and write string
	memset(buf,0,BUFLEN);
	if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) 
	  // write the time string
	  write(socketDescriptor,mxArrayToString(arg1),strlen(mxArrayToString(arg1)));
	else
	  mexPrintf("(mglPrivateMovie) Could not read acknowledge string from socket\n");
      }
      break;
    //++++++++++++++++++++++++++++++++
    case GET_FRAME:
      // write command
      sprintf(buf,"getFrame %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      // wait for confirmation. Should be 2 uint32 with the width and size of frame
      int numCountToRead = sizeof(uint32)*2;
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) != numCountToRead) {
	// did not read properly
	mexPrintf("(mglPrivateMovie) Could not read size of frame from socket\n");
	close(socketDescriptor);
	return retval;
      }
      // convert buf into int array to get width and height
      uint32 *widthAndHeight = (uint32 *)buf;
      if (verbose) mexPrintf("(mglPrivateMovie) width: %i height: %i\n",widthAndHeight[0],widthAndHeight[1]);
      // send acknowledge
      if (write(socketDescriptor,"Ack",3) != 3) {
	mexPrintf("(mglPrivateMovie) Could not send acknowledge message to socket\n");
	close(socketDescriptor);
	return retval;
      }
      // read in data, put into a width x height x3 matlab matrix of uint8
      int totalReadCount = 0,bufSize = widthAndHeight[0]*widthAndHeight[1]*3;
      // note that width/height are intentionally swaped here so that
      // image displays correctly when you do imagesc
      mwSize dims[3] = {widthAndHeight[1], widthAndHeight[0], 3};
      retval = mxCreateNumericArray(3, dims, mxUINT8_CLASS, mxREAL);
      uint8 *outputPtr = (uint8 *)mxGetPr(retval), *outputPtrReader = outputPtr;
      // need to read in blocks
      while ((readCount=read(socketDescriptor,outputPtrReader,bufSize)) != 0) {
	// udpate total read
	totalReadCount += readCount;
	// as long as we haven't read over the end of the buffer keep going
	if (totalReadCount <= bufSize)
	  outputPtrReader += readCount;
	else 
	  break;
      }
      // check that we read as much as we thought we would
      if (totalReadCount != bufSize)
	mexPrintf("(mglPrivateMovie) Could not read frame from socket. Got %i bytes when expecting %i\n",totalReadCount,bufSize);
      break;
    //++++++++++++++++++++++++++++++++
    case MOVE:
      // check arguments
      if ((arg1 == NULL) || mxIsCell(arg1) || ((mxGetN(arg1) != 2) && (mxGetN(arg1) != 4)))
	mexPrintf("(mglPrivateMovie) Must pass in a vector of length 2 [x y] or 4 [x y width height]\n");
      else {
	// get position to move to
        double *position = mxGetPr(arg1);
	uint32 positionLen = mxGetN(arg1);
	if (mxGetN(arg1) == 2) {
	  // send position
	  sprintf(buf,"move %i %i %i",(int)moviePointer,(int)position[0],(int)position[1]);
	  write(socketDescriptor,buf,strlen(buf));
	}
	else {
	  // send position and size
	  sprintf(buf,"moveAndResize %i %i %i %i %i",(int)moviePointer,(int)position[0],(int)position[1],(int)position[2],(int)position[3]);
	  write(socketDescriptor,buf,strlen(buf));
	}
      }
      break;
    //++++++++++++++++++++++++++++++++
    case GET_POSITION:
      sprintf(buf,"getPosition %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back the current position
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) {
	retval = mxCreateDoubleMatrix(1,4,mxREAL);
	double *pos = mxGetPr(retval);
	char *readBuf;
	pos[0] =  strtod(buf,&readBuf);
	pos[1] =  strtod(readBuf,&readBuf);
	pos[2] =  strtod(readBuf,&readBuf);
	pos[3] =  strtod(readBuf,&readBuf);
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not read position from mglMovieStandAlone - perhaps socket has closed\n");
      }

      break;
    //++++++++++++++++++++++++++++++++
    case GET_FRAMERATE:
      sprintf(buf,"getFramerate %i",(int)moviePointer);
      if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
      write(socketDescriptor,buf,strlen(buf));
      // read back the current time
      memset(buf,0,BUFLEN);
      if ((readCount=read(socketDescriptor,buf,sizeof(buf))) > 0) {
	retval = mxCreateDoubleMatrix(1,1,mxREAL);
	double *outbuf = mxGetPr(retval);
	outbuf[0] = strtod(buf,NULL);
      }
      else {
	mexPrintf("(mglPrivateMovie) Could not read framerate from mglMovieStandAlone - perhaps socket has closed\n");
      }

      break;
    //++++++++++++++++++++++++++++++++
    case SET_FRAMERATE:
      if (arg1 == NULL) 
	mexPrintf("(mglPrivateMovie) Must pass in a time string\n");
      else {
	// write command
	sprintf(buf,"setFramerate %i %f",(int)moviePointer,*mxGetPr(arg1));
	if (verbose) mexPrintf("(mglPrivateMovie): Sending: %s\n",buf);
	write(socketDescriptor,buf,strlen(buf));
      }
      break;
    //++++++++++++++++++++++++++++++++
    default:
      mexPrintf("(mglPrivateMovie) Unknown command %i\n",command);
      break;
  }
  close(socketDescriptor);
  return retval;
}

#endif //__APPLE__
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
