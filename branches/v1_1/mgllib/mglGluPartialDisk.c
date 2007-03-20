#ifdef documentation
=========================================================================

     program: mglGluPartialDisk.c
          by: denis schluppeck (based on code by justin gardner & Jonas Larsson)
        date: 2007-03-19
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot ciruclar dots on an OpenGL screen opened with mglOpen
       usage: mglGluPartialDisk(x,y, isize, osize, startAngle, sweepAngle, color, nslices, nloops)
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
  double *x, *y, *isize, *osize, *startAngles, *sweepAngles, *color;
  int nslices, nloops;
  int i, n, ni, no, nStartAngles, nSweepAngles, ncolors;

  GLUquadricObj	  *diskQuadric;
  
  // check input arguments
  if ((nrhs < 6) || (nrhs>9)) {
    mexPrintf("(mglGluPartialDisk) Wrong number of arguments!\n\n"); 
    usageError("mglGluPartialDisk");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglGluPartialDisk) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglGluPartialDisk");
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  
  // get sizes
  ni = mxGetN(prhs[2])*mxGetM(prhs[2]);
  no = mxGetN(prhs[3])*mxGetM(prhs[3]);
  if ( (ni != no) || (ni != n) ) {
    mexPrintf("(mglGluPartialDisk) UHOH: Vector of sizes and x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglGluPartialDisk");
    return;
  }
  isize = (double*)mxGetPr(prhs[2]);
  osize = (double*)mxGetPr(prhs[3]);

    // get angles
  nStartAngles = mxGetN(prhs[4])*mxGetM(prhs[4]);
  nSweepAngles = mxGetN(prhs[5])*mxGetM(prhs[5]);
  if ( (nStartAngles != nSweepAngles) || (nStartAngles != n) ) {
    mexPrintf("(mglGluPartialDisk) UHOH: Vector of angles must match vector of of sizes\n\n");
    usageError("mglGluPartialDisk");
    return;
  }
  startAngles = (double*)mxGetPr(prhs[4]);
  sweepAngles = (double*)mxGetPr(prhs[5]);


  // set color of points
  /* if (nrhs < 7)
    // set default color
    glColor3f(1.0,1.0,1.0); 
  else {
    // get color
    if (mglGetColor(prhs[6],color) == 0) 
      glColor3f(1.0,1.0,1.0);
    else
      glColor3f(color[0],color[1],color[2]);
      }*/

  // set color of points
  if (nrhs < 7) {
    // set default color
    glColor3f(1.0,1.0,1.0); 
  } else {
    // get color
    ncolors = mxGetN(prhs[6])*mxGetM(prhs[6]);
    if ( (ncolors != 3) && ( (ncolors != 3*ni) || (mxGetM(prhs[6]) != 3)) ) {
      mexPrintf("%i, ni=%i\n", ncolors,ni);
      mexPrintf("(mglGluAnnulus) UHOH: Vector of colors needs to be 3x1 or 3xn\n\n");
      usageError("mglGluAnnulus");
      return;
    }
    color = (double*)mxGetPr(prhs[6]);
    if (ncolors == 3) {
      glColor3f(color[0],color[1],color[2]);
    }
  }
  
  // set default loops and slices (or get them)
  if (nrhs < 9) {
    nloops = 2; // default radial resolution
  } else {
    nloops = (int) *mxGetPr(prhs[8]);
  }
  if (nrhs < 8) {
    nslices = 8; // default angular resolution
  } else {
    nslices = (int) *mxGetPr(prhs[7]);
  }

  // make a disk
  diskQuadric=gluNewQuadric();
  
  // specify that we are changing the modelview matrix
  glMatrixMode(GL_MODELVIEW);

  // draw the disks
  for(i=0;i<n;i++){
    glPushMatrix();
    glTranslated(x[i],y[i], 0.0);
    if (ncolors > 3) {
      glColor3f(color[3*i+0],color[3*i+1],color[3*i+2]);
    }
    if (ni == 1 || no == 1)
      gluPartialDisk(diskQuadric, isize[0], osize[0], nslices, nloops, startAngles[0], sweepAngles[0]);
    else
      gluPartialDisk(diskQuadric, isize[i], osize[i],  nslices, nloops, startAngles[i], sweepAngles[i]);
    glPopMatrix();
  }
  
  // free space
  gluDeleteQuadric(diskQuadric);
}

