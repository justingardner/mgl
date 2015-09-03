#ifdef documentation
=========================================================================

  program: mglClearScreen.c
       by: justin gardner
     date: 04/03/06
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose: mex function to clear the screen
    usage: mglClearScreen(<color>, <clearBits>)

  $Id$
		  
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

#define NUM_BUFFER_TYPES 4
static const GLbitfield bufferTypes[] = {GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT,
                                         GL_ACCUM_BUFFER_BIT, GL_STENCIL_BUFFER_BIT};

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  GLbitfield mask = GL_COLOR_BUFFER_BIT;

  if (nrhs > 2) {
    usageError("mglClearScreen");
  }

  switch (nrhs) {
    case 2:
      {
        size_t m, n;
        int i;
        mwSize numDims;
        double *bitsInfo;

        // Validate the dimensions of the input.
        numDims = mxGetNumberOfDimensions(prhs[1]);
        if (numDims != 2) {
          mexPrintf("(mglClearScreen) clearBits can only have 2 dimensions.\n");
          return;
        }

        // Validate that the input is a 1xNUM_BUFFER_TYPES.
        if (mxGetM(prhs[1]) != 1 || mxGetN(prhs[1]) != NUM_BUFFER_TYPES) {
          mexPrintf("(mglClearScreen) clearBits must be a 1x4 array.\n");
          return;
        }

        // Read in the buffer bit info and set the mask.
        bitsInfo = mxGetPr(prhs[1]);
        mask = 0;
        for (i = 0; i < NUM_BUFFER_TYPES; i++) {
          if ((int)bitsInfo[i]) {
            mask = mask | bufferTypes[i];
          }
        }
      }

    case 1:
      {
        double color[4];

        // Try to get the color.  Throw an error if we are unsuccessful,
        // and go ahead and set the clear color if we are successful.
        if (!mglGetColor(prhs[0], color)) {
          usageError("mlgClearScreen");
        }
	glClearColor(color[0], color[1], color[2], color[3]);

      }
  }

  // check if we have to do a stencil clear. This is used to
  // stencil out a portion of the screen to black and only
  // allow drawing on the stenciled portion - something useful
  // for when you are projecting on to an irregularly shaped screen
  const mxArray *mglGlobalClearWithMask = mexGetVariablePtr("global", "mglGlobalClearWithMask");
  if (mglGlobalClearWithMask == NULL)
    // now clear to the set color
    glClear(mask);
  else {
    // get stencil number
    double *clearWithMask = mxGetPr(mglGlobalClearWithMask);
    // get the clear color
    GLfloat clearColor[4];
    glGetFloatv(GL_COLOR_CLEAR_VALUE,clearColor);
    double deviceWidth = mglGetGlobalDouble("deviceWidth");
    double deviceHeight = mglGetGlobalDouble("deviceHeight");
    // clear to black
    glClearColor(0,0,0,1);
    glClear(mask);
    // set clear color back
    glClearColor(clearColor[0],clearColor[1],clearColor[2],clearColor[3]);
    // set stencil
    //    int stencilBits = (int)mglGetGlobalDouble("stencilBits");
    //    int stencilAllMask = (1<<stencilBits)-1;
    //    int stencilNumber = (1<<((int)(clearWithMask[0])-1));
    //    glStencilFunc(GL_EQUAL,stencilAllMask,stencilNumber);
    // set color    
    glColor3f(clearColor[0],clearColor[1],clearColor[2]);
    // draw rectangle
    glRectd(-deviceWidth/2,-deviceHeight/2,deviceWidth/2,deviceHeight/2);
  }
}

