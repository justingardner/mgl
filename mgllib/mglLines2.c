#ifdef documentation
=========================================================================

     program: glLines2.c
          by: justin gardner
        date: 04/03/06
     purpose: mex function to plot lines on an OpenGL screen opened with glopen
       usage: mglLines(x0,y0, x1, y1,size,color,bgcolor)
       e.g.: mglLines2(x0, y0, x1, y1, 2, [1 0.6 1]);
              
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
  double *x0, *y0, *x1, *y1, color[4];
  int i, n;

  // check input arguments
  if ((nrhs < 4) || (nrhs>6)) {
    usageError("mglLines2");
    return;
  }

  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglLines2) UHOH: Number of x points (%i) must match with y (%i)\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    return;
  }
  x0 = (double*)mxGetPr(prhs[0]);
  y0 = (double*)mxGetPr(prhs[1]);
  x1 = (double*)mxGetPr(prhs[2]);
  y1 = (double*)mxGetPr(prhs[3]);

  // set point size
  if (nrhs < 5)
    glLineWidth(2);
  else
    glLineWidth(*mxGetPr(prhs[4]));

  // set color of points
  if (nrhs < 6)
    // set default color
    glColor3f(1.0,1.0,1.0); 
  else {
    // get color
    if (mglGetColor(prhs[5],color) == 0) 
      glColor3f(1.0,1.0,1.0);
    else
      glColor3f(color[0],color[1],color[2]);
  }

  // draw the points
  glBegin(GL_LINES);
  for(i=0;i<n;i++){
    glVertex2f(x0[i],y0[i]);
    glVertex2f(x1[i],y1[i]);
  }
  glEnd();
}

