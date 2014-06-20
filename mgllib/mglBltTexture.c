#ifdef documentation
=========================================================================

     program: mglBltTexture.c
          by: justin gardner with modifications by Jonas Larsson
        date: 04/09/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: moves a texture on to the screen
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
#define LEFT -1
#define CENTER 0
#define RIGHT 1
#define TOP -1
#define BOTTOM 1
#define DEFAULT_H_ALIGNMENT CENTER
#define DEFAULT_V_ALIGNMENT CENTER
#define XY 1
#define YX 0

//////////////////////////
//   type declartions   //
//////////////////////////
typedef struct textype {
  GLuint textureNumber;
  GLenum textureType;
  double imageWidth;
  double imageHeight;
  int textureAxes;
  int vFlip;
  int hFlip;
  double textOverhang;
  int isText;
  double displayRect[4];
  double rotation;
} textype;

//////////////////////////////
//   function declartions   //
//////////////////////////////
// getmsec is used for profiling
double getmsec()
{
#ifdef _WIN32
  LARGE_INTEGER freq, t;
  
  if (QueryPerformanceFrequency(&freq) == FALSE) {
    mexPrintf("(mglBltTexture) Could not get high resolution timer frequency.\n");
    return -1;
  }
  
  if (QueryPerformanceCounter(&t) == FALSE) {
    mexPrintf("(mglBltTexture) Could not get high resolution timer value.\n");
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
  int profile = 0;
  double functionStartTime;
  if (profile) functionStartTime = getmsec();

  
  // check for open window
  if (!mglIsWindowOpen()) {
    mexPrintf("(mglBltTexture) No window is open\n");
    return;
  }

  // check input arguments
  if (nrhs < 2) {
    // if not supported, call matlab help on the file
    usageError("mglBltTexture");
    return;
  }

  // declarae some variables
  size_t numTextures = mxGetNumberOfElements(prhs[0]);
  char textureAxesString[3];
  double xPixelsToDevice, yPixelsToDevice,deviceHDirection,deviceVDirection;
  int verbose;
  double startTime;
  textype *tex;
  double *allParams;
  int texnum;

  // allocate space for texture info
  tex = (textype*)malloc(numTextures*sizeof(textype));

  // now get destination rectangle
  double *inputRect;
  if ((inputRect = (double *)mxGetPr(prhs[1])) == NULL) {
    mexPrintf("(mglBltTexture): Empty destination rect\n");
    free(tex);
    return;
  }
  int inputRectCols = (int)mxGetN(prhs[1]);
  int inputRectRows = (int)mxGetM(prhs[1]);
  int inputRectOffset;
  if ((inputRectRows != 1) && (inputRectRows != numTextures)) {
    mexPrintf("(mglBltTexture) Dest rect must be either 1 or number of texture rows long\n");
    free(tex);
    return;
  }
  if ((inputRectCols != 2) && (inputRectCols != 4) && (inputRectCols != 3)) {
    mexPrintf("(mglBltTexture) Dest rect must be either 2 or 4 columns long\n");
    free(tex);
    return;
  }

  if (profile) startTime = getmsec();

  for (texnum = 0; texnum < numTextures; texnum++) {
    if (mxGetField(prhs[0],texnum,"allParams") != 0) {
      // grab all the info from the allParams field
      allParams = mxGetPr(mxGetField(prhs[0],texnum,"allParams"));
      tex[texnum].textureNumber = (GLuint)allParams[0];
      tex[texnum].imageWidth = allParams[1];
      tex[texnum].imageHeight = allParams[2];
      tex[texnum].textureAxes = allParams[3];
      tex[texnum].hFlip = allParams[4];
      tex[texnum].vFlip = allParams[5];
      tex[texnum].textOverhang = allParams[6];
      tex[texnum].isText = allParams[7];
      xPixelsToDevice = allParams[8];
      yPixelsToDevice = allParams[9];
      deviceHDirection = allParams[10];
      deviceVDirection = allParams[11];
      verbose = (int)allParams[12];
      tex[texnum].textureType = (GLenum)allParams[13];
    }
    else {
      xPixelsToDevice = mglGetGlobalDouble("xPixelsToDevice");
      yPixelsToDevice = mglGetGlobalDouble("yPixelsToDevice");
      verbose = (int)mglGetGlobalDouble("verbose");
      deviceHDirection = mglGetGlobalDouble("deviceHDirection");
      deviceVDirection = mglGetGlobalDouble("deviceVDirection");
      if (profile) {
	mexPrintf("Globals %f\n",getmsec()-startTime);
	startTime = getmsec();
      }

      // get the texture number and imageWidth and imageHeight
      // check to make sure that the input strucutre properly contains these fields
      if (mxGetField(prhs[0],texnum,"textureNumber") != 0)
      tex[texnum].textureNumber = (GLuint)*mxGetPr(mxGetField(prhs[0],texnum,"textureNumber"));
      else {
	mexPrintf("(mglBltTexture): TextureNumber field not defined in texture");
	free(tex);
	return;
      }
      if (mxGetField(prhs[0],texnum,"textureType") != 0)
      tex[texnum].textureType = (GLenum)*mxGetPr(mxGetField(prhs[0],texnum,"textureType"));
      else {
	mexPrintf("(mglBltTexture): TextureType field not defined in texture");
	tex[texnum].textureType = GL_TEXTURE_RECTANGLE_EXT;
      }
      if (mxGetField(prhs[0],texnum,"imageWidth") != 0)
	tex[texnum].imageWidth = (double)*mxGetPr(mxGetField(prhs[0],texnum,"imageWidth"));
      else {
	mexPrintf("(mglBltTexture): imageWidth field not defined in texture\n");
	free(tex);
	return;
      }
      if (mxGetField(prhs[0],texnum,"imageHeight") != 0)
	tex[texnum].imageHeight = (double)*mxGetPr(mxGetField(prhs[0],texnum,"imageHeight"));
      else {
	mexPrintf("(mglBltTexture): imageHeight field not defined in texture\n");
	free(tex);
	return;
      }
      if (mxGetField(prhs[0],texnum,"textureAxes") != 0) {
	mxGetString(mxGetField(prhs[0],texnum,"textureAxes"),textureAxesString,3);
	if (strncmp(textureAxesString,"yx",2)==0) {
	  tex[texnum].textureAxes = YX;
	}
	else if (strncmp(textureAxesString,"xy",2)==0) {
	  tex[texnum].textureAxes = XY;
	}
      }
      else {
	mexPrintf("(mglBltTexture): textureAxes field not defined in texture\n");
	free(tex);
	return;
      }
      if (mxGetField(prhs[0],texnum,"hFlip") != 0)
	tex[texnum].hFlip = (double)*mxGetPr(mxGetField(prhs[0],texnum,"hFlip"));
      else {
	mexPrintf("(mglBltTexture): hFlip field not defined in texture\n");
	free(tex);
	return;
      }
      if (mxGetField(prhs[0],texnum,"vFlip") != 0)
	tex[texnum].vFlip = (double)*mxGetPr(mxGetField(prhs[0],texnum,"vFlip"));
      else {
	mexPrintf("(mglBltTexture): vFlip field not defined in texture\n");
	free(tex);
	return;
      }
      // now check to see if this is a text texture and
      // offset the vertical position if necessary to deal
      // with overhang characters like 'g'
      if (mxGetField(prhs[0],texnum,"textImageRect") != NULL) {
	if (mxGetN(mxGetField(prhs[0],texnum,"textImageRect")) == 4) {
	  // get the second array element of textImageRect and this will
	  // be used to modify the imageHeight for alignment
	  tex[texnum].textOverhang = (*(mxGetPr(mxGetField(prhs[0],texnum,"textImageRect"))+1))*yPixelsToDevice;
	  tex[texnum].isText = 1;
	}
	else {
	  mexPrintf("(mglBltTexture) The input text texture has an invalid textImageRect\n");
	  free(tex);
	  return;
	}
      } 
    }
    
    if (profile) {
      mexPrintf("Fields %f\n",getmsec()-startTime);
      startTime = getmsec();
    }
    
    // get the xPixelsToDevice and yPixelsToDevice making sure these are set properly
    if ((xPixelsToDevice == 0) || (yPixelsToDevice == 0)) {
      mexPrintf("(mglBltTexture) UHOH: pixelsToDevice not set properly, using 1->1\n");
      xPixelsToDevice = 1;yPixelsToDevice = 1;
    }

    // check the length of position

    inputRectOffset = (inputRectRows == 1) ? 0 : texnum;
    if (verbose) mexPrintf("inputRectOffset: %i\n",inputRectOffset);
    switch (inputRectCols) {
      case 2:
	tex[texnum].displayRect[0] = inputRect[inputRectOffset];
	tex[texnum].displayRect[1] = inputRect[inputRectOffset+inputRectRows];
	tex[texnum].displayRect[2] = tex[texnum].imageWidth*xPixelsToDevice;
	tex[texnum].displayRect[3] = tex[texnum].imageHeight*yPixelsToDevice;
	break;
      case 3:
	tex[texnum].displayRect[0] = inputRect[inputRectOffset];
	tex[texnum].displayRect[1] = inputRect[inputRectOffset+inputRectRows];
	tex[texnum].displayRect[2] = tex[texnum].imageWidth*xPixelsToDevice;
	tex[texnum].displayRect[3] = inputRect[inputRectOffset+inputRectRows*2];
	break;
      case 4:
	tex[texnum].displayRect[0] = inputRect[inputRectOffset];
	tex[texnum].displayRect[1] = inputRect[inputRectOffset+inputRectRows];
	tex[texnum].displayRect[2] = inputRect[inputRectOffset+inputRectRows*2];
	tex[texnum].displayRect[3] = inputRect[inputRectOffset+inputRectRows*3];
	break;
      default:
	mexPrintf("(mglBltTexture): Destination rectangle must be either [xmin ymin] or [xmin ymin xmax ymax]\n");
	free(tex);
	return;
	break;
    }
    // set any nan positions to defaults
    double displayRectDefaults[] = {0,0,tex[texnum].imageWidth*xPixelsToDevice,tex[texnum].imageHeight*yPixelsToDevice};
    int i;
    for (i = 0;i < 4;i++)
      if (mxIsNaN(tex[texnum].displayRect[i]))
	tex[texnum].displayRect[i] = displayRectDefaults[i];


    if (verbose)
      mexPrintf("(mglBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",tex[texnum].displayRect[0],tex[texnum].displayRect[1],tex[texnum].displayRect[2],tex[texnum].displayRect[3]);


    // declare some variables for dealing with alignment
    int hAlignment, vAlignment;
    // check the alginment options
    if (nrhs < 3) {
      hAlignment = DEFAULT_H_ALIGNMENT;
    }
    else {
      hAlignment = ((int)mxGetN(prhs[2]) > texnum) ? *(mxGetPr(prhs[2])+texnum) : *mxGetPr(prhs[2]);
      if ((hAlignment != CENTER) && (hAlignment != LEFT) && (hAlignment != RIGHT)) {
        mexPrintf("(mglBltTexture) Unknown hAlignment %i\n",*mxGetPr(prhs[2]));
        free(tex);
        return;
      }
    }
    if (verbose) mexPrintf("(mglBltTexture) hAlignment is %s\n",(hAlignment == CENTER)?"center":((hAlignment == LEFT)?"left":"right"));

    // check the alginment options for vertical
    if (nrhs < 4) {
      vAlignment = DEFAULT_V_ALIGNMENT;
    }
    else {
      vAlignment = (mxGetN(prhs[3]) > texnum) ? *(mxGetPr(prhs[3])+texnum) : *mxGetPr(prhs[3]);
      if ((vAlignment != CENTER) && (vAlignment != TOP) && (vAlignment != BOTTOM)) {
        mexPrintf("(mglBltTexture) Unknown vAlignment %i\n",*mxGetPr(prhs[3]));
        free(tex);
        return;
      }
    }
    if (verbose) mexPrintf("(mglBltTexture) vAlignment is %s\n",(vAlignment == CENTER)?"center":((vAlignment == TOP)?"top":"bottom"));

    // check the rotation
    if (nrhs < 5) {
      tex[texnum].rotation = 0;
    }
    else {
      tex[texnum].rotation = ((int)mxGetN(prhs[4]) > texnum) ? *(mxGetPr(prhs[4])+texnum) : *mxGetPr(prhs[4]);
    }
    if (verbose) mexPrintf("(mglBltTexture) rotation is %f\n",tex[texnum].rotation);

    // display text overhang
    if (verbose) mexPrintf("(mglBltTexture) Text overhang = %0.2f\n",tex[texnum].textOverhang);

    // ok now fix horizontal alignment
    if (hAlignment == CENTER) {
      tex[texnum].displayRect[0] = tex[texnum].displayRect[0] - (tex[texnum].displayRect[2]+tex[texnum].textOverhang)/2;
    }
    else if (hAlignment == RIGHT) {
      if (deviceHDirection > 0)
        tex[texnum].displayRect[0] = tex[texnum].displayRect[0] - (tex[texnum].displayRect[2]+tex[texnum].textOverhang);
    }
    else if (hAlignment == LEFT) {
      if (deviceHDirection < 0)
        tex[texnum].displayRect[0] = tex[texnum].displayRect[0] + (tex[texnum].displayRect[2]+tex[texnum].textOverhang);
    }

    // ok now fix vertical alignment
    if (vAlignment == CENTER) {
      tex[texnum].displayRect[1] = tex[texnum].displayRect[1] - (tex[texnum].displayRect[3]+tex[texnum].textOverhang)/2;
      if (deviceVDirection > 0) {
	// and adjust overhang
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1]+tex[texnum].textOverhang;
      }
    }
    else if (vAlignment == BOTTOM) {
      if (deviceVDirection < 0) {
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1] - (tex[texnum].displayRect[3]+tex[texnum].textOverhang);
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1]-tex[texnum].textOverhang;
      }
      else {
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1]+2*tex[texnum].textOverhang;
      }
    }
    else if (vAlignment == TOP) {
      if (deviceVDirection > 0) {
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1] - (tex[texnum].displayRect[3]+tex[texnum].textOverhang);
      }
      else {
	tex[texnum].displayRect[1] = tex[texnum].displayRect[1]+tex[texnum].textOverhang;
      }
    }

    // add the offset to the display rect
    tex[texnum].displayRect[2] = tex[texnum].displayRect[2] + tex[texnum].displayRect[0];
    tex[texnum].displayRect[3] = tex[texnum].displayRect[3] + tex[texnum].displayRect[1];

    // check for flips, this is only necessary for text textures (i.e. ones created by mglText)
    // so that the global variables textHFlip and textVFlip control how the texture is blted
    if (tex[texnum].isText) {
      // look in global for flips    
      // first check whether coordinate system runs upward or downward
      if (deviceVDirection < 0) {
	if (verbose) mexPrintf("(mglBltTexture) Flipping vertically to compensate for device\n");
	// coordinate system flipped in y-direction; flip text by default
	double temp;
	temp = tex[texnum].displayRect[1];
	tex[texnum].displayRect[1] = tex[texnum].displayRect[3];
	tex[texnum].displayRect[3] = temp;
      }
    }
    // see if we need to do vflip
    if (tex[texnum].vFlip) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping font vertically\n");
      double temp;
      temp = tex[texnum].displayRect[1];
      tex[texnum].displayRect[1] = tex[texnum].displayRect[3];
      tex[texnum].displayRect[3] = temp;
    }
    // see if we need to do hflip
    if (tex[texnum].hFlip) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping font horizontally\n");
      double temp;
      temp = tex[texnum].displayRect[2];
      tex[texnum].displayRect[2] = tex[texnum].displayRect[0];
      tex[texnum].displayRect[0] = temp;
    }
    if (profile) {
      mexPrintf("Processing %f\n",getmsec()-startTime);
      startTime = getmsec();
    }
    if (verbose)
      mexPrintf("(mglBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",tex[texnum].displayRect[0],tex[texnum].displayRect[1],tex[texnum].displayRect[2],tex[texnum].displayRect[3]);

  }

  // set blending functions etc.
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glColor4f(1,1,1,1);
  
  // cycle through all the texture, and display them using gl functions
  for (texnum = 0; texnum < numTextures; texnum++) {

    // calculate the amount of shift we need to
    // move the axis (to center tex)
    double xshift = tex[texnum].displayRect[0]+(tex[texnum].displayRect[2]-tex[texnum].displayRect[0])/2;
    double yshift = tex[texnum].displayRect[1]+(tex[texnum].displayRect[3]-tex[texnum].displayRect[1])/2;
    tex[texnum].displayRect[3] -= yshift;
    tex[texnum].displayRect[2] -= xshift;
    tex[texnum].displayRect[1] -= yshift;
    tex[texnum].displayRect[0] -= xshift;

    // now shift and rotate the coordinate frame
    glMatrixMode( GL_MODELVIEW );    
    glPushMatrix();
    glTranslated(xshift,yshift,0);
    glRotated(tex[texnum].rotation,0,0,1);

    // GL_TEXTURE_RECTANGLE_EXT (standard 2D texture that can be a rectangle)
    if (tex[texnum].textureType==GL_TEXTURE_RECTANGLE_EXT) {
      if (verbose) mexPrintf("(mglBltTexture) GL_TEXTURE_RECTANGLE_EXT\n");
      // bind the texture we want to draw
      glEnable(GL_TEXTURE_RECTANGLE_EXT);
      glBindTexture(GL_TEXTURE_RECTANGLE_EXT, tex[texnum].textureNumber);

      // profile info
      if (profile) {
	mexPrintf("Enable %f\n",getmsec()-startTime);
	startTime = getmsec();
      }

      // and set the transformation
      glBegin(GL_QUADS);
      if (tex[texnum].textureAxes == YX) {
	// default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords (done in mglCreateTexture)
	glTexCoord2d(0.0, 0.0);
	glVertex3d(tex[texnum].displayRect[0],tex[texnum].displayRect[1], 0.0);
    
	glTexCoord2d(0.0, tex[texnum].imageHeight);
	glVertex3d(tex[texnum].displayRect[0], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(tex[texnum].imageWidth, tex[texnum].imageHeight);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(tex[texnum].imageWidth, 0.0);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[1], 0.0);
	glEnd();
      }  else if (tex[texnum].textureAxes==XY) {
	//  using reverse ordered coordinates does require swapping y and x in texture coords.
	glTexCoord2d(0.0, 0.0);
	glVertex3d(tex[texnum].displayRect[0],tex[texnum].displayRect[1], 0.0);
    
	glTexCoord2d(0.0, tex[texnum].imageWidth);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[1], 0.0);
	
	glTexCoord2d(tex[texnum].imageHeight,tex[texnum].imageWidth);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(tex[texnum].imageHeight, 0.0);
	glVertex3d(tex[texnum].displayRect[0], tex[texnum].displayRect[3], 0.0);    
      }

      glEnd();
      glDisable(GL_TEXTURE_RECTANGLE_EXT);
    }
    // On systems w/out GL_TEXTURE_RECTANGLE_EXT we use the GL_TEXTURE_2D
    else if (tex[texnum].textureType == GL_TEXTURE_2D) {
      if (verbose) mexPrintf("(mglBltTexture) GL_TEXTURE_2D\n");
      // bind the texture we want to draw
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, tex[texnum].textureNumber);

      // and set the transformation
      glBegin(GL_QUADS);
      if (tex[texnum].textureAxes==YX) {
	// default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords.
	glTexCoord2d(0.0, 0.0);
	glVertex3d(tex[texnum].displayRect[0],tex[texnum].displayRect[1], 0.0);
    
	glTexCoord2d(0.0, 1.0);
	glVertex3d(tex[texnum].displayRect[0], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(1.0, 1.0);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(1.0, 0.0);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[1], 0.0);
      } else if (tex[texnum].textureAxes==XY) {
	//  using reverse ordered coordinates does require swapping y and x in texture coords.
	glTexCoord2d(0.0, 0.0);
	glVertex3d(tex[texnum].displayRect[0],tex[texnum].displayRect[1], 0.0);
    
	glTexCoord2d(0.0, 1.0);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[1], 0.0);
    
	glTexCoord2d(1.0, 1.0);
	glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[3], 0.0);
    
	glTexCoord2d(1.0, 0.0);
	glVertex3d(tex[texnum].displayRect[0], tex[texnum].displayRect[3], 0.0);
    
      }
      glEnd();
      glDisable(GL_TEXTURE_2D);
    }
    // 1D texture
    else if (tex[texnum].textureType == GL_TEXTURE_1D) {
      if (verbose) mexPrintf("(mglBltTexture) GL_TEXTURE_1D\n");
      // bind the texture we want to draw
      glEnable(GL_TEXTURE_1D);
      glBindTexture(GL_TEXTURE_1D, tex[texnum].textureNumber);

      // and set the transformation
      glBegin(GL_QUADS);

      glTexCoord1d(0.0);
      glVertex3d(tex[texnum].displayRect[0],tex[texnum].displayRect[1], 0.0);
    
      glTexCoord1d(0.0);
      glVertex3d(tex[texnum].displayRect[0], tex[texnum].displayRect[3], 0.0);
    
      glTexCoord1d(1.0);
      glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[3], 0.0);
    
      glTexCoord1d(1.0);
      glVertex3d(tex[texnum].displayRect[2], tex[texnum].displayRect[1], 0.0);

      glEnd();
      glDisable(GL_TEXTURE_1D);
    }
    else {
      mexPrintf("(mglBltTexture) Unknown texture type: %i\n",tex[texnum].textureType);
    }
    glPopMatrix();
  }
  if (profile) {
    mexPrintf("Blt %f\n",getmsec()-startTime);
    mexPrintf("mglBltTexture (internal): %f\n",getmsec()-functionStartTime);
  }
  free(tex);
}


