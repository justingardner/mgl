#ifdef documentation
=========================================================================

     program: mglPoints3.c
          by: justin gardner & Jonas Larsson
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot 2D points on an OpenGL screen opened with mglOpen
       usage: mglPoints3(x,y,z,size,color)

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
  double *x, *y, *z, color[4];
  int i, n;

  // check input arguments
  if ((nrhs < 2) || (nrhs>5)) {
    usageError("mglPoints3");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglPoints3) Number of x points (%i) must match with y (%i)\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  z = (double*)mxGetPr(prhs[2]);

  // set point size if supported, otherwise use draw rect function to draw points
  double pointSize=2;
  if (nrhs >= 4) {
    pointSize=*mxGetPr(prhs[3]);
  }
  GLint range[2];
  glGetIntegerv(GL_POINT_SIZE_RANGE,range);
  bool useRects=(range[1]<pointSize);
  
  if (!useRects)
    glPointSize(pointSize);

  // set color of points
  if (nrhs < 5)
    // set default color
    glColor3f(1.0,1.0,1.0); 
  else {
    // get color
    if (mglGetColor(prhs[3],color) == 0) 
      glColor3f(1.0,1.0,1.0);
    else
      glColor3f(color[0],color[1],color[2]);
  }

  // draw the points
  if (useRects) {
    // convert pointSize to pixels
    if (!(mglGetGlobalDouble("screenCoordinates")>0)) {
      pointSize=pointSize*mglGetGlobalDouble("xPixelsToDevice");
    }
    pointSize=pointSize/2;
    glBegin(GL_QUADS);
    for(i=0;i<n;i++){      
      glVertex3d(x[i]-pointSize, y[i]-pointSize, z[i]);
      glVertex3d(x[i]-pointSize, y[i]+pointSize, z[i]);
      glVertex3d(x[i]+pointSize, y[i]+pointSize, z[i]);
      glVertex3d(x[i]+pointSize, y[i]-pointSize, z[i]);
    }
  } else {
    glBegin(GL_POINTS);
    for(i=0;i<n;i++){
      glVertex3d(x[i],y[i],z[i]);
    }
    glEnd();
  }

}

