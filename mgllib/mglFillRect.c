#ifdef documentation
=========================================================================

     program: mglFillRect.c
          by: denis schluppeck (based on code by justin gardner & Jonas Larsson)
        date: 04/03/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: mex function to plot an rect on an OpenGL screen opened with mglOpen
       usage: mglFillRect(x,y,size, color, [antialias])
              
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
  int i, n, nsize, antiAliasFlag;
    
  // check input arguments
  if ((nrhs < 3) || (nrhs>5)) {
    mexPrintf("(mglFillRect) Wrong number of arguments!\n\n");
    usageError("mglFillRect");
    return;
  }
  
  // get points
  n = mxGetN(prhs[0])*mxGetM(prhs[0]);
  if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
    mexPrintf("(mglFillRect) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
    usageError("mglFillRect");
    return;
  }
  x = (double*)mxGetPr(prhs[0]);
  y = (double*)mxGetPr(prhs[1]);
  
  // get size
  nsize = mxGetN(prhs[2])*mxGetM(prhs[2]);
  if (nsize != 2 ) {
    mexPrintf("(mglFillRect) UHOH: size needs to have x and y dims\n");
    return;
  }
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
  if (nrhs < 6)
    antiAliasFlag = 0;
  else {
    if ((int)*mxGetPr(prhs[5]) == 1)
      antiAliasFlag = 1;
    else
      antiAliasFlag = 0;
  }
  //enable and disable some things
  //glDisable(GL_DEPTH_TEST);
  //glDisable(GL_TEXTURE_2D);
  //glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  //glEnable(GL_BLEND);
  
  // specify that we are changing the modelview matrix
  glMatrixMode(GL_MODELVIEW);

  // make the rect
  // and draw it
  for(i=0;i<n;i++){
    glPushMatrix();
    glTranslated(x[i],y[i], 0.0);
    glScaled(size[0]/2, size[1]/2, 1.0 ); 
    glBegin(GL_QUADS);
    glVertex2d(-1.0, -1.0); glVertex2d(-1.0, +1.0); glVertex2d(+1.0, +1.0); glVertex2d(+1.0, -1.0);
    glEnd();
    glPopMatrix();
  
    // maybe antialias the edges
    if (antiAliasFlag == 1)
      {
	glEnable(GL_LINE_SMOOTH);
	//glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	//glEnable(GL_BLEND);
	glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);
	
	glBegin(GL_QUADS);
	glVertex2d(-1.0, -1.0); glVertex2d(-1.0, +1.0); glVertex2d(+1.0, +1.0); glVertex2d(+1.0, -1.0);
	glEnd();
	
	glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);
	glDisable(GL_LINE_SMOOTH);
      }    
    
  }
  
  
  
}

