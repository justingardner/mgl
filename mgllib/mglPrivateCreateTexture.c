#ifdef documentation
=========================================================================

     program: mglCreateTexture.c 
          by: justin gardner with add-ons by Jonas Larsson
        date: 04/09/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: sets up a texture element to be in VRAM
              see Red book Chapter 9

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
#define BYTEDEPTH 4
#define WRAP_S 0
#define WRAP_T 1
#define MAG_FILTER 2
#define MIN_FILTER 3
#define TEXTURE_DATATYPE GL_UNSIGNED_BYTE // Independent of endianness
// #define TEXTURE_DATATYPE GL_UNSIGNED_INT_8_8_8_8 // This is endian-dependent and should be avoided

int sub2ind( int row, int col, int height, int elsize ) {
  // return linear index corresponding to (row,col) into Matlab array
  return ( row*elsize + col*height*elsize );
}

//////////////////////////////
//   function declartions   //
//////////////////////////////
// getmsec is used for profiling
double getmsec()
{
#ifdef _WIN32
  LARGE_INTEGER freq, t;
  
  if (QueryPerformanceFrequency(&freq) == FALSE) {
    mexPrintf("(mglPrivateCreateTexture) Could not get high resolution timer frequency.\n");
    return -1;
  }
  
  if (QueryPerformanceCounter(&t) == FALSE) {
    mexPrintf("(mglPrivateCreateTexture) Could not get high resolution timer value.\n");
    return -1;
  }

  return (double)t.QuadPart/(double)freq.QuadPart*1000.0;
#endif

#ifdef __linux__
  struct timeval tp;
  struct timezone tz;

  gettimeofday( &tp, &tz );
  
  return (double)tp.tv_sec + (double)tp.tv_usec * 0.000001;
#endif

#ifdef __APPLE__
#ifdef __MAC_10_8
  static const double kOneBillion = 1000 * 1000 * 1000; 
  static mach_timebase_info_data_t sTimebaseInfo;

  if (sTimebaseInfo.denom == 0) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  // This seems to work on Mac OS 10.9 with a Mac PRO. But note that sTimebaseInfo is hardware implementation
  // dependent. The mach_absolute_time is ticks since the machine started and to convert it to ms you
  // multiply by the fraction in sTimebaseInfo - worried that this could possibly overflow the
  // 64 bit int values depending on what is actually returned. Maybe that is not a problem
  return((double)((mach_absolute_time()*(uint64_t)(sTimebaseInfo.numer)/(uint64_t)(sTimebaseInfo.denom)))/kOneBillion);
#else
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)currentTime.hi; 
  double lowerHalf = (double)currentTime.lo; 
  
  doubleValue = (upperHalf * twoPower32) + lowerHalf;
  
  return doubleValue/1000;
