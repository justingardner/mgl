#ifdef documentation
=========================================================================

     program: mglFrameGrab.c
          by: justin gardner
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to delete a texture
       usage: mglDeleteTexture(texnum)

$Id$
=========================================================================
#endif


/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int width, height,x,y,c;

  // check to see if MGL is open
  if (!mglIsWindowOpen()) {
    mexPrintf("(mglFrameGrab) No MGL window is open\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  // no arguments, then default to full frame grab
  if (nrhs == 0) {
    x = 0;
    y = 0;
    width = mglGetGlobalDouble("screenWidth");
    height = mglGetGlobalDouble("screenHeight");
  }
  else if (nrhs == 1) {
    switch (mxGetN(prhs[0])) {
      // if the argument is two numbers, then set x and y position
      case 2:
        x = *(double*)mxGetPr(prhs[0]);
        y = *(((double*)mxGetPr(prhs[0]))+1);
        width = mglGetGlobalDouble("screenWidth")-x;
        height = mglGetGlobalDouble("screenHeight")-y;
        break;
      // if the argument is four numbers, then set x and y and width and height
      case 4:
        x = *(double*)mxGetPr(prhs[0]);
        y = *(((double*)mxGetPr(prhs[0]))+1);
        width = *(((double*)mxGetPr(prhs[0]))+2);
        height = *(((double*)mxGetPr(prhs[0]))+3);
        break;
     default:
      usageError("mglFrameGrab");
      return;
    }
  }
  else {
    usageError("mglFrameGrab");
    return;
  }
  
  // create a C array for getting stuff from glReadPizels
  GLfloat *frame;
  frame = (GLfloat*)malloc(width*height*3*sizeof(GLfloat));
  if (!frame) {
    mexPrintf("(mglFrameGrab) Could not allocate memory");
    return;
  }

  // create the matlab array for returning data
  mwSize dims[3];
  dims[0] = (mwSize)width;dims[1] = (mwSize)height;dims[2] = 3;
  plhs[0] = mxCreateNumericArray(3,dims,mxSINGLE_CLASS,mxREAL);
  GLfloat *outPtr = (GLfloat*)mxGetPr(plhs[0]);

  // get the pixels
  glReadPixels(x,y,width,height,GL_RGB,GL_FLOAT,frame);

  // now write the date in the correct format to the outptr
  for(x=0;x<width;x++)
    for(y=0;y<height;y++)
      for(c=0;c<3;c++)
	outPtr[c*width*height+(height-y-1)*width+x] = frame[y*width*3+x*3+c];

  // free the temporary memory and we are done
  free(frame);
}

