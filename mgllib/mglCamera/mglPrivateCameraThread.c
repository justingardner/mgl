#ifdef documentation
=========================================================================

    program: mglPrivateCameraThread.c
         by: justin gardner
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
       date: 10/14/2019
    purpose: Starts a thread to interact with FLIR camera - based on mglPrivateListener.c
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include <mex.h>
#include <pthread.h>
#include "Spinnaker.h"
#include "SpinGenApi/SpinnakerGenApi.h"
#include <iostream>
#include <sstream>
#include "matrix.h"
// used for time function
#include <mach/mach.h>
#include <mach/mach_time.h>

////////////////////
//    namespace   //
////////////////////
using namespace Spinnaker;
using namespace Spinnaker::GenApi;
using namespace Spinnaker::GenICam;
using namespace std;

////////////////////////
//   define section   //
////////////////////////
#define TRUE 1
#define FALSE 0

#define NOCOMMAND -1
#define INIT 1
#define QUIT 2
#define CAPTURE 3
#define GETDATA 4

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* cameraThread(void *data);
void startCameraThread();
void mglPrivateCameraThreadOnExit(void);
int AcquireImages(CameraPtr pCam, unsigned int numImages, INodeMap& nodeMap, vector<ImagePtr>& images, vector<double>& imageTimes);
double getCurrentTimeInSeconds();

////////////////
//   globals  //
////////////////
static pthread_mutex_t gMutex;
static int gCameraThreadInstalled = FALSE;
static int gCommand = 0;
static mxArray *gData;
unsigned int gImageWidth, gImageHeight;
// Pointer for images
vector<ImagePtr> gImages;
vector<double> gImageTimes;

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get which command this is
  int command = mxGetScalar(prhs[0]);

  // INIT command -----------------------------------------------------------------
  if (command == INIT) {
    // start the thread that will have a callback that gets called every
    // time there is a keyboard or mouse event of interest
    if (!gCameraThreadInstalled) {

      // init pthread_mutex
      pthread_mutex_init(&gMutex,NULL);
      pthread_mutex_lock(&gMutex);

      // start the thread
      startCameraThread();

      // and remember that we have a thread running
      gCameraThreadInstalled = TRUE;

      // display that we started
      mexPrintf("(mglPrivateCameraThread) Starting camera thread. End with mglCameraThread('quit').\n");

      // tell matlab to call this function to cleanup properly
      //mexAtExit(mglPrivateCameraThreadOnExit);

      // unlock the mutex
      pthread_mutex_unlock(&gMutex);

      // started running, return 1
      plhs[0] = mxCreateDoubleScalar(1);
    }
    else {

      // set flag to no command
      pthread_mutex_lock(&gMutex);
      gCommand = NOCOMMAND;
      pthread_mutex_unlock(&gMutex);

      // already running, return 1
      plhs[0] = mxCreateDoubleScalar(1);
    }
  }
  // Capture command -----------------------------------------------------------------
  else if (command == CAPTURE) {
    if (gCameraThreadInstalled) {

      // lock the pthread mutex
      pthread_mutex_lock(&gMutex);

      // set flag to capture
      gCommand = CAPTURE;

      // unlock the mutex
      pthread_mutex_unlock(&gMutex);
    }
    // return 1
    plhs[0] = mxCreateDoubleScalar(1);
  }
  // Get data command -----------------------------------------------------------------
  else if (command == GETDATA) {
    if (gCameraThreadInstalled) {
      
      // lock the pthread mutex
      pthread_mutex_lock(&gMutex);

      unsigned int imageSize = gImageWidth * gImageHeight;
      unsigned int nImages = gImages.size();
      mexPrintf("imageSize: %i x %i (n=%i) (startTime: %7.5f endTime: %7.5f)\n",gImageWidth,gImageHeight,nImages,*(gImageTimes.begin()),*(gImageTimes.end()-1));

      // allocate buffer for return array of images
      plhs[0] = mxCreateNumericMatrix(imageSize,nImages,mxUINT8_CLASS,mxREAL);

      // return size of images
      plhs[1] = mxCreateDoubleScalar(gImageWidth);
      plhs[2] = mxCreateDoubleScalar(gImageHeight);

      // and array of image times
      plhs[3] = mxCreateDoubleMatrix(1,nImages,mxREAL);

      // cycle through images and return into matrix
      // get pointer (matlab claims that this is no longer a good way to get
      // pointers, but the function mxSetUint8s does not compile for me
      // and also doesn't seem to allow updating the pointer, so sticking
      // to what works
      unsigned char *dataPtr = (unsigned char *)(double*)mxGetPr(plhs[0]);
      double *timePtr = (double*)mxGetPr(plhs[3]);

      // fill the matlab pointer with images
      for (unsigned int imageCnt = 0; imageCnt < nImages; imageCnt++) {
	// copy image
      	memcpy(dataPtr+imageCnt*imageSize,gImages[imageCnt]->GetData(),imageSize);
	// copy time stamp
	*(timePtr+imageCnt) = *(gImageTimes.begin()+imageCnt);
      }

      // clear the image vector
      gImages.clear();

      // unlock the mutex
      pthread_mutex_unlock(&gMutex);
    }
  }
  // QUIT command -----------------------------------------------------------------
  else if (command == QUIT) {
    // return argument set to 0
    plhs[0] = mxCreateDoubleScalar(0);

    // disable the thread
    if (gCameraThreadInstalled) {

      // display that we started
      mexPrintf("(mglPrivateCameraThread) Quitting running camera thread\n");

      // lock the pthread mutex
      pthread_mutex_lock(&gMutex);
 
      // set flag to stop loop
      gCommand = QUIT;

      // unlock the mutex
      pthread_mutex_unlock(&gMutex);
    }
  }
}