#endif
#endif
}

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // declare some variables
  GLenum textureType;
  int i,j;
  int liveBuffer = 0;
  double *textureParams;
  int profile = 0;
  double startTime;

  if (profile) startTime = getmsec();

  // check for open window
  if (!mglIsWindowOpen()) {
    mexPrintf("(mglPrivateCreateTexture) No window is open\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // check input arguments
  if (nrhs > 4) {
    // if not supported, call matlab help on the file
    const int ndims = 1;
    const int dims[] = {1};
    mxArray *callInput[] = {mxCreateString("mglCreateTexture")};
    mexCallMATLAB(0,NULL,1,callInput,"help");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }  

  // Get the live buffer pointer.  A value of 0 effectively means that
  // no live buffer will be used.
  if (nrhs >= 3) {
    liveBuffer = (int)*(double *)mxGetPr(prhs[2]);
  }

  // Get the texture parameters.  Set some defaults if none were passed.
  if (nrhs == 4) {
    textureParams = mxGetPr(prhs[3]);
  }
  else {
    textureParams = (double*)mxMalloc(4 * sizeof(double));
    textureParams[WRAP_S] = GL_CLAMP_TO_EDGE;
    textureParams[WRAP_T] = GL_CLAMP_TO_EDGE;
    textureParams[MAG_FILTER] = GL_LINEAR;
    textureParams[MIN_FILTER] = GL_LINEAR;
  }

  // get status of global variable that sets wether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");
  // check for null input pointer
  if (mxGetPr(prhs[0]) == NULL) {
    mexPrintf("(mglPrivateCreateTexture) Input is empty\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // variables for dimensions
  const mwSize *dims = mxGetDimensions(prhs[0]); // rows cols
  const mwSize ndims = mxGetNumberOfDimensions(prhs[0]); 
  const size_t n = mxGetNumberOfElements(prhs[0]);
  int imageWidth, imageHeight;

  // test the data type of the input array
  bool dataIsFormatted = FALSE;
  if (mxIsUint8(prhs[0])) {
    // if we are being passed a unit8 array, then 
    // we assume that the data has been preformatted and that we can just 
    // copy it directly into the texture
    if (verbose) mexPrintf("(mglPrivateCreateTexture) Input matrix is UINT8, copying directly into texture\n");
    dataIsFormatted = TRUE;
    // for uint8 creation there is no buffer which we are copying from
    liveBuffer = FALSE;
    // check dimensions
    if (ndims != 3) {
      mexPrintf("(mglPrivateCreateTexture) Input for uint8 should be 4xnxm (rgba x width x height)\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    // make sure we have a valid number of pixel values
    if (dims[0] != 4) {
      mexPrintf("(mglPrivateCreateTexture) Input for uint8 should be 4xnxm (rgba x width x height)\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    // get image size and type
    imageWidth = (int)dims[1];
    imageHeight = (int)dims[2];
  }
  // otherwise if the datatype is not UINT8 check to see if it is double
  else if (mxIsDouble(prhs[0])) {
    // check to see that we don't have too many dimensions
    if ((ndims != 2) && (ndims != 3)) {
      mexPrintf("(mglPrivateCreateTexture) Input should be either nxm (grayscale), nxmx3 (color) or nxmx4 (color w/alpha)\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    // make sure we have a valid number of pixel values
    if ((ndims == 3) && ((dims[2] != 1) && (dims[2] != 3) && (dims[2] != 4))) {
      mexPrintf("(mglPrivateCreateTexture) Input should be either nxm (grayscale), nxmx3 (color) or nxmx4 (color w/alpha)\n");
      plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      return;
    }
    // get image size and type
    imageWidth = (int)dims[1];
    imageHeight = (int)dims[0];
  }
  // if neither UINT8 or double return error
  else {
    // unknown data type for input matrix
    mexPrintf("(mglPrivateCreateTexture) Input matrix should be of type double or uint8\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // set what kind of texture this is
  if (imageHeight == 1)
    // a 1D texture
    textureType = GL_TEXTURE_1D;
  else {
#ifndef GL_TEXTURE_RECTANGLE_EXT
    // for systems without rectangular textures, use 2D texture
    textureType = GL_TEXTURE_2D;
#else
    // rectangular textures
    textureType = GL_TEXTURE_RECTANGLE_EXT;
#endif
  }


  size_t imageType;
  if (ndims == 2) imageType = 1; else imageType = dims[2];

  // if everything is ok, in verbose mode display some info
  if (verbose) {
    mexPrintf("(mglPrivateCreateTexture) imagesize (width x height): %ix%i (%i rows x %i columns) (%i dims) ",imageWidth,imageHeight,mxGetM(prhs[0]), mxGetN(prhs[0]),mxGetNumberOfDimensions(prhs[0]));
    switch (imageType) {
      case 1: mexPrintf("grayscale\n"); break;
      case 3: mexPrintf("color\n"); break;
      case 4: mexPrintf("color w/alpha\n"); break;
    }
  }


  if (profile) {
    mexPrintf("(mglPrivateCreateTexture) Arg processing %f\n",getmsec()-startTime);
    startTime = getmsec();
  }
  // now create a temporary buffer for the image, unless we were passed
  // in UINT8 data in which we are going to directly copy.
  GLubyte *imageFormatted;
  if (dataIsFormatted) {
    // already formatted UNIT8 data, just copy the pointer
    imageFormatted = (GLubyte*)	mxGetPr(prhs[0]);
  }
  else {
    // allocate temporary memory to make copy into
    imageFormatted = (GLubyte*)malloc(imageWidth*imageHeight*sizeof(GLubyte)*BYTEDEPTH);

    // get the input image data
    double *imageData = mxGetPr(prhs[0]);
    if (profile) {
      mexPrintf("(mglPrivateCreateTexture) Memory allocation %f\n",getmsec()-startTime);
      startTime = getmsec();
    }

    
    // and fill it with the image
    ////////////////////////////
    // grayscale image
    int widthDepth = imageWidth*BYTEDEPTH;
    int c=0;
    if (imageType == 1) {
        for (j = 0; j < imageWidth; j++, c+=BYTEDEPTH) { //cols
            int colStart = j*imageHeight;

            for (i = 0; i < imageHeight; i++) { //rows
                int ind = i + colStart;
                int outind = i*widthDepth;

                imageFormatted[c+outind] = (GLubyte)imageData[ind];
                imageFormatted[c+outind+1] = (GLubyte)imageData[ind];
                imageFormatted[c+outind+2] = (GLubyte)imageData[ind];
                imageFormatted[c+outind+3] = (GLubyte)255;
            }
        }
    }
    
    ////////////////////////////
    // color image
    else if (imageType == 3) {
        int imageSize = imageWidth*imageHeight;
        int imageSize2 = imageSize*2;
        
        for (j = 0; j < imageWidth; j++, c+=BYTEDEPTH) {
            int colStart = j*imageHeight;

            for (i = 0; i < imageHeight; i++) {
                int ind = i + colStart;
                int outind = i*widthDepth;
                
                imageFormatted[c+outind]   = (GLubyte)imageData[ind];
                imageFormatted[c+outind+1] = (GLubyte)imageData[ind+imageSize];
                imageFormatted[c+outind+2] = (GLubyte)imageData[ind+imageSize2];
                imageFormatted[c+outind+3] = (GLubyte)255;
            }
        }
    }
    
    ////////////////////////////
    // color+alpha image
    else if (imageType == 4) {
        int imageSize = imageWidth*imageHeight;
        int imageSize2 = imageSize*2;
        int imageSize3 = imageSize*3;
        
        for (j = 0; j < imageWidth;j++, c+=BYTEDEPTH) {
            int colStart = j*imageHeight;
            
            for (i = 0; i < imageHeight; i++) {
                int ind = i + colStart;
                int outind = i*widthDepth;

                imageFormatted[c+outind] = (GLubyte)imageData[ind];
                imageFormatted[c+outind+1] = (GLubyte)imageData[ind+imageSize];
                imageFormatted[c+outind+2] = (GLubyte)imageData[ind+imageSize2];
                imageFormatted[c+outind+3] = (GLubyte)imageData[ind+imageSize3];
            }
        }
    }
  }

  
  if (profile) {
    mexPrintf("(mglPrivateCreateTexture) Copying memory %f\n",getmsec()-startTime);
    startTime = getmsec();
  }
  GLuint textureNumber;
  // get a unique texture identifier name
  glGenTextures(1, &textureNumber);

  // If rectangular textures are unsupported, scale image to nearest dimensions
  if (textureType == GL_TEXTURE_2D) {
    // No support for non-power of two textures
    int po2Width=imageWidth;
    int po2Height=imageHeight;
    double lw=log((double)imageWidth)/log(2.0);
    double lh=log((double)imageHeight)/log(2.0);
    if ((lw !=round(lw)) | (lh !=round(lh))) {
      po2Width=(int) pow(2,round(lw));
      po2Height=(int) pow(2,round(lh));
      if (verbose) {
	mexPrintf("(mglPrivateCreateTexture) Only support for power-of-2 sized textures on this platform.\n");
	mexPrintf("(mglPrivateCreateTexture) Scaling image to nearest power-of-2 size...\n");
	mexPrintf("(mglPrivateCreateTexture) Scaled size is (width x height): %i x %i\n",po2Width,po2Height);
      }
      GLubyte * tmp =(GLubyte*)malloc(po2Width*po2Height*sizeof(GLubyte)*BYTEDEPTH);
      gluScaleImage( GL_RGBA, imageWidth, imageHeight, TEXTURE_DATATYPE, imageFormatted, po2Width, po2Height, TEXTURE_DATATYPE, tmp);
      free(imageFormatted);
      imageFormatted=tmp;
    }
    glBindTexture(textureType, textureNumber);
    glTexParameteri(textureType, GL_TEXTURE_WRAP_S, (GLint)textureParams[WRAP_S]);
    glTexParameteri(textureType, GL_TEXTURE_WRAP_T, (GLint)textureParams[WRAP_T]);
    glTexParameteri(textureType, GL_TEXTURE_MAG_FILTER, (GLint)textureParams[MAG_FILTER]);
    glTexParameteri(textureType, GL_TEXTURE_MIN_FILTER, (GLint)textureParams[MIN_FILTER]);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

    // now place the data into the texture
    glTexImage2D(GL_TEXTURE_2D,0,4,po2Width,po2Height,0,GL_RGBA,TEXTURE_DATATYPE,imageFormatted);

  }
  else if (textureType == GL_TEXTURE_RECTANGLE_EXT) {
    // Support for non-power of two textures
    glBindTexture(textureType, textureNumber);

#ifdef __APPLE__
    // tell GL that the memory will be handled by us. (apple)
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE,0);
    // now, try to store the memory in VRAM (apple)
    glTexParameteri(textureType,GL_TEXTURE_STORAGE_HINT_APPLE,GL_STORAGE_CACHED_APPLE);
    glTextureRangeAPPLE(textureType,imageWidth*imageHeight*BYTEDEPTH,imageFormatted);
#endif

    // some other stuff
    glTexParameteri(textureType, GL_TEXTURE_WRAP_S, (GLint)textureParams[WRAP_S]);
    glTexParameteri(textureType, GL_TEXTURE_WRAP_T, (GLint)textureParams[WRAP_T]);
    glTexParameteri(textureType, GL_TEXTURE_MAG_FILTER, (GLint)textureParams[MAG_FILTER]);
    glTexParameteri(textureType, GL_TEXTURE_MIN_FILTER, (GLint)textureParams[MIN_FILTER]);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
    // now place the data into the texture
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,imageWidth,imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,imageFormatted);

  }
  else if (textureType == GL_TEXTURE_1D) {

    // Support for non-power of two textures
    glBindTexture(textureType, textureNumber);

#ifdef __APPLE__
    // tell GL that the memory will be handled by us. (apple)
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE,0);
    // now, try to store the memory in VRAM (apple)
    glTexParameteri(textureType,GL_TEXTURE_STORAGE_HINT_APPLE,GL_STORAGE_CACHED_APPLE);
    glTextureRangeAPPLE(textureType,imageWidth*imageHeight*BYTEDEPTH,imageFormatted);
#endif

    // some other stuff
    glTexParameteri(textureType, GL_TEXTURE_WRAP_S, (GLint)textureParams[WRAP_S]);
    glTexParameteri(textureType, GL_TEXTURE_WRAP_T, (GLint)textureParams[WRAP_T]);
    glTexParameteri(textureType, GL_TEXTURE_MAG_FILTER, (GLint)textureParams[MAG_FILTER]);
    glTexParameteri(textureType, GL_TEXTURE_MIN_FILTER, (GLint)textureParams[MIN_FILTER]);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

    // now place the data into the texture
    glTexImage1D(textureType,0,GL_RGBA,imageWidth,0,GL_RGBA,TEXTURE_DATATYPE,imageFormatted);
  }

  if (profile) {
    mexPrintf("(mglPrivateCreateTexture) Binding texture %f\n",getmsec()-startTime);
    startTime = getmsec();
  }
  // error status checking commented out, since it just returns
  // a number that doesn't mean anything to the user.
  //GLenum err=glGetError();
  //if (err != noErr) {
  //  mexPrintf("(mglCreateTexture): Got gl error number %i\n", err);
  //}

  // free temporary image storage
  if (!liveBuffer && !dataIsFormatted) {
    free(imageFormatted);
  }

  // create the output structure
  const char *fieldNames[] =  {"textureNumber","imageWidth","imageHeight","textureAxes","textureType","liveBuffer" };
  mwSize outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,6,fieldNames);

  // now set the textureNumber field
  double *outptr;
  mxSetField(plhs[0],0,"textureNumber",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textureNumber"));
  *outptr = (double)textureNumber;

  // now set the imageWidth and height and axis order
  char charptr[3];
  memset(charptr,0,3);
  if ( nrhs>1 ) {
    if (mxGetNumberOfElements( prhs[1] )==2) {
      mxGetString(prhs[1],charptr,3);
    }
  } else if (mglIsGlobal("defaultTextureAxes")) {   
    if (mxGetNumberOfElements( mglGetGlobalField("defaultTextureAxes") )==2) {
      mxGetString(mglGetGlobalField("defaultTextureAxes"),charptr,3);
    } 
  }

  if (*charptr==0) {
    mxSetField(plhs[0],0,"textureAxes",mxCreateString("yx"));  
  } else 
    mxSetField(plhs[0],0,"textureAxes",mxCreateString(charptr));  


  // set width and height
  mxSetField(plhs[0],0,"imageWidth",mxCreateDoubleMatrix(1,1,mxREAL));
  mxSetField(plhs[0],0,"imageHeight",mxCreateDoubleMatrix(1,1,mxREAL));

  if (strncmp(charptr,"xy",2)==0) {
    // transpose w & h
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageHeight"));
    *outptr = (double)imageWidth;
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageWidth"));
    *outptr = (double)imageHeight;

  } else {
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageWidth"));
    *outptr = (double)imageWidth;
    outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageHeight"));
    *outptr = (double)imageHeight;
  }

  // set the textureType
  mxSetField(plhs[0],0,"textureType",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textureType"));
  *outptr = (double)textureType;

  // set the liveBuffer
  mxSetField(plhs[0],0,"liveBuffer",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"liveBuffer"));
  if (liveBuffer) {
    *outptr = (double)(unsigned long)imageFormatted;
  }
  else {
    *outptr = 0;
  }
  if (profile) {
    mexPrintf("(mglPrivateCreateTexture) Output %f\n",getmsec()-startTime);
    startTime = getmsec();
  }
}

