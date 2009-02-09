#ifdef documentation
=========================================================================

     program: mglTransform.c
          by: Jonas Larsson
        date: 2006-04-07
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
     purpose: applies view transformations 
     syntax:  mglTransform( whichMatrix, whichTransform, whichParameters )

$Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

////////////////////////
//   define section   //
////////////////////////

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  // if display number does not exist, then there is nothing to do
  if (!mglIsGlobal("displayNumber")) {
    mexPrintf("(mglTransform) No open window\n");
    return;
  }

  // get what display number we have
  int displayNumber = (int)mglGetGlobalDouble("displayNumber");
  if (displayNumber<0) {
    mexPrintf("(mglTransform) No open window\n");
    return;
  }

  // get parameters
  if (nrhs<1) {
    usageError("mglTransform");
    return;
  }

  if (!mxIsChar( prhs[0] )) {
    mexPrintf("First input argument must be a string:\n");
    mexPrintf(" whichMatrix:     one of GL_MODELVIEW, GL_PROJECTION, or GL_TEXTURE\n");
    return;
  }
  if (nrhs>1 && !mxIsChar( prhs[1] )) {
    mexPrintf("Second input argument must be a string:\n");
    mexPrintf(" whichTransform:  one of glRotate, glTranslate, glScale, glMultMatrix, glFrustum, glOrtho,\n");
    mexPrintf("                  glLoadMatrix, glLoadIdentity, glPushMatrix, glPopMatrix, glDepthRange, or glViewport\n");
    return;
  }

  // parse matrix mode
  int buflen=mxGetN( prhs[0] )+1;
  char *whichMatrix=(char*)malloc(buflen);
  mxGetString( prhs[0], whichMatrix, buflen);
  if (strcmp(whichMatrix,"GL_MODELVIEW")==0) {
    glMatrixMode( GL_MODELVIEW );
  } else if (strcmp(whichMatrix,"GL_PROJECTION")==0) {
    glMatrixMode( GL_PROJECTION );
  } else if (strcmp(whichMatrix,"GL_TEXTURE")==0) {
    glMatrixMode( GL_TEXTURE );    
  } else {
    mexPrintf("Incorrect matrix specification!\n");
    mexPrintf(" whichMatrix:     one of GL_MODELVIEW, GL_PROJECTION, or GL_TEXTURE\n");
    return;
  }
  
  if (nlhs>0) {
    // return initial matrix
    plhs[0]= mxCreateDoubleMatrix(4,4,mxREAL);
    double * optr = mxGetPr(plhs[0]);
    if (strcmp(whichMatrix,"GL_MODELVIEW")==0) {
      glGetDoublev( GL_MODELVIEW_MATRIX, optr );
    } else if (strcmp(whichMatrix,"GL_PROJECTION")==0) {
      glGetDoublev( GL_PROJECTION_MATRIX, optr );
    } else if (strcmp(whichMatrix,"GL_TEXTURE")==0) {
      glGetDoublev( GL_TEXTURE_MATRIX, optr );
    } 
  }

  // return here if no transform is specified
  if (nrhs < 2) return;

  // parse transform to apply
  buflen=mxGetN( prhs[1] )+1;
  char *whichTransform=(char*)malloc(buflen);
  mxGetString( prhs[1], whichTransform, buflen);
  if (strcmp(whichTransform,"glRotate")==0) {
    if (nrhs!=6) {
      mexPrintf("Wrong number of arguments for %s (should be 4)\n",whichTransform);
      return;
    }
    glRotated( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ), *mxGetPr( prhs[5] ));
  } 
  else if (strcmp(whichTransform,"glTranslate")==0) {
    if (nrhs!=5) {
      mexPrintf("Wrong number of arguments for %s (should be 3)\n",whichTransform);
      return;
    }
    glTranslated( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ));
  } else if (strcmp(whichTransform,"glScale")==0) {
    if (nrhs!=5) {
      mexPrintf("Wrong number of arguments for %s (should be 2)\n",whichTransform);
      return;
    }
    glScaled( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ));
  } else if (strcmp(whichTransform,"glMultMatrix")==0) {
    if (nrhs!=3) {
      mexPrintf("Wrong number of arguments for %s (should be 1)\n",whichTransform);
      return;
    }
    if ( mxGetN( prhs[2] ) !=4 || mxGetM( prhs[2] ) != 4 ) {
      mexPrintf("Error: transformation matrix must be 4x4\n");
      return;
    }
    glMultMatrixd( mxGetPr( prhs[2] ));
  } else if (strcmp(whichTransform,"glFrustum")==0) {
    if (nrhs!=8) {
      mexPrintf("Wrong number of arguments for %s (should be 6)\n",whichTransform);
      return;
    }
    glFrustum( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ), *mxGetPr( prhs[5] ),  *mxGetPr( prhs[6] ), *mxGetPr( prhs[7] ) );
  } else if (strcmp(whichTransform,"glOrtho")==0) {
    if (nrhs!=8) {
      mexPrintf("Wrong number of arguments for %s (should be 6)\n",whichTransform);
      return;
    }
    glOrtho( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ), *mxGetPr( prhs[5] ),  *mxGetPr( prhs[6] ), *mxGetPr( prhs[7] ) );
  } else if (strcmp(whichTransform,"glLoadMatrix")==0) {
    if (nrhs!=3) {
      mexPrintf("Wrong number of arguments for %s (should be 1)\n",whichTransform);
      return;
    }
    if ( mxGetN( prhs[2] ) !=4 || mxGetM( prhs[2] ) != 4 ) {
      mexPrintf("Error: transformation matrix must be 4x4\n");
      return;
    }
    glLoadMatrixd( mxGetPr( prhs[2] ));
  } else if (strcmp(whichTransform,"glLoadIdentity")==0) {
    glLoadIdentity();
  } else if (strcmp(whichTransform,"glPushMatrix")==0) {
    glPushMatrix();
  } else if (strcmp(whichTransform,"glPopMatrix")==0) {
    glPopMatrix();
  } else if (strcmp(whichTransform,"glViewport")==0) {
    if (nrhs!=6) {
      mexPrintf("Wrong number of arguments for %s (should be 4)\n",whichTransform);
      return;
    }
    glViewport( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ), *mxGetPr( prhs[4] ), *mxGetPr( prhs[5] ));
  } else if (strcmp(whichTransform,"glDepthRange")==0) {
    if (nrhs!=4) {
      mexPrintf("Wrong number of arguments for %s (should be 2)\n",whichTransform);
      return;
    }
    glDepthRange( *mxGetPr( prhs[2] ), *mxGetPr( prhs[3] ) );
  } else if (nrhs>1) {
    mexPrintf("Incorrect transform specification!\n");
    mexPrintf(" whichTransform:  one of glRotate, glTranslate, glScale, glMultMatrix, glFrustum, glOrtho,\n");
    mexPrintf("                  glLoadMatrix, glLoadIdentity, glPushMatrix, glPopMatrix, glDepthRange, or glViewport\n");
    return;
  }
  if (nlhs>1) {
    // return resulting matrix
    plhs[1]= mxCreateDoubleMatrix(4,4,mxREAL);
    double * optr = mxGetPr(plhs[1]);
    GLint nmats=0;
    if (strcmp(whichMatrix,"GL_MODELVIEW")==0) {
      glGetIntegerv( GL_MODELVIEW_STACK_DEPTH, &nmats );
      if (nmats>0) {
	glGetDoublev( GL_MODELVIEW_MATRIX, optr );
      }
    } else if (strcmp(whichMatrix,"GL_PROJECTION")==0) {
      glGetIntegerv( GL_PROJECTION_STACK_DEPTH, &nmats );
      if (nmats>0) {
	glGetDoublev( GL_PROJECTION_MATRIX, optr );
      }
    } else if (strcmp(whichMatrix,"GL_TEXTURE")==0) {
      glGetIntegerv( GL_TEXTURE_STACK_DEPTH, &nmats );
      if (nmats>0) {
	glGetDoublev( GL_TEXTURE_MATRIX, optr );
      } 
    }
  }
  // clean up
  free( whichMatrix );
  free( whichTransform );
  // set scaling of normals 
  //glEnable(GL_NORMALIZE);
}

