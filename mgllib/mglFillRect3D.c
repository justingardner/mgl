#ifdef documentation
=========================================================================

   program:mglFillRect3D.c
        by:Christopher Broussard
      date:05 / 10 / 2011
 copyright:(c) 2006 Justin     Gardner, Jonas Larsson(GPL see mgl / COPYING)
   purpose: mex function to plot an rect on an OpenGL screen opened with mglOpen
     usage:mglFillRect(x, y, z, size, color,[antialias])
	  
$Id: mglFillRect3D.c 334 2008 - 12 - 28 02: 49:05 Z justin $
=========================================================================
#endif


/////////////////////////
//include section //
/////////////////////////
#include "mgl.h"

/////////////
//main //
//////////////
void mexFunction(int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[])
{
  double         *x, *y, *z, *size, color[4];
  int             i, n, nsize, antiAliasFlag;
  int             numX, numY, numZ; //Number of x, y, and z points.

  // check input arguments
  if ((nrhs < 4) || (nrhs > 6)) {
    mexPrintf("(mglFillRect) Wrong number of arguments!\n\n");
    usageError("mglFillRect");
    return;
  }
  // Get the number of each coordinate.
  numX = mxGetNumberOfElements(prhs[0]);
  numY = mxGetNumberOfElements(prhs[1]);
  numZ = mxGetNumberOfElements(prhs[2]);

  // Make sure that they all have the same number of points.
  if (numX != numY || numX != numZ) {
    mexPrintf("(mglFillRect) UHOH: Number of x points (%i) must match with y (%i) and z (%i)\n\n", numX, numY, numZ);
    usageError("mglFillRect");
    return;
  }
  
  // Grab the coordinates data.
  x = (double *) mxGetPr(prhs[0]);
  y = (double *) mxGetPr(prhs[1]);
  z = (double *) mxGetPr(prhs[2]);

  // Get the size data.
  nsize = mxGetNumberOfElements(prhs[3]);
  if (nsize != 2) {
    mexPrintf("(mglFillRect) UHOH: size needs to have x and y dims\n");
    return;
  }
  size = (double *) mxGetPr(prhs[3]);

  // Set color of points.
  if (nrhs < 5) {
    // set default color
    glColor3f(1.0, 1.0, 1.0);
  }
  else {
    // Grab the RGB value and set it to the default if it's messed up.
    if (mglGetColor(prhs[4], color) == 0) {
      glColor3f(1.0, 1.0, 1.0);
	}
    else {
      glColor3f(color[0], color[1], color[2]);
	}
  }

  // Look for the antialiasing flag.
  if (nrhs < 6)
    antiAliasFlag = 0;
  else {
    if ((int) *mxGetPr(prhs[5]) == 1) {
      antiAliasFlag = 1;
	}
    else {
	  antiAliasFlag = 0;
	}
  }
  
  //enable and disable some things
  // glDisable(GL_DEPTH_TEST);
  //glDisable(GL_TEXTURE_2D);
  //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  //glEnable(GL_BLEND);

  // Switch back to the modelview matrix.
  glMatrixMode(GL_MODELVIEW);

  // Render the rectangles.
  for (i = 0; i < n; i++) {
    glPushMatrix();
    glTranslated(x[i], y[i], z[i]);
    glScaled(size[0] / 2, size[1] / 2, 1.0);
    glBegin(GL_QUADS);
    glVertex2d(-1.0, -1.0);
    glVertex2d(-1.0, +1.0);
    glVertex2d(+1.0, +1.0);
    glVertex2d(+1.0, -1.0);
    glEnd();
    glPopMatrix();

    // Antialias the edges if toggled.
    if (antiAliasFlag == 1) {
      glEnable(GL_LINE_SMOOTH);
      //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      //glEnable(GL_BLEND);
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

      glBegin(GL_QUADS);
      glVertex2d(-1.0, -1.0);
      glVertex2d(-1.0, +1.0);
      glVertex2d(+1.0, +1.0);
      glVertex2d(+1.0, -1.0);
      glEnd();

      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      glDisable(GL_LINE_SMOOTH);
    }
  }
}
