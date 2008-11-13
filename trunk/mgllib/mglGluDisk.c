#ifdef documentation
=========================================================================

     program: mglGluDisk.c
          by: denis schluppeck (based on code by justin gardner & Jonas Larsson)
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot ciruclar dots on an OpenGL screen opened with mglOpen
       usage: mglGluDisk(x,y,size,color)
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
  int nslices, nloops;
  int i, n;

  GLUquadricObj	  *diskQuadric;
  
  // check input arguments
  if ((nrhs < 3) || (nrhs>6)) {
    mexPrintf("(mglGluDisk) Wrong number of arguments!\n\n"); 
    usageError("mglGluDisk");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglGluDisk) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglGluDisk");
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  
  // get size
  size = (double*)mxGetPr(prhs[2]);

  // set color of points
  if (nrhs < 4)
    // set default color
    glColor3f(1.0,1.0,1.0); 
  else {
    // get color
    if (mglGetColor(prhs[3],color) == 0) 
      glColor3f(1.0,1.0,1.0);
    else
      glColor3f(color[0],color[1],color[2]);
  }
  
  // set default loops and slices (or get them)
  if (nrhs < 6) {
    nloops = 2; // default radial resolution
  } else {
    nloops = (int) *mxGetPr(prhs[5]);
  }
  if (nrhs < 5) {
    nslices = 8; // default angular resolution
  } else {
    nslices = (int) *mxGetPr(prhs[4]);
  }

  // make a disk
  diskQuadric=gluNewQuadric();
  
  // specify that we are changing the modelview matrix
  glMatrixMode(GL_MODELVIEW);

  // draw the disks
  for(i=0;i<n;i++){
    glPushMatrix();
    glTranslated(x[i],y[i], 0.0);
    if ( (mxGetN(prhs[2])*mxGetM(prhs[2]) ) != (mxGetN(prhs[0])*mxGetM(prhs[0]))) {
      // then need to use 1 size
      gluDisk(diskQuadric, 0.0, size[0], nslices, nloops);
    } else {
      // else have many sizes... so can use information
      gluDisk(diskQuadric, 0.0, size[i], nslices, nloops);
      // mexPrintf("%.2f\n",size[i]); // debug
    }
    glPopMatrix();
  }
  
  // free space
  gluDeleteQuadric(diskQuadric);
}

