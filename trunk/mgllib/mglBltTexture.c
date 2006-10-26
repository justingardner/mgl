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
  double imageWidth;
  double imageHeight;
  int textureAxes;
  int vFlip;
  int hFlip;
  double textOverhang;
  int isText;
} textype;
//////////////////////////////
//   function declartions   //
//////////////////////////////
double getmsec()
{ 
#ifdef __linux__
  struct timeval tp;
  struct timezone tz;

  gettimeofday( &tp, &tz );
  double doubleValue = (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;
  doubleValue = doubleValue * 1000;
#endif
#ifdef __APPLE__
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)currentTime.hi; 
  double lowerHalf = (double)currentTime.lo; 
  
  doubleValue = (upperHalf * twoPower32) + lowerHalf; 
#endif
  return(doubleValue/1000); 
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
    mexPrintf("(mgl) UHOH: No window is open\n");
    return;
  }

  // check input arguments
  if (nrhs < 2) {
    // if not supported, call matlab help on the file
    usageError("mglBltTexture");
    return;
  }

  // declarae some variables
  int numTextures = mxGetNumberOfElements(prhs[0]);
  char textureAxesString[3];
  double xPixelsToDevice, yPixelsToDevice,deviceHDirection,deviceVDirection;
  int verbose;
  double startTime;
  textype *tex;
  // allocate space for texture info
  tex = malloc(numTextures*sizeof(textype));
  double *allParams;

  if (profile) startTime = getmsec();

  int texnum;
  for (texnum = 0; texnum < numTextures; texnum++) {
    if (mxGetField(prhs[0],0,"allParams") != 0) {
      // grab all the info from the allParams field
      allParams = mxGetPr(mxGetField(prhs[0],texnum,"allParams"));
      tex[0].textureNumber = (GLuint)allParams[0];
      tex[0].imageWidth = allParams[1];
      tex[0].imageHeight = allParams[2];
      tex[0].textureAxes = allParams[3];
      tex[0].hFlip = allParams[4];
      tex[0].vFlip = allParams[5];
      tex[0].textOverhang = allParams[6];
      tex[0].isText = allParams[7];
      xPixelsToDevice = allParams[8];
      yPixelsToDevice = allParams[9];
      deviceHDirection = allParams[10];
      deviceVDirection = allParams[11];
      verbose = (int)allParams[12];
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
	mexPrintf("UHOH (mglBltTexture): TextureNumber field not defined in texture");
	return;
      }
      if (mxGetField(prhs[0],texnum,"imageWidth") != 0)
	tex[texnum].imageWidth = (double)*mxGetPr(mxGetField(prhs[0],texnum,"imageWidth"));
      else {
	mexPrintf("UHOH (mglBltTexture): imageWidth field not defined in texture\n");
	return;
      }
      if (mxGetField(prhs[0],texnum,"imageHeight") != 0)
	tex[texnum].imageHeight = (double)*mxGetPr(mxGetField(prhs[0],texnum,"imageHeight"));
      else {
	mexPrintf("UHOH (mglBltTexture): imageHeight field not defined in texture\n");
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
	mexPrintf("UHOH (mglBltTexture): textureAxes field not defined in texture\n");
	return;
      }
      if (mxGetField(prhs[0],texnum,"hFlip") != 0)
	tex[texnum].hFlip = (double)*mxGetPr(mxGetField(prhs[0],texnum,"hFlip"));
      else {
	mexPrintf("UHOH (mglBltTexture): hFlip field not defined in texture\n");
	return;
      }
      if (mxGetField(prhs[0],texnum,"vFlip") != 0)
	tex[texnum].vFlip = (double)*mxGetPr(mxGetField(prhs[0],texnum,"vFlip"));
      else {
	mexPrintf("UHOH (mglBltTexture): vFlip field not defined in texture\n");
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
	  return;
	}
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

  // now get destination rectangle
  double *inputRect,displayRect[4];
  if ((inputRect = (double *)mxGetPr(prhs[1])) == NULL) {
    mexPrintf("UHOH (mglBltTexture): Empty destination rect\n");
    return;
  }

  // check the length of position
  switch (mxGetN(prhs[1])) {
    case 2:
      memcpy(displayRect,inputRect,2*sizeof(double));
      displayRect[2] = tex[0].imageWidth*xPixelsToDevice;
      displayRect[3] = tex[0].imageHeight*yPixelsToDevice;
      break;
    case 4:
      memcpy(displayRect,inputRect,4*sizeof(double));
      break;
    default:
      mexPrintf("UHOH (mglBltTexture): Destination rectangle must be either [xmin ymin] or [xmin ymin xmax ymax]\n");
      return;
      break;
  }

  // declare some variables for dealing with alignment
  int hAlignment, vAlignment;
  // check the alginment options
  if (nrhs < 3) {
    hAlignment = DEFAULT_H_ALIGNMENT;
  }
  else {
    hAlignment = *mxGetPr(prhs[2]);
    if ((hAlignment != CENTER) && (hAlignment != LEFT) && (hAlignment != RIGHT)) {
      mexPrintf("(mglBltTexture) Unknown hAlignment %i\n",*mxGetPr(prhs[2]));
      return;
    }
  }
  if (verbose) mexPrintf("hAlignment is %s\n",(hAlignment == CENTER)?"center":((hAlignment == LEFT)?"left":"right"));

  // check the alginment options for vertical
  if (nrhs < 4) {
    vAlignment = DEFAULT_V_ALIGNMENT;
  }
  else {
    vAlignment = *mxGetPr(prhs[3]);
    if ((vAlignment != CENTER) && (vAlignment != TOP) && (vAlignment != BOTTOM)) {
      mexPrintf("(mglBltTexture) Unknown vAlignment %i\n",*mxGetPr(prhs[3]));
      return;
    }
  }
  if (verbose) mexPrintf("vAlignment is %s\n",(vAlignment == CENTER)?"center":((vAlignment == TOP)?"top":"bottom"));

  // display text overhang
  if (verbose) mexPrintf("(mglBltTexture) Text overhang = %0.2f\n",tex[0].textOverhang);

  // ok now fix horizontal alignment
  if (hAlignment == CENTER) {
    displayRect[0] = displayRect[0] - (displayRect[2]+tex[0].textOverhang)/2;
  }
  else if (hAlignment == RIGHT) {
    if (deviceHDirection > 0)
      displayRect[0] = displayRect[0] - (displayRect[2]+tex[0].textOverhang);
  }
  else if (hAlignment == LEFT) {
    if (deviceHDirection < 0)
      displayRect[0] = displayRect[0] + (displayRect[2]+tex[0].textOverhang);
  }

  // ok now fix vertical alignment
  if (vAlignment == CENTER) {
    displayRect[1] = displayRect[1] - (displayRect[3]+tex[0].textOverhang)/2;
    if (deviceVDirection > 0) {
      // and adjust overhang
      displayRect[1] = displayRect[1]+tex[0].textOverhang;
    }
  }
  else if (vAlignment == BOTTOM) {
    if (deviceVDirection < 0) {
      displayRect[1] = displayRect[1] - (displayRect[3]+tex[0].textOverhang);
      displayRect[1] = displayRect[1]-tex[0].textOverhang;
    }
    else {
      displayRect[1] = displayRect[1]+2*tex[0].textOverhang;
    }
  }
  else if (vAlignment == TOP) {
    if (deviceVDirection > 0) {
      displayRect[1] = displayRect[1] - (displayRect[3]+tex[0].textOverhang);
    }
    else {
      displayRect[1] = displayRect[1]+tex[0].textOverhang;
    }
  }

  // add the offset to the display rect
  displayRect[2] = displayRect[2] + displayRect[0];
  displayRect[3] = displayRect[3] + displayRect[1];

  // check for flips, this is only necessary for text textures (i.e. ones created by mglText)
  // so that the global variables textHFlip and textVFlip control how the texture is blted
  if (tex[0].isText) {
    // look in global for flips    
    // first check whether coordinate system runs upward or downward
    if (deviceVDirection < 0) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping vertically to compensate for device\n");
      // coordinate system flipped in y-direction; flip text by default
      double temp;
      temp = displayRect[1];
      displayRect[1] = displayRect[3];
      displayRect[3] = temp;
    }
  }
  // see if we need to do vflip
  if (tex[0].vFlip) {
    if (verbose) mexPrintf("(mglBltTexture) Flipping font vertically\n");
    double temp;
    temp = displayRect[1];
    displayRect[1] = displayRect[3];
    displayRect[3] = temp;
  }
  // see if we need to do hflip
  if (tex[0].hFlip) {
    if (verbose) mexPrintf("(mglBltTexture) Flipping font horizontally\n");
    double temp;
    temp = displayRect[2];
    displayRect[2] = displayRect[0];
    displayRect[0] = temp;
  }
  if (profile) {
    mexPrintf("Processing %f\n",getmsec()-startTime);
    startTime = getmsec();
  }

  if (verbose)
    mexPrintf("(mglBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",displayRect[0],displayRect[1],displayRect[2],displayRect[3]);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glColor4f(1,1,1,1);

