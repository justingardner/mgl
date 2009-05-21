#ifdef documentation
=========================================================================

     program: mglGluAnnulus.c
          by: denis schluppeck (based on code by justin gardner & Jonas Larsson)
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot ciruclar dots on an OpenGL screen opened with mglOpen
       usage: mglGluAnnulus(x,y,isize, osize,color, nslices, nloops)
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
  double *x, *y, *isize, *osize, *color;
  int nslices, nloops;
  int i, n, ni, no, ncolors;

  GLUquadricObj	  *diskQuadric;
  
  // check input arguments
  if ((nrhs < 4) || (nrhs>7)) {
    mexPrintf("(mglGluAnnulus) Wrong number of arguments!\n\n"); 
    usageError("mglGluAnnulus");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglGluAnnulus) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglGluAnnulus");
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  
  // get sizes
  ni = mxGetN(prhs[2])*mxGetM(prhs[2]);
  no = mxGetN(prhs[3])*mxGetM(prhs[3]);
  if ( (ni != no) || (ni != n) ) {
    mexPrintf("(mglGluAnnulus) UHOH: Vector of sizes and x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglGluAnnulus");
    return;
  }

  isize = (double*)mxGetPr(prhs[2]);
  osize = (double*)mxGetPr(prhs[3]);

  // set color of points
  if (nrhs < 5) {
    // set default color
    glColor3f(1.0,1.0,1.0); 
  } else {
    // get color
    ncolors = mxGetN(prhs[4])*mxGetM(prhs[4]);
    if ( (ncolors != 3) && ( (ncolors != 3*ni) || (mxGetM(prhs[4]) != 3)) ) {
      mexPrintf("%i, ni=%i\n", ncolors,ni);
      mexPrintf("(mglGluAnnulus) UHOH: Vector of colors needs to be 3x1 or 3xn\n\n");
      usageError("mglGluAnnulus");
      return;
    }
    color = (double*)mxGetPr(prhs[4]);
    if (ncolors == 3) {
	glColor3f(color[0],color[1],color[2]);
    }
  }
  
  // set default loops and slices (or get them)
  if (nrhs < 7) {
    nloops = 2; // default radial resolution
  } else {
    nloops = (int) *mxGetPr(prhs[6]);
  }
  if (nrhs < 6) {
    nslices = 8; // default angular resolution
  } else {
    nslices = (int) *mxGetPr(prhs[5]);
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
      gluDisk(diskQuadric, isize[0], osize[0], nslices, nloops);
    else
      gluDisk(diskQuadric, isize[i], osize[i], nslices, nloops);
    glPopMatrix();
  }
  
  // free space
  gluDeleteQuadric(diskQuadric);
}

