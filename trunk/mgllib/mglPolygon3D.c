#ifdef documentation
=========================================================================
program: mglPolygon3D.c
     by: Christopher Broussard
   date: 05/10/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Mex function to draw a polygon in an OpenGL screen opened with mglOpen. 
         x, y, and z are vectors defining a closed polygon.
  usage: mglPolygon3D(x, y, z, [color])
			  
$Id: mglPolygon.c 18 2006-09-13 15:41:18Z justin $
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
  double *x, *y, *z, color[4];
  int i;

  // Check input arguments.
  if ((nrhs < 3) || (nrhs > 4)) {
    printf("Wrong number of arguments!\n\n");
    usageError("mglPolygon3D");
    return;
  }

  // Get vertices and check sizes.
  int numPoints[3]; 
  for (i = 0; i < 3; i++) {
    numPoints[i] = mxGetN(prhs[i]) * mxGetM(prhs[i]);
  }

  if (numPoints[0] != numPoints[1] || numPoints[0] != numPoints[2]) {
    mexPrintf("(mglPolygon) UHOH: Number of x, y, and z points must match.\n");
    usageError("mglPolygon3D");
    return;
  }

  // Grab the vertices.
  x = mxGetPr(prhs[0]);
  y = mxGetPr(prhs[1]);
  z = mxGetPr(prhs[2]);

  // Set the point color.
  if (nrhs < 4)
    // Default color.
    glColor3d(1.0, 1.0, 1.0);
  else {
    if (mglGetColor(prhs[3], color) == 0) {
      glColor3d(1.0, 1.0, 1.0);
    }
    else {
      glColor3d(color[0], color[1], color[2]);
    }
  }

  // Antialias the edges.
  glEnable(GL_POLYGON_SMOOTH);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

  // draw the polygon - fill
  glBegin(GL_POLYGON);
  for(i = 0; i < numPoints[0]; i++) {
    glVertex3d(x[i], y[i], z[i]);
  }
  glEnd();

  glDisable(GL_BLEND);
}

