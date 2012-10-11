#ifdef documentation
=========================================================================

  program:mglFillRect3D.c
       by:Christopher Broussard
     date:05 / 10 / 2011
copyright:(c) 2006 Justin     Gardner, Jonas Larsson(GPL see mgl / COPYING)
  purpose: mex function to plot an rect on an OpenGL screen opened with mglOpen
    usage:mglFillRect(x, y, z, size, [color], [rotation], [antialias])

  $Id: mglFillRect3D.c 334 2008 - 12 - 28 02: 49:05 Z justin $

  =========================================================================
#endif


/////////////////////////
//include section      //
/////////////////////////
#include "mgl.h"

// Defines to help us index arguments out of the prhs.
#define XI 0
#define YI 1
#define ZI 2
#define SIZEI 3
#define COLORI 4
#define ROTI 5
#define AAI 6
#define MAX_ARGS 7
#define MIN_ARGS 4

//////////////
//main      //
//////////////
void mexFunction(int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[])
{
  double         *x, *y, *z, *size, color[4], *rotData;
  int             i, n, nsize, antiAliasFlag;
  int             numX, numY, numZ; //Number of x, y, and z points.

  // Validate the number of arguments passed.
  if (nrhs < MIN_ARGS || nrhs > MAX_ARGS) {
    mexPrintf("(mglFillRect3D) Wrong number of arguments!\n\n");
    usageError("mglFillRect3D");
    return;
  }

  // Get the number of each coordinate.
  numX = mxGetNumberOfElements(prhs[XI]);
  numY = mxGetNumberOfElements(prhs[YI]);
  numZ = mxGetNumberOfElements(prhs[ZI]);

  // Make sure that they all have the same number of points.
  if (numX != numY || numX != numZ) {
    mexPrintf("(mglFillRect3D) UHOH: Number of x points (%i) must match with y (%i) and z (%i)\n\n", numX, numY, numZ);
    usageError("mglFillRect3D");
    return;
  }

  // Grab the coordinates data.
  x = (double*)mxGetPr(prhs[XI]);
  y = (double*)mxGetPr(prhs[YI]);
  z = (double*)mxGetPr(prhs[ZI]);

  // Get the size data.
  nsize = mxGetNumberOfElements(prhs[SIZEI]);
  if (nsize != 2) {
    mexPrintf("(mglFillRect3D) UHOH: size needs to have x and y dims\n");
    return;
  }
  size = (double*)mxGetPr(prhs[SIZEI]);

  // Set the color of the points.
  if (nrhs <= COLORI) {
    // Default to white.
    glColor3d(1.0, 1.0, 1.0);
  }
  else {
    // Grab the RGB value and set it to the default if it's messed up.
    if (mglGetColor(prhs[COLORI], color) == 0) {
      glColor3d(1.0, 1.0, 1.0);
    }
    else {
      glColor4d(color[0], color[1], color[2], color[3]);
    }
  }

  // Set the rotation value.
  if (nrhs <= ROTI) {
    // Default to zero about the y-axis.
    rotData = (double*)mxMalloc(4*sizeof(double));
    rotData[0] = 0.0; rotData[1] = 0.0; rotData[2] = 1.0; rotData[3] = 0.0;;
  }
  else {
    // Validate the input dims.
    if (mxGetNumberOfElements(prhs[ROTI]) != 4 || mxGetM(prhs[ROTI]) != 1 || mxGetN(prhs[ROTI]) != 4) {
      mexPrintf("(mglFillRect3D) rotation must be a 1x4.\n");
      return;
    }

    rotData = mxGetPr(prhs[ROTI]); 
  }

  // Set antialiasing.
  if (nrhs <= AAI) {
    antiAliasFlag = 0;
  }
  else {
    if ((int) *mxGetPr(prhs[5]) == 1) {
      antiAliasFlag = 1;
    }
    else {
      antiAliasFlag = 0;
    }
  }

  // Switch back to the modelview matrix.
  glMatrixMode(GL_MODELVIEW);

  // Render the rectangles.
  for (i = 0; i < numX; i++) {
    glPushMatrix();

    glTranslated(x[i], y[i], z[i]);
    glRotated(rotData[0], rotData[1], rotData[2], rotData[3]);
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