#ifdef GL_TEXTURE_RECTANGLE_EXT
  // bind the texture we want to draw
  glEnable(GL_TEXTURE_RECTANGLE_EXT);
  if (profile) {
    mexPrintf("Enable %f\n",getmsec()-startTime);
    startTime = getmsec();
  }
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, tex[0].textureNumber);

  // and set the transformation
  glBegin(GL_QUADS);
  if (tex[0].textureAxes == YX) {
    // default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords (done in mglCreateTexture)
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, tex[0].imageHeight-1);
    glVertex3f(displayRect[0], displayRect[3], 0.0);
    
    glTexCoord2f(tex[0].imageWidth-1, tex[0].imageHeight-1);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(tex[0].imageWidth-1, 0.0);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
    glEnd();
#if 0
    float xoffset;
    for (xoffset = -12;xoffset <=12;xoffset++) {
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(xoffset+displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, tex[0].imageHeight-1);
    glVertex3f(xoffset+displayRect[0], displayRect[3], 0.0);
    
    glTexCoord2f(tex[0].imageWidth-1, tex[0].imageHeight-1);
    glVertex3f(xoffset+displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(tex[0].imageWidth-1, 0.0);
    glVertex3f(xoffset+displayRect[2], displayRect[1], 0.0);
    }
#endif

  }  else if (tex[0].textureAxes==XY) {
    //  using reverse ordered coordinates does require swapping y and x in texture coords.
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, tex[0].imageWidth-1);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
    
    glTexCoord2f(tex[0].imageHeight-1,tex[0].imageWidth-1);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(tex[0].imageHeight-1, 0.0);
    glVertex3f(displayRect[0], displayRect[3], 0.0);    
  }

  glEnd();
  glDisable(GL_TEXTURE_RECTANGLE_EXT);
#else
  // bind the texture we want to draw
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[0].textureNumber);

  // and set the transformation
  glBegin(GL_QUADS);
  if (strncmp(tex[0].textureAxes,"yx",2)==0) {
    // default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords.
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, 1.0);
    glVertex3f(displayRect[0], displayRect[3], 0.0);
    
    glTexCoord2f(1.0, 1.0);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(1.0, 0.0);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
  } else if (strncmp(tex[0].textureAxes,"xy",2)==0) {
    //  using reverse ordered coordinates does require swapping y and x in texture coords.
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, 1.0);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
    
    glTexCoord2f(1.0, 1.0);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(1.0, 0.0);
    glVertex3f(displayRect[0], displayRect[3], 0.0);
    
  }
  glEnd();
#endif
  if (profile) {
    mexPrintf("Blt %f\n",getmsec()-startTime);
    mexPrintf("mglBltTexture (internal): %f\n",getmsec()-functionStartTime);
  }
 
}


