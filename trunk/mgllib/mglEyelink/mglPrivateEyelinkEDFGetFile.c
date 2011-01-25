#ifdef documentation
=========================================================================
program: mglPrivateEyelinkEDFGetFile.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Receives a data file from the EyeLink tracker PC.
usage:   mglPrivateEyelinkEDFGetFile(filename, filedestination)


=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
#include <eyelink.h>

//////////////
//   main   //
//////////////
		
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	char *filename, *filedestination;
	INT16 dest_is_path = 0;
	int result;
	
	// Check that we have the correct number of arguments.
	if (nrhs < 1 || nrhs > 2) {
		usageError("mglPrivateEyelinkEDFGetFile");
		return;
	}
	
	// Make sure our input is a character matrix.
	if (!mxIsChar(prhs[0])) {
		mexPrintf("(mglPrivateEyelinkEDFGetFile) filename must be a string.\n");
		return;
	}
	
	// Also make sure that the input is a row vector, i.e. string.
	if (mxGetM(prhs[0]) != 1) {
		mexPrintf("(mglPrivateEyelinkEDFGetFile) Input must be a row vector.\n");
		return;
	}
	
	// Get a pointer to the filename string.
	filename = mxArrayToString(prhs[0]);
	
	// Do the same checks for the 2nd function argument if present.
	if (nrhs == 2) {
		if (!mxIsChar(prhs[1])) {
			mexPrintf("(mglPrivateEyelinkEDFGetFile) filedestination must be a string.\n");
			return;
		}
		
		if (mxGetM(prhs[1]) != 1) {
			mexPrintf("(mglPrivateEyelinkEDFGetFile) Input must be a row vector.\n");
			return;
		}
		
		// Get a pointer to the file destination string.
		filedestination = mxArrayToString(prhs[1]);
		
		// Tell the EyeLink API that we are specifying the folder where we
		// want the data file saved.
		dest_is_path = 1;
	}
	else {
		// If no file destination was specified, we'll use the same name as the
		// eye tracker file.
		filedestination = filename;
	}
	
	mexPrintf("(mglPrivateEyelinkEDFGetFile) ");
	if (result = receive_data_file(filename, filedestination, dest_is_path)) {
		if (result == FILE_CANT_OPEN || result == FILE_XFER_ABORTED) {
			mexPrintf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
			mexPrintf("(mglPrivateEyelinkEDFGetFile) File transfer error.\n");
			mexPrintf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
		}
	}
	else {
		mexPrintf("\n.");
	}
	
	// Free the string memory.
	mxFree(filename);
	if (nrhs == 2) {
		mxFree(filedestination);
	}
}
