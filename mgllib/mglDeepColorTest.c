#ifdef documentation
=========================================================================

     program: mglDeepColorTest
          by: justin gardner
        date: 06/01/2018
   copyright: (c) 2018 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: Tries to make a high color depth texture and display it
              called by the mglTestGammaSet program

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

#define RGBATYPE GLubyte
       //#define RGBATYPE GLushort

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // declare some variables
  GLenum textureType;
  int i,j;

  // check for open window
  if (!mglIsWindowOpen()) {
    mexPrintf("(mglPrivateCreateTexture) No window is open\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
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
  const int *dims = mxGetDimensions(prhs[0]); // rows cols
  const mwSize ndims = mxGetNumberOfDimensions(prhs[0]); 
  const size_t n = mxGetNumberOfElements(prhs[0]);
  int imageWidth, imageHeight;

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

  //  data in which we are going to directly copy.
  RGBATYPE *imageFormatted;
  // allocate temporary memory to make copy into
  imageFormatted = (RGBATYPE*)malloc(imageWidth*imageHeight*sizeof(RGBATYPE)*BYTEDEPTH);
  // display size 
  mexPrintf("(mglPrivateCreateTexture) Testing with %i bytes per channel\n",(int)sizeof(RGBATYPE));

  // get the input image data
  double *imageData = mxGetPr(prhs[0]);
    
  int imageSize = imageWidth*imageHeight;
  int imageSize2 = imageSize*2;
  int imageSize3 = imageSize*3;
  int widthDepth = imageWidth*BYTEDEPTH;
  int c=0;
        
  for (j = 0; j < imageWidth;j++, c+=BYTEDEPTH) {
    int colStart = j*imageHeight;
    
    for (i = 0; i < imageHeight; i++) {
      int ind = i + colStart;
      int outind = i*widthDepth;
      
      imageFormatted[c+outind] = (RGBATYPE)(imageData[ind]);
      imageFormatted[c+outind+1] = (RGBATYPE)(imageData[ind+imageSize]);
      imageFormatted[c+outind+2] = (RGBATYPE)(imageData[ind+imageSize2]);
      imageFormatted[c+outind+3] = (RGBATYPE)(imageData[ind+imageSize3]);
    }
  }
  
  GLuint textureNumber;
  // get a unique texture identifier name
  glGenTextures(1, &textureNumber);

  // set texture type
  textureType = GL_TEXTURE_RECTANGLE_EXT;
  glBindTexture(textureType, textureNumber);

  // print out what is in the buffer
  int loc = 0;
  for (i=0;i<imageWidth;i++) {
    for (j=0;j<imageHeight;j++) {
      loc = i*imageHeight*4+j*4;
      mexPrintf("[%i %i %i %i] ",(int)imageFormatted[loc],(int)imageFormatted[loc+1],(int)imageFormatted[loc+2],(int)imageFormatted[loc+3]);
    }
    mexPrintf("\n");
  }

  // See here:  https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml
  // create the texture
  //  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA16,imageWidth,imageHeight,0,GL_RGBA,GL_UNSIGNED_SHORT,imageFormatted);
  //  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA16,imageWidth,imageHeight,0,GL_RGBA,GL_UNSIGNED_SHORT,imageFormatted);

  // This is standard version - which should be working - set the
  // RGBATYPE to GLubyte at the top if you want to test
  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,imageWidth,imageHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,imageFormatted);

  // bind the texture
  glEnable(GL_TEXTURE_RECTANGLE_EXT);
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureNumber);

  // get pixels to device
  double xPixelsToDevice = mglGetGlobalDouble("xPixelsToDevice");
  double yPixelsToDevice = mglGetGlobalDouble("yPixelsToDevice");

  double displayRect[4];
  displayRect[0] = 0;
  displayRect[1] = 0;
  displayRect[2] = imageWidth*xPixelsToDevice;
  displayRect[3] = imageHeight*yPixelsToDevice;

  // and set the transformation
  glBegin(GL_QUADS);

  glTexCoord2d(0.0, 0.0);
  glVertex3d(displayRect[0],displayRect[1], 0.0);
    
  glTexCoord2d(0.0, imageHeight);
  glVertex3d(displayRect[0], displayRect[3], 0.0);
    
  glTexCoord2d(imageWidth, imageHeight);
  glVertex3d(displayRect[2], displayRect[3], 0.0);
    
  glTexCoord2d(imageWidth, 0.0);
  glVertex3d(displayRect[2], displayRect[1], 0.0);
  glEnd();
  
  glDisable(GL_TEXTURE_RECTANGLE_EXT);

  // free temporary image storage
  free(imageFormatted);

}

