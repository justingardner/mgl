#ifdef documentation
=========================================================================
program: mglDrawImage.c
     by: Christopher Broussard
   date: 06/08/2008
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Mex function to take draw an RGB image.
  usage: mglDrawImage(pixelData, centerPx)
			  
$Id: mglPolygon.c,v 1.3 2006/09/13 15:40:39 justin Exp $
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

#define INDEXELEMENTFROM3DARRAY(mDim, nDim, pDim, m, n, p) (p*mDim*nDim + n*mDim + m)

/////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int ri, gi, bi, ix, iy, inputM, inputN, pixelIndex = 0;
	size_t numPoints;
	double *inputMatrix, *centerPos;
	const mwSize *dims;
	GLfloat *pixelData, rv, gv, bv, rasterX, rasterY;
	GLdouble currentRasterPosition[4];
	
	if (nrhs != 2) {
		usageError("mglDrawImage");
		return;
	}
	
	// Get the dimensions of the input image.
	dims = mxGetDimensions(prhs[0]);
	inputM = dims[0];
	inputN = dims[1];
	numPoints = (size_t)(inputM * inputN);
	
	// DEBUG
	//mexPrintf("M: %d, N: %d, numPoints: %d\n", inputM, inputN, numPoints);
	
	// Get the center position of the image.
	centerPos = mxGetPr(prhs[1]);
	
	// Get a pointer to the image data.
	inputMatrix = mxGetPr(prhs[0]);
	
	// Allocate memory to hold the repacked image data.
	pixelData = (GLfloat*)mxMalloc(numPoints * sizeof(GLfloat) * 4);
	
	// Repack the image data in a format that OpenGL can use.
	for (iy = 0; iy < inputM; iy++) {
		for (ix = 0; ix < inputN; ix++) {
			// Find the index into the input data that corresponds to the specific
			// location we want.
			ri = INDEXELEMENTFROM3DARRAY(inputM, inputN, 3, iy, ix, 0);
			gi = INDEXELEMENTFROM3DARRAY(inputM, inputN, 3, iy, ix, 1);
			bi = INDEXELEMENTFROM3DARRAY(inputM, inputN, 3, iy, ix, 2);
			
			// Pull out the indexed values.
			rv = (GLfloat)inputMatrix[ri];
			gv = (GLfloat)inputMatrix[gi];
			bv = (GLfloat)inputMatrix[bi];
			
			// Put the values into the OpenGL packed array.
			pixelData[pixelIndex++] = rv;
			pixelData[pixelIndex++] = gv;
			pixelData[pixelIndex++] = bv;
			pixelData[pixelIndex++] = (GLfloat)1.0;
		}
	}
	
	// Get the previous raster position so we restore it later.
	glGetDoublev(GL_CURRENT_RASTER_POSITION, currentRasterPosition);
	
	// Set the raster position so that we can draw starting at this location.
	rasterX = (GLfloat)(centerPos[0] - (GLfloat)(inputN)/2.0);
	rasterY = (GLfloat)(centerPos[1] + (GLfloat)(inputM)/2.0);
	glRasterPos2f(rasterX, rasterY);
	
	// Tell glDrawPixels to unpack the pixel array along GLfloat boundaries.
	glPixelStorei(GL_UNPACK_ALIGNMENT, (GLint)sizeof(GLfloat));
	
	// Dump the pixels to the screen.
	glDrawPixels(inputN, inputM, GL_RGBA, GL_FLOAT, pixelData);
	
	mxFree(pixelData);
}
