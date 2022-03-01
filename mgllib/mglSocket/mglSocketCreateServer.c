#ifdef documentation
=========================================================================

  program: mglSocketCreateServer.c
       by: Ben Heasly
     date: 03/01/2022
copyright: (c) 2019 Justin Gardner (GPL see mgl/COPYING)
  purpose: mex function to open a posix socket and listen at an address.
    usage: s = mglSocketCreateServer(address pollMilliseconds=10, maxConnections=500)

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
        mxArray *callInput[] = { mxCreateString("mglSocketCreateServer") };
        mexCallMATLAB(0, NULL, 1, callInput, "help");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    int verbose = (int)mglGetGlobalDouble("verbose");

    // Get the socket address to bind from the first argument.
    char *address = mxArrayToUTF8String(prhs[0]);
    if (address == NULL) {
        mexPrintf("(mglSocketCreateServer) Could not read socket address from first arg.\n");
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

    // Get the max number of pending connections from the third argument.
    double maxConnections = 500;
    if (nrhs >= 3) {
        maxConnections = mxGetScalar(prhs[2]);
    }

    // Create a socket for the server to bind and listen on.
    int boundSocketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0);
    if (boundSocketDescriptor < 0) {
        mexPrintf("(mglSocketCreateServer) Could not create a socket -- result: %d, errno: %d\n", boundSocketDescriptor, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Make the socket nonblocking so that accept() doesn't stall Matlab.
    int nonblockingResult = fcntl(boundSocketDescriptor, F_SETFL, O_NONBLOCK);
    if (nonblockingResult < 0) {
        close(boundSocketDescriptor);
        mexPrintf("(mglSocketCreateServer) Could not make socket nonblocking -- result: %d, errno: %d\n", nonblockingResult, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Bind the socket to the given address.
    int bindResult = bind(boundSocketDescriptor, (struct sockaddr *) &addr, sizeof(struct sockaddr_un));
    if (bindResult < 0) {
        close(boundSocketDescriptor);
        mexPrintf("(mglSocketCreateServer) Could not bind socket to address %s -- result: %d, errno: %d\n", addr.sun_path, bindResult, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Start listening and queueing up pending client connections.
    int listenResult = listen(boundSocketDescriptor, maxConnections);
    if (listenResult < 0) {
        close(boundSocketDescriptor);
        mexPrintf("(mglSocketCreateServer) Could not listen for connections -- result: %d, errno: %d\n", listenResult, errno);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }

    // Success.
    if (verbose) {
        mexPrintf("(mglSocketCreateServer) ready and listening for connections at address %s\n", addr.sun_path);
    }

    // Return socket info struct to pass to other socket functions.
    const char *fieldNames[] = {"address", "pollMilliseconds", "maxConnections", "boundSocketDescriptor", "connectionSocketDescriptor"};
    plhs[0] = mxCreateStructMatrix(1, 1, 5, fieldNames);
    mxSetField(plhs[0], 0, "address", mxCreateString(addr.sun_path));
    mxSetField(plhs[0], 0, "pollMilliseconds", mxCreateDoubleScalar(pollMilliseconds));
    mxSetField(plhs[0], 0, "maxConnections", mxCreateDoubleScalar(maxConnections));
    mxSetField(plhs[0], 0, "boundSocketDescriptor", mxCreateDoubleScalar(boundSocketDescriptor));
    mxSetField(plhs[0], 0, "connectionSocketDescriptor", mxCreateDoubleScalar(-1));
}
