#ifdef documentation
=========================================================================

     program: mglFillOval.c
          by: denis schluppeck (based on code by justin gardner & Jonas Larsson)
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot an oval on an OpenGL screen opened with mglOpen
       usage: mglFillOval(x,y,size,color)
              needs glu.h

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
  double *x, *y, *size, color[4];
  size_t n, nsize;
  int i;
  int nslices = 60; // default angular resolution
  int nloops = 10; // default radial resolution

  GLUquadricObj	  *diskQuadric;
  
  // check input arguments
  if ((nrhs < 3) || (nrhs>4)) {
    mexPrintf("(mglFillOval) Wrong number of arguments!\n\n");
    usageError("mglFillOval");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglFillOval) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
     usageError("mglFillOval");
     return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  
  // get size
  nsize = mxGetN(prhs[2])*mxGetM(prhs[2]);
  if (nsize != 2 ) {
    mexPrintf("(mglFillOval) UHOH: size needs to have x and y dims\n");
    return;
  }
  size = (double*)mxGetPr(prhs[2]);

  // set color of points
  if (nrhs < 4)
    // set default color
    glColor3d(1.0,1.0,1.0); 
  else {
    // get color
    if (mglGetColor(prhs[3],color) == 0) 
      glColor3d(1.0,1.0,1.0);
    else
      glColor3d(color[0],color[1],color[2]);
  }

  // make a disk
  diskQuadric=gluNewQuadric();

  // specify that we are changing the modelview matrix
  glMatrixMode(GL_MODELVIEW);

  // draw the disks
  for(i=0;i<n;i++){
    glPushMatrix();
    glTranslated(x[i],y[i],0.0);
    glScaled(size[0]/2, size[1]/2, 1.0 ); // radius vs diameter
    gluDisk(diskQuadric, 0.0, 1, nslices, nloops);
    glPopMatrix();
  }
  
  // free space
  gluDeleteQuadric(diskQuadric);
}

