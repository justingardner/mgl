#ifdef documentation
=========================================================================

     program: mglPrivateDeleteTexture.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to delete a texture
       usage: mglDeleteTexture(texnum)

$Id: mglPrivateDeleteTexture.c 286 2008-03-03 03:21:15Z justin $
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#define BYTEDEPTH 4
#define TEXTURE_DATATYPE GL_UNSIGNED_BYTE // Independent of endianness
#define WIDTH 600
#define HEIGHT 400

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  mexEvalString("mglOpen;\n");
  mexEvalString("mglVisualAngleCoordinates(57,[16 12]);\n");

  // create a texture using mglCreateTexture
  mxArray *callInput[3],*callOutput[2];
  mwSize dims[3] = {WIDTH,HEIGHT, BYTEDEPTH};
  callInput[0] = mxCreateNumericArray(3,dims,mxDOUBLE_CLASS,mxREAL);
  callInput[1] = mxCreateString("xy");
  callInput[2] = mxCreateDoubleMatrix(1,1,mxREAL);
  double *arg = (double*)mxGetPr(callInput[2]);
  *arg = 1;
  mexCallMATLAB(1,callOutput,3,callInput,"mglCreateTexture");            

  // clean up
  mxDestroyArray(callInput[0]);
  mxDestroyArray(callInput[1]);
  mxDestroyArray(callInput[2]);

  // get the pointer to the "liveBuffer" which we can use to modify the texture on the fly
  GLubyte *buf = (GLubyte*)(unsigned long)*mxGetPr(mxGetField(callOutput[0],0,"liveBuffer"));
  GLenum textureType = (GLenum)*mxGetPr(mxGetField(callOutput[0],0,"textureType"));
  GLuint textureNumber = (GLuint)*mxGetPr(mxGetField(callOutput[0],0,"textureNumber"));
 
  // display the texture (should be black)
  mexEvalString("mglClearScreen;\n");
  callOutput[1] = mxCreateDoubleMatrix(1,4,mxREAL);
  double *bltPos = (double*)mxGetPr(callOutput[1]);
  bltPos[0] = 0;
  bltPos[1] = 0;
  bltPos[2] = 5;
  bltPos[3] = 5;
  mexCallMATLAB(0,NULL,2,callOutput,"mglBltTexture");            

  mexEvalString("mglFlush;\n");
  mexEvalString("mglWaitSecs(0.5);");

  int i,j,c=0,k;
  for(k = 0;k<120;k++) {
    c = 0;
    // now put noise int the buffer
    for(i = 0;i<WIDTH;i++)
      for(j=0;j<HEIGHT;j++,c+=4){
	buf[c] = (GLubyte)(255.0*rand()/RAND_MAX);
	buf[c+1] = (GLubyte)(255.0*rand()/RAND_MAX);
	buf[c+2] = (GLubyte)(255.0*rand()/RAND_MAX);
	buf[c+3] = 255;
      }
    // rebind
    glBindTexture(textureType, textureNumber);
    glTexImage2D(textureType,0,GL_RGBA,HEIGHT,WIDTH,0,GL_RGBA,TEXTURE_DATATYPE,buf);

    // and redisplay
    mexEvalString("mglClearScreen");
    mexCallMATLAB(0,NULL,2,callOutput,"mglBltTexture");
    mexEvalString("mglFlush;\n");
  }
  mexEvalString("mglClose;");

}

