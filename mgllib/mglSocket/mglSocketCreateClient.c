#ifdef documentation
=========================================================================

  program: mglSocketCreateClient.c
       by: Ben Heasly
     date: 03/01/2022
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to open a posix socket and connect to an address.
    usage: s = mglSocketCreateClient(address, pollMilliseconds=10)

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"
#include <sys/socket.h>
#include <sys/un.h>

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for expected usage.
    if (nrhs < 1 || nrhs > 3 || nlhs != 1){
        const int ndims = 1;
        const int dims[] = {1};
        mxArray *callInput[] = { mxCreateString("mglSocketCreateClient") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the socket address to connect to from the first argument.
    char *address = mxArrayToUTF8String(prhs[0]);
    if (address == NULL) {
        mexPrintf("(mglSocketCreateClient) Could not read socket address from first arg.\n");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    struct sockaddr_un addr;
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, address, sizeof(addr.sun_path) - 1);
    mxFree(address);

    // Get the socket polling time in ms from the second argument.
    double pollMilliseconds = 10;
    if (nrhs >= 2) {
        pollMilliseconds = mxGetScalar(prhs[1]);
    }
    
    // Create a socket for the client connect from.
    int connectionSocketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0);
    if (connectionSocketDescriptor < 0) {
        mexPrintf("(mglSocketCreateClient) Could not create a socket -- result: %d, errno: %d\n", connectionSocketDescriptor, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // Connect the socket to the given address.
    int connectResult = connect(connectionSocketDescriptor, (struct sockaddr *) &addr, sizeof(struct sockaddr_un));
    if (connectResult < 0) {
        close(connectionSocketDescriptor);
        mexPrintf("(mglSocketCreateClient) Could not connect socket to address %s -- result: %d, errno: %d\n", addr.sun_path, connectResult, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // Success.
    if (verbose) {
        mexPrintf("(mglSocketCreateClient) ready and connected to server at %s\n", addr.sun_path);
    }
    
    // Return socket info struct to pass to other socket functions.
    const char *fieldNames[] = {"address", "pollMilliseconds", "maxConnections", "boundSocketDescriptor", "connectionSocketDescriptor"};
    plhs[0] = mxCreateStructMatrix(1, 1, 5, fieldNames);
    mxSetField(plhs[0], 0, "address", mxCreateString(addr.sun_path));
    mxSetField(plhs[0], 0, "pollMilliseconds", mxCreateDoubleScalar(pollMilliseconds));
    mxSetField(plhs[0], 0, "maxConnections", mxCreateDoubleScalar(0));
    mxSetField(plhs[0], 0, "boundSocketDescriptor", mxCreateDoubleScalar(-1));
    mxSetField(plhs[0], 0, "connectionSocketDescriptor", mxCreateDoubleScalar(connectionSocketDescriptor));
}
