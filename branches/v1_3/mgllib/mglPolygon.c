#ifdef documentation
=========================================================================
program: mglPolygon.c
     by: denis schluppeck (based on mglQuad/mglPoints by eli, 
         justin, jonas
   date: 05/10/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to draw a polygon in an OpenGL screen opened with mglOpen. 
	 x and y can be vectors (the polygon will be closed)
  usage: mglPolygon(x, y, [color])
			  
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
  double *x, *y, color[4];
    int i, n;

    // check input arguments
    if ((nrhs < 2) || (nrhs>3)) {
        printf("Wrong number of arguments!\n\n");
        usageError("mglPolygon");
	return;
    }
    
    // get vertices and check sizes
    n = mxGetN(prhs[0])*mxGetM(prhs[0]);
    if (n != mxGetN(prhs[1])*mxGetM(prhs[1]) ) {
      mexPrintf("(mglPolygon) UHOH: Number of x points (%i) must match with y (%i)\n\n",n,mxGetN(prhs[1])*mxGetM(prhs[1]));
      usageError("mglPolygon");
      return;
    }

    // set the vertices
    x = (double*)mxGetPr(prhs[0]);
    y = (double*)mxGetPr(prhs[1]);
 


    // set color of points
    if (nrhs < 3)
        // set default color
        glColor3f(1.0,1.0,1.0);
    else {
      // get color
      if (mglGetColor(prhs[2],color) == 0) 
	glColor3f(1.0,1.0,1.0);
      else
	glColor3f(color[0],color[1],color[2]);
    }


    // enable and disable some things
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    // draw the polygon
    glBegin(GL_POLYGON);
    for(i=0;i<n;i++){
      glVertex2f(x[i],y[i]);
    }

    glEnd();

    // antialias the edges
    glEnable(GL_LINE_SMOOTH);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);
    
    // draw the polygon - fill
    glBegin(GL_POLYGON);
    for(i=0;i<n;i++){
      glVertex2f(x[i],y[i]);
    }
    glEnd();

    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);
    glDisable(GL_LINE_SMOOTH);

}

