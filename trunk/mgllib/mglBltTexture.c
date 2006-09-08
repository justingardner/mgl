#ifdef documentation
=========================================================================

     program: mglBltTexture.c
          by: justin gardner with modifications by Jonas Larsson
        date: 04/09/06
     purpose: moves a texture on to the screen
              see Red book Chapter 9

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

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
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

  // get the texture number and imageWidth and imageHeight
  // check to make sure that the input strucutre properly contains these fields
  GLuint textureNumber;double imageWidth,imageHeight;
  char textureAxes[3];
  if (mxGetField(prhs[0],0,"textureNumber") != 0)
    textureNumber = (GLuint)*mxGetPr(mxGetField(prhs[0],0,"textureNumber"));
  else {
    mexPrintf("UHOH (mglBltTexture): TextureNumber field not defined in texture");
    return;
  }
  if (mxGetField(prhs[0],0,"imageWidth") != 0)
    imageWidth = (double)*mxGetPr(mxGetField(prhs[0],0,"imageWidth"));
  else {
    mexPrintf("UHOH (mglBltTexture): imageWidth field not defined in texture\n");
    return;
  }
  if (mxGetField(prhs[0],0,"imageHeight") != 0)
    imageHeight = (double)*mxGetPr(mxGetField(prhs[0],0,"imageHeight"));
  else {
    mexPrintf("UHOH (mglBltTexture): imageHeight field not defined in texture\n");
    return;
  }
  if (mxGetField(prhs[0],0,"textureAxes") != 0)
    mxGetString(mxGetField(prhs[0],0,"textureAxes"),textureAxes,3);
  else {
    mexPrintf("UHOH (mglBltTexture): textureAxes field not defined in texture\n");
    return;
  }

  // get the xPixelsToDevice and yPixelsToDevice making sure these are set properly
  double xPixelsToDevice = mglGetGlobalDouble("xPixelsToDevice");
  double yPixelsToDevice = mglGetGlobalDouble("yPixelsToDevice");
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
      displayRect[2] = imageWidth*xPixelsToDevice;
      displayRect[3] = imageHeight*yPixelsToDevice;
      break;
    case 4:
      memcpy(displayRect,inputRect,4*sizeof(double));
      break;
    default:
      mexPrintf("UHOH (mglBltTexture): Destination rectangle must be either [xmin ymin] or [xmin ymin xmax ymax]\n");
      return;
      break;
  }

  // verbose or not
  int verbose = (int)mglGetGlobalDouble("verbose");

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

  double textOverhang = 0;
  // now check to see if this is a text texture and
  // offset the vertical position if necessary to deal
  // with overhang characters like 'g'
  if (mxGetField(prhs[0],0,"textImageRect") != NULL) {
    if (mxGetN(mxGetField(prhs[0],0,"textImageRect")) == 4) {
      // get the second array element of textImageRect and this will
      // be used to modify the imageHeight for alignment
      textOverhang = (*(mxGetPr(mxGetField(prhs[0],0,"textImageRect"))+1))*yPixelsToDevice;
    }
    else {
      mexPrintf("(mglBltTexture) The input text texture has an invalid textImageRect\n");
      return;
    }
  } 

  // display text overhang
  if (verbose) mexPrintf("(mglBltTexture) Text overhang = %0.2f\n",textOverhang);

  // ok now fix horizontal alignment
  if (hAlignment == CENTER) {
    displayRect[0] = displayRect[0] - (displayRect[2]+textOverhang)/2;
  }
  else if (hAlignment == RIGHT) {
    if (mglGetGlobalDouble("deviceHDirection") > 0)
      displayRect[0] = displayRect[0] - (displayRect[2]+textOverhang);
  }
  else if (hAlignment == LEFT) {
    if (mglGetGlobalDouble("deviceHDirection") < 0)
      displayRect[0] = displayRect[0] + (displayRect[2]+textOverhang);
  }

  // ok now fix vertical alignment
  if (vAlignment == CENTER) {
    displayRect[1] = displayRect[1] - (displayRect[3]+textOverhang)/2;
    if (mglGetGlobalDouble("deviceVDirection") > 0) {
      // and adjust overhang
      displayRect[1] = displayRect[1]+textOverhang;
    }
  }
  else if (vAlignment == BOTTOM) {
    if (mglGetGlobalDouble("deviceVDirection") < 0) {
      displayRect[1] = displayRect[1] - (displayRect[3]+textOverhang);
      displayRect[1] = displayRect[1]-textOverhang;
    }
    else {
      displayRect[1] = displayRect[1]+2*textOverhang;
    }
  }
  else if (vAlignment == TOP) {
    if (mglGetGlobalDouble("deviceVDirection") > 0) {
      displayRect[1] = displayRect[1] - (displayRect[3]+textOverhang);
    }
    else {
      displayRect[1] = displayRect[1]+textOverhang;
    }
  }

  // add the offset to the display rect
  displayRect[2] = displayRect[2] + displayRect[0];
  displayRect[3] = displayRect[3] + displayRect[1];

  // check for flips, this is only necessary for text textures (i.e. ones created by mglText)
  // so that the global variables textHFlip and textVFlip control how the texture is blted
  if (mxGetField(prhs[0],0,"textImageRect") != NULL) {
    // look in global for flips    
    // first check whether coordinate system runs upward or downward
    if (mglGetGlobalDouble("deviceVDirection") < 0) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping vertically to compensate for device\n");
      // coordinate system flipped in y-direction; flip text by default
      double temp;
      temp = displayRect[1];
      displayRect[1] = displayRect[3];
      displayRect[3] = temp;
    }
  }
  // see if we need to do vflip
  if (mxGetField(prhs[0],0,"vFlip") != 0) {
    if (*mxGetPr(mxGetField(prhs[0],0,"vFlip"))) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping font vertically\n");
      double temp;
      temp = displayRect[1];
      displayRect[1] = displayRect[3];
      displayRect[3] = temp;
    }
  }
  // see if we need to do hflip
  if (mxGetField(prhs[0],0,"hFlip") != 0) {
    if (*mxGetPr(mxGetField(prhs[0],0,"hFlip"))) {
      if (verbose) mexPrintf("(mglBltTexture) Flipping font horizontally\n");
      double temp;
      temp = displayRect[2];
      displayRect[2] = displayRect[0];
      displayRect[0] = temp;
    }
  }

  if (verbose)
    mexPrintf("(mglBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",displayRect[0],displayRect[1],displayRect[2],displayRect[3]);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glColor4f(1,1,1,1);

