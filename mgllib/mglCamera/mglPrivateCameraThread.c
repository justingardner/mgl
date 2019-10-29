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
#include "SpinVideo.h"
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
using namespace Spinnaker::Video;
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
#define VERBOSE 5
#define SAVEDATA 6

///////////////////////////////
//   function declarations   //
///////////////////////////////
void* cameraThread(void *data);
void startCameraThread();
void mglPrivateCameraThreadOnExit(void);
int AcquireImages(CameraPtr pCam, unsigned int maxImages, double captureUntilTime, INodeMap& nodeMap, vector<ImagePtr>& images, vector<double>& imageTimes, vector<double>& imageExposureTimes, double &startCameraTime, double &startSystemTime, double &endCameraTime, double &endSystemTime);
double getCurrentTimeInSeconds();
int ConfigureChunkData(INodeMap& nodeMap);
int DisplayChunkData(INodeMap& nodeMap);

// FIX: This seems to cause a linkage problem with freetype where ffmpeg wants version 24 but 
// only 18 is available. Not sure what the deal is, so am commenting out the vital code inside
// this function so that it can still complie and run. JG 2019/10/28. To test it, add the following define
//#define TESTVIDEOCODE 1
int SaveVectorToVideo(vector<ImagePtr>& images);

////////////////
//   globals  //
////////////////
static pthread_mutex_t gMutex;
static int gCameraThreadInstalled = FALSE;
static int gCommand = 0;
static int gCameraNum;
static double gCaptureUntilTime = -1;
static int gMaxImages = 100;
static mxArray *gData;
unsigned int gImageWidth, gImageHeight;
double gStartCameraTime,gEndCameraTime,gStartSystemTime,gEndSystemTime;
// Pointer for images
vector<ImagePtr> gImages;
vector<double> gImageTimes;
vector<double> gImageExposureTimes;
unsigned int gVerbose = FALSE;

