#ifdef documentation
=========================================================================
program: mglQuad.c
by:      eli merriam, based on mglPoints.c by justin gardner & Jonas Larsson
date:    04/20/06
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to draw a quad in an OpenGL screen opened with mglOpen
usage:   mglQuad([xV, yV, rgbColor)

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
    if (nrhs<3) 
    {
      usageError("mglQuad");
      return;
    }


    double *vX, *vY, *color, rgb[3];
    int i, m, n, c1, c2, antiAliasFlag;
    double v0[2],v1[2],v2[2],v3[2];

    // read in the X and Y data
    vX = (double*)mxGetPr(prhs[0]);
    vY = (double*)mxGetPr(prhs[1]);
    
    color = (double*)mxGetPr(prhs[2]);

    if (nrhs>3) 
        antiAliasFlag = (int) *mxGetPr(prhs[3]);
    else
        antiAliasFlag = 0;
    
    m = mxGetM(prhs[0]); // rows
    n = mxGetN(prhs[0]); // columns
    
    if (mxGetM(prhs[0]) != 4)
    {
        mexPrintf ("(mglQuad) vX does not have 4 rows\n");
        return;
    }

    if (mxGetM(prhs[1]) != 4)
    {
        mexPrintf ("(mglQuad) vY does not have 4 rows\n");
        return;
    }

    if (mxGetM(prhs[2]) != 3)
    {
        mexPrintf ("(mglQuad) rgbColors does not have 3 rows\n");
        return;
    }
    
    if ( (mxGetN(prhs[0])+mxGetN(prhs[1])+mxGetN(prhs[2])) != mxGetN(prhs[0])*3 )
    {
        mexPrintf ("(mglQuad) input args differ in number of columns \n", n);
        return;
    }

    // enable and disable some things
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    // draw the quad
    glBegin(GL_QUADS);
    c1=0;                       /* counter 1 */
    c2=0;                       /* counter 2 */
    
    for(i=0;i<n;i++)         
    {
        // update variables.  ATTN i know this is inefficient
        v0[0]=*(vX+c1+0);  v0[1]=*(vY+c1+0);
        v1[0]=*(vX+c1+1);  v1[1]=*(vY+c1+1);
        v2[0]=*(vX+c1+2);  v2[1]=*(vY+c1+2);
        v3[0]=*(vX+c1+3);  v3[1]=*(vY+c1+3);
        rgb[0]=*(color+c2+0); rgb[1]=*(color+c2+1), rgb[2]=*(color+c2+2); 
        
        // draw the sucker
        glColor3f(rgb[0], rgb[1], rgb[2]);
	glVertex2dv(v0); glVertex2dv(v1); glVertex2dv(v2); glVertex2dv(v3);
        
        // update counters
        c1=c1+4;
        c2=c2+3;
    }
    glEnd();
    
    if (antiAliasFlag) {
      glEnable(GL_LINE_SMOOTH);
      GLboolean antialias;
      glGetBooleanv(GL_LINE_SMOOTH,&antialias);
      if (antialias) {
        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); 
        glEnable(GL_BLEND); 
        glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
        glLineWidth(1);

        c1=0;                       /* counter 1 */
        c2=0;                       /* counter 2 */

	glBegin(GL_QUADS);
        
        for(i=0;i<n;i++)         
	  {
            // update variables.  ATTN i know this is inefficient -epm
            v0[0]=*(vX+c1+0);  v0[1]=*(vY+c1+0);
            v1[0]=*(vX+c1+1);  v1[1]=*(vY+c1+1);
            v2[0]=*(vX+c1+2);  v2[1]=*(vY+c1+2);
            v3[0]=*(vX+c1+3);  v3[1]=*(vY+c1+3);
            rgb[0]=*(color+c2+0); rgb[1]=*(color+c2+1), rgb[2]=*(color+c2+2); 
            
            // draw the sucker
            glColor3f(rgb[0], rgb[1], rgb[2]);
            glVertex2dv(v0); glVertex2dv(v1); 
	    glVertex2dv(v2); glVertex2dv(v3);

            // update counters
            c1=c1+4;
            c2=c2+3;
	  }
	glEnd();
	glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
	glDisable(GL_LINE_SMOOTH); 
      } else {
	mexPrintf("(mglQuad): antialiasing not supported on this GL platform!\n");
      }
    }
    
}
                 
		 