#ifdef GL_TEXTURE_RECTANGLE_EXT
  // bind the texture we want to draw
  glEnable(GL_TEXTURE_RECTANGLE_EXT);
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureNumber);

  // and set the transformation
  glBegin(GL_QUADS);
  if (strncmp(textureAxes,"yx",2)==0) {
    // default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords (done in mglCreateTexture)
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, imageHeight);
    glVertex3f(displayRect[0], displayRect[3], 0.0);
    
    glTexCoord2f(imageWidth, imageHeight);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(imageWidth, 0.0);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
  }  else if (strncmp(textureAxes,"xy",2)==0) {
    //  using reverse ordered coordinates does require swapping y and x in texture coords.
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, imageWidth-1);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
    
    glTexCoord2f(imageHeight-1,imageWidth-1);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(imageHeight-1, 0.0);
    glVertex3f(displayRect[0], displayRect[3], 0.0);    
  }

  glEnd();
  glDisable(GL_TEXTURE_RECTANGLE_EXT);
#else
  // bind the texture we want to draw
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, textureNumber);

  // and set the transformation
  glBegin(GL_QUADS);
  if (strncmp(textureAxes,"yx",2)==0) {
    // default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords.
    glTexCoord2f(0.0, 0.0);
    glVertex3f(displayRect[0],displayRect[1], 0.0);
    
    glTexCoord2f(0.0, 1.0);
    glVertex3f(displayRect[0], displayRect[3], 0.0);
    
    glTexCoord2f(1.0, 1.0);
    glVertex3f(displayRect[2], displayRect[3], 0.0);
    
    glTexCoord2f(1.0, 0.0);
    glVertex3f(displayRect[2], displayRect[1], 0.0);
  } else if (strncmp(textureAxes,"xy",2)==0) {
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
}

