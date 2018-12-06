#ifdef documentation
=========================================================================

     program: mglPoints2c.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06, 09/07/18
   copyright: (c) 2006 Justin Gardner, Jonas Larsson, Dan Birman (GPL see mgl/COPYING)
     purpose: mex function to plot 2D points on an OpenGL screen opened with mglOpen
              allows every dot to have a different color, useful for overlapping
              dot patches
       usage: mglPoints2c(x,y,size,color)

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
  //  CGLContextObj contextObj = CGLGetCurrentContext();
  double *x, *y, *r, *g, *b;//, color[4];
  int i, n;

  // check input arguments
  if ((nrhs < 2) || (nrhs>6)) {
    usageError("mglPoints2");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglPoints2) UHOH: Number of x points (%i) must match with y (%i)\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  r = (double*)mxGetPr(prhs[3]);
  g = (double*)mxGetPr(prhs[4]);
  b = (double*)mxGetPr(prhs[5]);
  
  // set point size if supported, otherwise use draw rect function to draw points
  double pointSize=2;
  if (nrhs >= 3) {
    pointSize=*mxGetPr(prhs[2]);
  }
  GLint range[2];
  glGetIntegerv(GL_POINT_SIZE_RANGE,range);
  bool useRects=(range[1]<pointSize);
  
  if (!useRects)
    glPointSize(pointSize);

  // draw the points
  if (useRects) {
    // convert pointSize to pixels
    if (!(mglGetGlobalDouble("screenCoordinates")>0)) {
      pointSize=pointSize*mglGetGlobalDouble("xPixelsToDevice");
    }
    pointSize=pointSize/2;
    for(i=0;i<n;i++){
      glColor3f(r[i],g[i],b[i]);
      glRectd(x[i]-pointSize,y[i]-pointSize, x[i]+pointSize,y[i]+pointSize);
    }
  } else {
    glBegin(GL_POINTS);
    for(i=0;i<n;i++){
      glColor3f(r[i],g[i],b[i]);
      glVertex2d(x[i],y[i]);
    }
    glEnd();
  }

}