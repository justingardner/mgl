#ifdef documentation
=========================================================================

     program: mglBindTexture.c 
          by: justin gardner
        date: 2012/02/01
   copyright: (c) 2012 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: For use with a "liveBuffer" texture. This function
              allows you to rebind the texture to a new image and display
              more quickly
$Id:$
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
#define TEXTURE_DATATYPE GL_UNSIGNED_BYTE // Independent of endianness
int sub2ind( int row, int col, int height, int elsize ) {
  // return linear index corresponding to (row,col) into Matlab array
  return ( row*elsize + col*height*elsize );
}

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
  GLubyte *liveBuffer;
} textype;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  textype *tex;
  size_t numTextures = mxGetNumberOfElements(prhs[0]);
  int texnum,verbose,i,j,c=0;
  double *allParams;

  // check input arguments
  if (nrhs < 2) {
    // if not supported, call matlab help on the file
    const int ndims = 1;
    const int dims[] = {1};
    mxArray *callInput[] = {mxCreateString("mglBindTexture")};
    mexCallMATLAB(0,NULL,1,callInput,"help");
    return;
  }
  // variables for dimensions of second input
  const mwSize *dims = mxGetDimensions(prhs[1]); // rows cols
  const mwSize ndims = mxGetNumberOfDimensions(prhs[1]); 

  // allocate space for texture info
  tex = (textype*)malloc(numTextures*sizeof(textype));

  // get the input image data
  double *imageData = mxGetPr(prhs[1]);

  // get texture and live buffer pointer
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
      verbose = (int)allParams[12];
      tex[texnum].textureType = (GLenum)allParams[13];
      // get the liveBuffer field
      if (mxGetField(prhs[0],texnum,"liveBuffer") != 0)
	tex[texnum].liveBuffer = (GLubyte *)(unsigned long) *mxGetPr(mxGetField(prhs[0],texnum,"liveBuffer"));
      else
	tex[texnum].liveBuffer = 0;
    }
    else {
      mexPrintf("(mglBindTexture) Could not find allparams field\n");
      free(tex);
      return;
    }
    // check texture type
    if (tex[texnum].textureType == GL_TEXTURE_RECTANGLE_EXT) {
      // now determine how to change the texture, if user passed
      // in a uint8 buffer that is 4 x imageWidth x imageHeight
      if (mxIsUint8(prhs[1])) {
	if ((ndims==3) && (dims[0] == 4) && (dims[1] == tex[texnum].imageWidth) && (dims[2] == tex[texnum].imageHeight)) {
	  // rebind texture directly
	  glBindTexture(tex[texnum].textureType, tex[texnum].textureNumber);
	  glTexImage2D(tex[texnum].textureType,0,GL_RGBA,tex[texnum].imageWidth,tex[texnum].imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,(GLubyte*)imageData);
	  free(tex);
	  return;
	}
	else{
	  mexPrintf("(mglBindTexture) uint8 input should be rgba x %i x %i\n",tex[texnum].imageWidth,tex[texnum].imageHeight);
	  free(tex);
	  return;
	}
      }
      // check for live buffer
      if ((unsigned long)tex[texnum].liveBuffer==0){
	mexPrintf("(mglBindTexture) Texture must be create with liveBuffer set to true for use with this function\n");
	free(tex);
	return;
      }
      // in a scalar, then set the alpha channel to that value
      if ((ndims==1) || ((ndims==2) && (dims[0] == 1) && (dims[1] == 1))){
	for(i = 0; i < tex[texnum].imageHeight; i++) {
	  for(j = 0; j < tex[texnum].imageWidth;j++,c+=BYTEDEPTH) {
	    tex[texnum].liveBuffer[c+3] = (GLubyte)*imageData;
	  }
	}
      }
      // passed in a full imageWidth x imageHeight x 4
      else if ((ndims==3) && (dims[0] == tex[texnum].imageWidth) && (dims[1] == tex[texnum].imageHeight) && (dims[2] == 4)) {
	// FIX FIX FIX - This assumes axis are xy
	int widthDepth = tex[texnum].imageWidth*BYTEDEPTH;
        int imageSize = tex[texnum].imageWidth*tex[texnum].imageHeight;
        int imageSize2 = imageSize*2;
        int imageSize3 = imageSize*3;
        
        for (j = 0; j < tex[texnum].imageWidth;j++, c+=BYTEDEPTH) {
            int colStart = j*tex[texnum].imageHeight;
            
            for (i = 0; i < tex[texnum].imageHeight; i++) {
                int ind = i + colStart;
                int outind = i*widthDepth;

                tex[texnum].liveBuffer[c+outind] = (GLubyte)imageData[ind];
                tex[texnum].liveBuffer[c+outind+1] = (GLubyte)imageData[ind+imageSize];
                tex[texnum].liveBuffer[c+outind+2] = (GLubyte)imageData[ind+imageSize2];
                tex[texnum].liveBuffer[c+outind+3] = (GLubyte)imageData[ind+imageSize3];
            }
        }
      }
      // passed in a full imageWidth x imageHeight - this means to replace alpha buffer
      else if ((ndims==2) && (dims[0] == tex[texnum].imageWidth) && (dims[1] == tex[texnum].imageHeight)) {
	for(i = 0; i < tex[texnum].imageHeight; i++) {
	  for(j = 0; j < tex[texnum].imageWidth;j++,c+=BYTEDEPTH) {
	    tex[texnum].liveBuffer[c+3] = (GLubyte)imageData[sub2ind( i, j, tex[texnum].imageWidth, 1 )];
	  }
	}
      }
      else {
	mexPrintf("(mglBindTexture) Unrecogonized format for texture %i\n",ndims);
	free(tex);
	return;
      }
      // rebind texture
      glBindTexture(tex[texnum].textureType, tex[texnum].textureNumber);
      glTexImage2D(tex[texnum].textureType,0,GL_RGBA,tex[texnum].imageWidth,tex[texnum].imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,tex[texnum].liveBuffer);
    }
    else {
      mexPrintf("(mglBindTexture) Currently only supports 4D textures\n");
      free(tex);
      return;
    }
  }

  // free textures
  free(tex);
}