// Video types
enum videoType
{
    UNCOMPRESSED,
    MJPG,
    H264
};
const videoType chosenVideoType = UNCOMPRESSED;

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

      // get the cameraNum 
      gCameraNum = (int)mxGetScalar(prhs[1]);

      // get the maximum number of images to buffer
      gMaxImages = (int)mxGetScalar(prhs[2]);

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

      // get the time to capture until
      gCaptureUntilTime = (double)mxGetScalar(prhs[1]);

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
  // Set verbose command -----------------------------------------------------------------
  else if (command == VERBOSE) {
    gVerbose = (int)mxGetScalar(prhs[1]);
    if (gVerbose)
      mexPrintf("(mglPrivateCameraThread) Setting verbose to: %i\n",gVerbose);
  }
  // Get data command -----------------------------------------------------------------
  else if (command == GETDATA) {
    if (gCameraThreadInstalled) {
      
      // lock the pthread mutex
      pthread_mutex_lock(&gMutex);

      unsigned int imageSize = gImageWidth * gImageHeight;
      unsigned int nImages = gImages.size();
      if (nImages == 0) {
	// report no images 
	mexPrintf("(mglPrivateCameraThread) No images to get\n");
	// set all output arguments to empty
	for (int iOutput = 0; iOutput <= 9; iOutput++) 
	  plhs[iOutput] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
      else {
	// report how many images
	mexPrintf("(mglPrivateCameraThread) Received %i images (%i x %i)\n",nImages,gImageWidth,gImageHeight);

	// allocate buffer for return array of images
	plhs[0] = mxCreateNumericMatrix(imageSize,nImages,mxUINT8_CLASS,mxREAL);

	// return size of images
	plhs[1] = mxCreateDoubleScalar(gImageWidth);
	plhs[2] = mxCreateDoubleScalar(gImageHeight);

	// and array of image times
	plhs[3] = mxCreateDoubleMatrix(1,nImages,mxREAL);

	// camera start and end time
	plhs[4] = mxCreateDoubleScalar(gStartCameraTime);
	plhs[5] = mxCreateDoubleScalar(gEndCameraTime);
	plhs[6] = mxCreateDoubleScalar(gStartSystemTime);
	plhs[7] = mxCreateDoubleScalar(gEndSystemTime);

	// and array of exposure times
	plhs[8] = mxCreateDoubleMatrix(1,nImages,mxREAL);

	// cycle through images and return into matrix
	// get pointer (matlab claims that this is no longer a good way to get
	// pointers, but the function mxSetUint8s does not compile for me
	// and also doesn't seem to allow updating the pointer, so sticking
	// to what works
	unsigned char *dataPtr = (unsigned char *)(double*)mxGetPr(plhs[0]);
	double *timePtr = (double*)mxGetPr(plhs[3]);
	double *exposureTimePtr = (double*)mxGetPr(plhs[8]);

	// fill the matlab pointer with images
	for (unsigned int imageCnt = 0; imageCnt < nImages; imageCnt++) {
	  // copy image
	  memcpy(dataPtr+imageCnt*imageSize,gImages[imageCnt]->GetData(),imageSize);
	  // copy time stamp
	  *(timePtr+imageCnt) = *(gImageTimes.begin()+imageCnt);
	  // copy time exposure time
	  *(exposureTimePtr+imageCnt) = *(gImageExposureTimes.begin()+imageCnt);
	}
      }
      // clear the image and time vector
      gImages.clear();
      gImageTimes.clear();
      gImageExposureTimes.clear();

      // unlock the mutex
      pthread_mutex_unlock(&gMutex);
    }
  }
  // Get data command -----------------------------------------------------------------
  else if (command == SAVEDATA) {
    if (gCameraThreadInstalled) {
      
      // lock the pthread mutex
      pthread_mutex_lock(&gMutex);

      unsigned int imageSize = gImageWidth * gImageHeight;
      unsigned int nImages = gImages.size();
      if (nImages == 0) {
	// report no images 
	mexPrintf("(mglPrivateCameraThread) No images to save\n");
	// set output to empty
	plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
      }
      else {
	// report how many images
	mexPrintf("(mglPrivateCameraThread) Received %i images (%i x %i)\n",nImages,gImageWidth,gImageHeight);

	// JG: FIX, Not tested yet - linkage problem see above
	SaveVectorToVideo(gImages);
      }
      // clear the image and time vector
      gImages.clear();
      gImageTimes.clear();
      gImageExposureTimes.clear();

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

  // Retrieve singleton reference to system object
  SystemPtr system = System::GetInstance();

  // Retrieve list of cameras from the system
  CameraList camList = system->GetCameras();
  unsigned int numCameras = camList.GetSize();

  // Finish if there are no cameras
  if ((numCameras == 0) || (numCameras < gCameraNum)) {

    // Clear camera list before releasing system
    camList.Clear();

    // Release system
    system->ReleaseInstance();

    // Print out error
    if (numCameras == 0)
      cout << "(mglPriavateCameraCapture) No cameras found." << endl;
    else
      cout << "(mglPriavateCameraCapture) Found " << numCameras << " cameras: Camera " << gCameraNum << " out of range." << endl;

    // return empty
    return NULL;
  }

  // display what we are doing
  cout << "(mglPriavateCameraCapture) Found " << numCameras << " cameras: Initializing camera " << gCameraNum << endl;

  // Set up pointer to camera
  CameraPtr pCam = camList.GetByIndex(gCameraNum-1);

  // nodeMap
  try{
    // Initialize camera
    pCam->Init();
    // Retrieve GenICam nodemap
    INodeMap &nodeMap = pCam->GetNodeMap();
  
    // Configure chunk data
    ConfigureChunkData(nodeMap);

    // display what we are doing
    cout << "(mglPriavateCameraCapture) Ready and waiting for commands" << endl;

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
	err = AcquireImages(pCam, gMaxImages, gCaptureUntilTime, nodeMap, gImages, gImageTimes, gImageExposureTimes, gStartCameraTime, gStartSystemTime, gEndCameraTime, gEndSystemTime);

	// if error then act as if there are no images in buffer
	if (err == -1) {
	  // clear the gImages buffer
	  gImages.clear();
	}
	else {
	  // get image size
	  gImageWidth = gImages[0]->GetWidth();
	  gImageHeight = gImages[0]->GetHeight();
	}

      }
      else if (gCommand == QUIT) {
	// stop the thread
	stopCameraThread = TRUE;
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
  
  // lock mutex
  pthread_mutex_lock(&gMutex);

  // Clear camera list before releasing system
  camList.Clear();

  // Deinitialize camera
  pCam->DeInit();
  pCam = nullptr;

  // Release system
  system->ReleaseInstance();
  
  // say that wer are ending
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

int64_t getCameraTimestamp(CameraPtr pCam)
{
  CCommandPtr ptrTimestampLatch = pCam->GetNodeMap().GetNode("TimestampLatch");
  if (!IsAvailable(ptrTimestampLatch))
    {
      cout << " Unable to retreive Time Stamp Latch (node retrieval). Aborting..."<< endl;
      return -1;
    }
  
  ptrTimestampLatch->Execute();
  
  CIntegerPtr ptrTimestampLatchValue = pCam->GetNodeMap().GetNode("TimestampLatchValue");
  if (!IsAvailable(ptrTimestampLatchValue) || !IsReadable(ptrTimestampLatchValue))
    {
      cout << " Unable to read Time Stamp Latch Value (node retrieval). Aborting.." << endl;
      return -1;
    }
	
  // return timestamp
  int64_t timestampLatchValue = ptrTimestampLatchValue->GetValue();
  return(timestampLatchValue);
}


///////////////////////
//   AcquireImages   //
///////////////////////
// This function acquires and saves 10 images from a device; please see
// Acquisition example for more in-depth comments on acquiring images.
int AcquireImages(CameraPtr pCam, unsigned int maxImages, double captureUntilTime, INodeMap& nodeMap, vector<ImagePtr>& images, vector<double>& imageTimes, vector<double>& imageExposureTimes, double &startCameraTime, double &startSystemTime, double &endCameraTime, double &endSystemTime)
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

	// get current time
	double currentTime = getCurrentTimeInSeconds();

	// log beginning camera and system time
	startCameraTime = getCameraTimestamp(pCam);
	startSystemTime = getCurrentTimeInSeconds();
	// averaging time from before and after getting system time to try to be more accurate
	startCameraTime = (getCameraTimestamp(pCam)+startCameraTime)/2;

	cout.precision(12);
	cout << "(mglPrivateCameraThread) Starting capture for " << captureUntilTime-currentTime << "s or until " << maxImages << " images are acquired." << endl;

        // Retrieve and convert images
	while((currentTime < captureUntilTime) && (images.size() < maxImages))
        {
            // Retrieve the next received image
	    currentTime = getCurrentTimeInSeconds();

            ImagePtr pResultImage = pCam->GetNextImage();
            try {
	      if (pResultImage->IsIncomplete()) {
		cout << "(mglPrivateCameraThread) Image incomplete with image status " << pResultImage->GetImageStatus() << "..." << endl;
	      }
	      else {
		// get fields from chunk data
		ChunkData  chunkData = pResultImage->GetChunkData();
		double timestamp = static_cast<double>(chunkData.GetTimestamp());
		double exposureTime = static_cast<double>(chunkData.GetExposureTime());
		// record time
		imageTimes.push_back(timestamp-exposureTime);

		// record exposure
		imageExposureTimes.push_back(exposureTime);
		// Deep copy image into image vector
		images.push_back(pResultImage->Convert(PixelFormat_Mono8, HQ_LINEAR));
	      }
            }
            catch (Spinnaker::Exception& e) {
	      cout << "(mglPrivateCameraThread) Error: " << e.what() << endl;
	      result = -1;
            }
            // Release image
            pResultImage->Release();
        }
        // End acquisition
        pCam->EndAcquisition();
	cout  << "(mglPrivateCameraThread) Capture of " << images.size() << " images finished." << endl;
	// log end camera and system time
	endCameraTime = getCameraTimestamp(pCam);
	endSystemTime = getCurrentTimeInSeconds();
	// averaging time from before and after getting system time to try to be more accurate
	endCameraTime = (getCameraTimestamp(pCam)+endCameraTime)/2;
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

// This function configures the camera to add chunk data to each image. It does
// this by enabling each type of chunk data before enabling chunk data mode.
// When chunk data is turned on, the data is made available in both the nodemap
// and each image.
int ConfigureChunkData(INodeMap& nodeMap)
{
    int result = 0;
    if (gVerbose)
      cout << endl << endl << "*** CONFIGURING CHUNK DATA ***" << endl << endl;

    try
    {
        //
        // Activate chunk mode
        //
        // *** NOTES ***
        // Once enabled, chunk data will be available at the end of the payload
        // of every image captured until it is disabled. Chunk data can also be
        // retrieved from the nodemap.
        //
        CBooleanPtr ptrChunkModeActive = nodeMap.GetNode("ChunkModeActive");
        if (!IsAvailable(ptrChunkModeActive) || !IsWritable(ptrChunkModeActive))
        {
            cout << "Unable to activate chunk mode. Aborting..." << endl << endl;
            return -1;
        }
        ptrChunkModeActive->SetValue(true);
	if (gVerbose)
	  cout << "Chunk mode activated..." << endl;
        //
        // Enable all types of chunk data
        //
        // *** NOTES ***
        // Enabling chunk data requires working with nodes: "ChunkSelector"
        // is an enumeration selector node and "ChunkEnable" is a boolean. It
        // requires retrieving the selector node (which is of enumeration node
        // type), selecting the entry of the chunk data to be enabled, retrieving
        // the corresponding boolean, and setting it to true.
        //
        // In this example, all chunk data is enabled, so these steps are
        // performed in a loop. Once this is complete, chunk mode still needs to
        // be activated.
        //
        NodeList_t entries;
        // Retrieve the selector node
        CEnumerationPtr ptrChunkSelector = nodeMap.GetNode("ChunkSelector");
        if (!IsAvailable(ptrChunkSelector) || !IsReadable(ptrChunkSelector))
        {
            cout << "Unable to retrieve chunk selector. Aborting..." << endl << endl;
            return -1;
        }
        // Retrieve entries
        ptrChunkSelector->GetEntries(entries);
	if (gVerbose)
	  cout << "Enabling entries..." << endl;
        for (size_t i = 0; i < entries.size(); i++)
        {
            // Select entry to be enabled
            CEnumEntryPtr ptrChunkSelectorEntry = entries.at(i);
            // Go to next node if problem occurs
            if (!IsAvailable(ptrChunkSelectorEntry) || !IsReadable(ptrChunkSelectorEntry))
            {
                continue;
            }
            ptrChunkSelector->SetIntValue(ptrChunkSelectorEntry->GetValue());
	    if (gVerbose)
	      cout << "\t" << ptrChunkSelectorEntry->GetSymbolic() << ": ";
            // Retrieve corresponding boolean
            CBooleanPtr ptrChunkEnable = nodeMap.GetNode("ChunkEnable");
            // Enable the boolean, thus enabling the corresponding chunk data
            if (!IsAvailable(ptrChunkEnable))
            {
	      if (gVerbose)
                cout << "not available" << endl;
                result = -1;
            }
            else if (ptrChunkEnable->GetValue())
            {
	      if (gVerbose)
                cout << "enabled" << endl;
            }
            else if (IsWritable(ptrChunkEnable))
            {
                ptrChunkEnable->SetValue(true);
		if (gVerbose)
		  cout << "enabled" << endl;
            }
            else
            {
	      if (gVerbose)
                cout << "not writable" << endl;
                result = -1;
            }
        }
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}

// This function displays all available chunk data by looping through the chunk
// data category node on the nodemap.
int DisplayChunkData(INodeMap& nodeMap)
{
    int result = 0;
    cout << "Printing chunk data from nodemap..." << endl;
    try
    {
        //
        // Retrieve chunk data information nodes
        //
        // *** NOTES ***
        // As well as being written into the payload of the image, chunk data is
        // accessible on the GenICam nodemap. Insofar as chunk data is enabled,
        // it is available from both sources.
        //
        CCategoryPtr ptrChunkDataControl = nodeMap.GetNode("ChunkDataControl");
        if (!IsAvailable(ptrChunkDataControl) || !IsReadable(ptrChunkDataControl))
        {
            cout << "Unable to retrieve chunk data control. Aborting..." << endl << endl;
            return -1;
        }
        FeatureList_t features;
        ptrChunkDataControl->GetFeatures(features);
        // Iterate through children
        FeatureList_t::const_iterator it;
        for (it = features.begin(); it != features.end(); ++it)
        {
            CNodePtr pFeature = (CNodePtr)*it;
            cout << "\t" << pFeature->GetDisplayName() << ": ";
            if (!IsAvailable(pFeature) || !IsReadable(pFeature))
            {
                cout << "node not available" << endl;
                result = result | -1;
                continue;
            }
            //
            // Print boolean node type value
            //
            // *** NOTES ***
            // Boolean information is manipulated to output the more-easily
            // identifiable 'true' and 'false' as opposed to '1' and '0'.
            //
            else if (pFeature->GetPrincipalInterfaceType() == intfIBoolean)
            {
                CBooleanPtr pBool = (CBooleanPtr)pFeature;
                bool value = pBool->GetValue();
                cout << (value ? "true" : "false") << endl;
            }
            //
            // Print non-boolean node type value
            //
            // *** NOTES ***
            // All nodes can be cast as value nodes and have their information
            // retrieved as a string using the ToString() method. This is much
            // easier than dealing with each node type individually.
            //
            else
            {
                CValuePtr pValue = (CValuePtr)pFeature;
                cout << pValue->ToString() << endl;
            }
        }
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}

///////////////////////////
//   SaveVectorToVideo   //
///////////////////////////
// This function prepares, saves, and cleans up an video from a vector of images.
int SaveVectorToVideo(vector<ImagePtr>& images)
{
    int result = 0;

#ifdef TESTVIDEOCODE
    cout << endl << endl << "*** CREATING VIDEO ***" << endl << endl;
    try
    {
        // Create a unique filename
        //
        // *** NOTES ***
        // This example creates filenames according to the type of video
        // being created. Notice that '.avi' does not need to be appended to the
        // name of the file. This is because the SpinVideo object takes care
        // of the file extension automatically.
        //
        string videoFilename;
        switch (chosenVideoType)
        {
        case UNCOMPRESSED:
            videoFilename = "SaveToAvi-Uncompressed";
            break;
        case MJPG:
            videoFilename = "SaveToAvi-MJPG";
            break;
        case H264:
            videoFilename = "SaveToAvi-H264";
        }
        //
        // Select option and open video file type
        //
        // *** NOTES ***
        // Depending on the file type, a number of settings need to be set in
        // an object called an option. An uncompressed option only needs to
        // have the video frame rate set whereas videos with MJPG or H264
        // compressions should have more values set.
        //
        // Once the desired option object is configured, open the video file
        // with the option in order to create the video file.
        //
        // *** LATER ***
        // Once all images have been added, it is important to close the file -
        // this is similar to many other standard file streams.
        //
        SpinVideo video;
	unsigned int frameRateToSet = 20;
        // Set maximum video file size to 2GB.
        // A new video file is generated when 2GB
        // limit is reached. Setting maximum file
        // size to 0 indicates no limit.
        const unsigned int k_videoFileSize = 2048;
        video.SetMaximumFileSize(k_videoFileSize);
        if (chosenVideoType == UNCOMPRESSED)
        {
            Video::AVIOption option;
            option.frameRate = frameRateToSet;
            video.Open(videoFilename.c_str(), option);
        }
        else if (chosenVideoType == MJPG)
        {
            Video::MJPGOption option;
            option.frameRate = frameRateToSet;
            option.quality = 75;
            video.Open(videoFilename.c_str(), option);
        }
        else if (chosenVideoType == H264)
        {
            Video::H264Option option;
            option.frameRate = frameRateToSet;
            option.bitrate = 1000000;
            option.height = static_cast<unsigned int>(images[0]->GetHeight());
            option.width = static_cast<unsigned int>(images[0]->GetWidth());
            video.Open(videoFilename.c_str(), option);
        }
        //
        // Construct and save video
        //
        // *** NOTES ***
        // Although the video file has been opened, images must be individually
        // appended in order to construct the video.
        //
        cout << "Appending " << images.size() << " images to video file: " << videoFilename << ".avi... " << endl
             << endl;
        for (unsigned int imageCnt = 0; imageCnt < images.size(); imageCnt++)
        {
            video.Append(images[imageCnt]);
            cout << "\tAppended image " << imageCnt << "..." << endl;
        }
        //
        // Close video file
        //
        // *** NOTES ***
        // Once all images have been appended, it is important to close the
        // video file. Notice that once an video file has been closed, no more
        // images can be added.
        //
        video.Close();
        cout << endl << "Video saved at " << videoFilename << ".avi" << endl << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
#endif
    return result;
}