/////////////////////
//   cameraThread   //
/////////////////////
void* cameraThread(void *data)
{
  int i = 0;
  
  // number of images to grab and camera to grab from
  unsigned int numImages = 100;
  unsigned int cameraNum = 1;

  // Retrieve singleton reference to system object
  SystemPtr system = System::GetInstance();

  // Retrieve list of cameras from the system
  CameraList camList = system->GetCameras();
  unsigned int numCameras = camList.GetSize();

  // Finish if there are no cameras
  if ((numCameras == 0) || (numCameras < cameraNum)) {

    // Clear camera list before releasing system
    camList.Clear();

    // Release system
    system->ReleaseInstance();

    // Print out error
    if (numCameras == 0)
      cout << "(mglPriavateCameraCapture) No cameras found." << endl;
    else
      cout << "(mglPriavateCameraCapture) Found " << numCameras << " cameras: Camera " << cameraNum << " out of range." << endl;

    // return empty
    return NULL;
  }

  // Set up pointer to camera
  CameraPtr pCam = camList.GetByIndex(cameraNum-1);

  // nodeMap
  try{
    // Initialize camera
    pCam->Init();
    // Retrieve GenICam nodemap
    INodeMap &nodeMap = pCam->GetNodeMap();
  
    // image info pointers
    unsigned int stopCameraThread = FALSE;
    int err;

    // loop here waiting for commands
    while (!stopCameraThread) {

      // lock mutex
      pthread_mutex_lock(&gMutex);

      // check commands
      if (gCommand == CAPTURE) {
	// capture images
	err = AcquireImages(pCam, numImages, nodeMap, gImages, gImageTimes);

	// get image size
	gImageWidth = gImages[0]->GetWidth();
	gImageHeight = gImages[0]->GetHeight();
      }
      else if (gCommand == QUIT) {
	// stop the thread
	stopCameraThread = TRUE;
	gCommand = NOCOMMAND;

	// drop out of loop
	continue;
      }

      // set command back to NOCOMMAND
      gCommand = NOCOMMAND;

      // unlock mutex
      pthread_mutex_unlock(&gMutex);
    }
  }
  catch (Spinnaker::Exception& e) {
    cout << "(mglPrivateCameraThread) Error: " << e.what() << endl;
  }
  
  // Clear camera list before releasing system
  camList.Clear();

  // Deinitialize camera
  pCam->DeInit();

  // Release system
  //system->ReleaseInstance();
  mexPrintf("FIX: Why does releasing system cause crash?");
  
  mexPrintf("(mglPrivateCameraThread) Ending thread\n");

  // set flag to uninstalled
  gCameraThreadInstalled = FALSE;

  // unlock mutex
  pthread_mutex_unlock(&gMutex);
  // destroy mutex
  pthread_mutex_destroy(&gMutex);
  return NULL;
}

//////////////////////////////////////
//   mglPrivateCameraThreadOnExit   //
//////////////////////////////////////
void mglPrivateCameraThreadOnExit()
{
  // call mglSwitchDisplay with -1 to close all open screens
  //  mxArray *callInput =  mxCreateDoubleMatrix(1,1,mxREAL);
  //  *(double*)mxGetPr(callInput) = 0;
  //  mexCallMATLAB(0,NULL,1,&callInput,"mglListener");
}


//////////////////////////
//   startCameraThread  //
//////////////////////////
void startCameraThread()
{
  // Create the thread using POSIX routines.
  pthread_attr_t  attr;
  pthread_t       posixThreadID;

  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

  int threadError = pthread_create(&posixThreadID, &attr, &cameraThread, NULL);

  pthread_attr_destroy(&attr);
  if (threadError != 0)
    mexPrintf("(mglPrivateCameraThread) Error could not setup camera thread: error %i\n",threadError);
}


///////////////////////
//   AcquireImages   //
///////////////////////
// This function acquires and saves 10 images from a device; please see
// Acquisition example for more in-depth comments on acquiring images.
int AcquireImages(CameraPtr pCam, unsigned int numImages, INodeMap& nodeMap, vector<ImagePtr>& images, vector<double>& imageTimes)
{
    int result = 0;

    try
    {
        // Set acquisition mode to continuous
        CEnumerationPtr ptrAcquisitionMode = nodeMap.GetNode("AcquisitionMode");
        if (!IsAvailable(ptrAcquisitionMode) || !IsWritable(ptrAcquisitionMode))
        {
            cout << "(mglPrivateCameraThread) Unable to set acquisition mode to continuous (node retrieval). Aborting..." << endl << endl;
            return -1;
        }
        CEnumEntryPtr ptrAcquisitionModeContinuous = ptrAcquisitionMode->GetEntryByName("Continuous");
        if (!IsAvailable(ptrAcquisitionModeContinuous) || !IsReadable(ptrAcquisitionModeContinuous))
        {
            cout << "(mglPrivateCameraThread) Unable to set acquisition mode to continuous (entry 'continuous' retrieval). Aborting..." << endl
                 << endl;
            return -1;
        }
        int64_t acquisitionModeContinuous = ptrAcquisitionModeContinuous->GetValue();
        ptrAcquisitionMode->SetIntValue(acquisitionModeContinuous);

        // Begin acquiring images
        pCam->BeginAcquisition();

	double currentTime = getCurrentTimeInSeconds();
	cout.precision(10);
	cout << "(mglPrivateCameraThread) Starting capture of " << numImages << " images: " <<  currentTime << endl;
        // Retrieve and convert images
        const unsigned int k_numImages = numImages;
        for (unsigned int imageCnt = 0; imageCnt < k_numImages; imageCnt++)
        {
            // Retrieve the next received image
	    currentTime = getCurrentTimeInSeconds();
            ImagePtr pResultImage = pCam->GetNextImage();
            try
            {
                if (pResultImage->IsIncomplete())
                {
		  cout << "(mglPrivateCameraThread) Image incomplete with image status " << pResultImage->GetImageStatus() << "..." << endl;
                }
                else
                {
		  // record time
		  imageTimes.push_back(currentTime);
		  // Deep copy image into image vector
		  images.push_back(pResultImage->Convert(PixelFormat_Mono8, HQ_LINEAR));
                }
            }
            catch (Spinnaker::Exception& e)
            {
                cout << "(mglPrivateCameraThread) Error: " << e.what() << endl;
                result = -1;
            }
            // Release image
            pResultImage->Release();
        }
        // End acquisition
        pCam->EndAcquisition();
	cout << "(mglPrivateCameraThread) Capture of " << k_numImages << " images finished" << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "(mglPrivateCameraThread) Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}

////////////////////////
//   getCurrentTime   //
////////////////////////
double getCurrentTimeInSeconds()
{
#ifdef __MAC_10_8
  static const double kOneBillion = 1000 * 1000 * 1000; 
  static mach_timebase_info_data_t sTimebaseInfo;

  if (sTimebaseInfo.denom == 0) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  // This seems to work on Mac OS 10.9 with a Mac PRO. But note that sTimebaseInfo is hardware implementation
  // dependent. The mach_absolute_time is ticks since the machine started and to convert it to ms you
  // multiply by the fraction in sTimebaseInfo - worried that this could possibly overflow the
  // 64 bit int values depending on what is actually returned. Maybe that is not a problem
  return((double)((mach_absolute_time()*(uint64_t)(sTimebaseInfo.numer)/(uint64_t)(sTimebaseInfo.denom)))/kOneBillion);
#else
  // get current time
  UnsignedWide currentTime; 
  Microseconds(&currentTime); 

  // convert microseconds to double
  double twoPower32 = 4294967296.0; 
  double doubleValue; 
  
  double upperHalf = (double)currentTime.hi; 
  double lowerHalf = (double)currentTime.lo; 
  doubleValue = (upperHalf * twoPower32) + lowerHalf; 
  return(0.000001*doubleValue);
#endif
}
