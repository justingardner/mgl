#ifdef documentation
=========================================================================

  program: mglPrivateCameraCapture.c
       by: justin gardner
     date: 10/05/2019
copyright: (c) 2019 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose: mex function to capture images from an FLIR camera
           adapted from Acquisition

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
//#include "../mgl.h"
#include "Spinnaker.h"
#include "SpinGenApi/SpinnakerGenApi.h"
#include <iostream>
#include <sstream>
#include <mex.h>
#include "matrix.h"

using namespace Spinnaker;
using namespace Spinnaker::GenApi;
using namespace Spinnaker::GenICam;
using namespace std;

///////////////////////////////
//   function declarations   //
///////////////////////////////

////////////////////////
//   define section   //
////////////////////////

// This function prints the device information of the camera from the transport
// layer; please see NodeMapInfo example for more in-depth comments on printing
// device information from the nodemap.
int PrintDeviceInfo(INodeMap& nodeMap)
{
    int result = 0;
    cout << endl << "*** DEVICE INFORMATION ***" << endl << endl;
    try
    {
        FeatureList_t features;
        CCategoryPtr category = nodeMap.GetNode("DeviceInformation");
        if (IsAvailable(category) && IsReadable(category))
        {
            category->GetFeatures(features);
            FeatureList_t::const_iterator it;
            for (it = features.begin(); it != features.end(); ++it)
            {
                CNodePtr pfeatureNode = *it;
                cout << pfeatureNode->GetName() << " : ";
                CValuePtr pValue = (CValuePtr)pfeatureNode;
                cout << (IsReadable(pValue) ? pValue->ToString() : "Node not readable");
                cout << endl;
            }
        }
        else
        {
            cout << "Device control information not available." << endl;
        }
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function acquires and saves 10 images from a device; please see
// Acquisition example for more in-depth comments on acquiring images.
int AcquireImages(CameraPtr pCam, unsigned int numImages, INodeMap& nodeMap, vector<ImagePtr>& images)
{
    int result = 0;
    cout << endl << endl << "*** IMAGE ACQUISITION ***" << endl << endl;
    try
    {
        // Set acquisition mode to continuous
        CEnumerationPtr ptrAcquisitionMode = nodeMap.GetNode("AcquisitionMode");
        if (!IsAvailable(ptrAcquisitionMode) || !IsWritable(ptrAcquisitionMode))
        {
            cout << "Unable to set acquisition mode to continuous (node retrieval). Aborting..." << endl << endl;
            return -1;
        }
        CEnumEntryPtr ptrAcquisitionModeContinuous = ptrAcquisitionMode->GetEntryByName("Continuous");
        if (!IsAvailable(ptrAcquisitionModeContinuous) || !IsReadable(ptrAcquisitionModeContinuous))
        {
            cout << "Unable to set acquisition mode to continuous (entry 'continuous' retrieval). Aborting..." << endl
                 << endl;
            return -1;
        }
        int64_t acquisitionModeContinuous = ptrAcquisitionModeContinuous->GetValue();
        ptrAcquisitionMode->SetIntValue(acquisitionModeContinuous);
        cout << "Acquisition mode set to continuous..." << endl;
        // Begin acquiring images
        pCam->BeginAcquisition();
        cout << "Acquiring images..." << endl << endl;
        // Retrieve and convert images
        const unsigned int k_numImages = numImages;
        for (unsigned int imageCnt = 0; imageCnt < k_numImages; imageCnt++)
        {
            // Retrieve the next received image
            ImagePtr pResultImage = pCam->GetNextImage();
            try
            {
                if (pResultImage->IsIncomplete())
                {
                    cout << "Image incomplete with image status " << pResultImage->GetImageStatus() << "..." << endl
                         << endl;
                }
                else
                {
                    cout << "Grabbed image " << imageCnt << ", width = " << pResultImage->GetWidth()
                         << ", height = " << pResultImage->GetHeight() << endl;
                    // Deep copy image into image vector
                    images.push_back(pResultImage->Convert(PixelFormat_Mono8, HQ_LINEAR));
                }
            }
            catch (Spinnaker::Exception& e)
            {
                cout << "Error: " << e.what() << endl;
                result = -1;
            }
            // Release image
            pResultImage->Release();
        }
        // End acquisition
        pCam->EndAcquisition();
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function acts as the body of the example; please see NodeMapInfo example
// for more in-depth comments on setting up cameras.
mxArray *RunSingleCamera(CameraPtr pCam, unsigned int numImages, unsigned int *imageWidth, unsigned int *imageHeight)
{
    int result = 0;
    int err = 0;
    try
    {
        // Retrieve TL device nodemap and print device information
        INodeMap& nodeMapTLDevice = pCam->GetTLDeviceNodeMap();
        result = PrintDeviceInfo(nodeMapTLDevice);
        // Initialize camera
        pCam->Init();
        // Retrieve GenICam nodemap
        INodeMap& nodeMap = pCam->GetNodeMap();
        // Acquire images and save into vector
        vector<ImagePtr> images;
        err = AcquireImages(pCam, numImages, nodeMap, images);
        if (err < 0)
        {
	  return(mxCreateDoubleScalar(31));
        }
        // Save vector of images to video
	//        result = result | SaveVectorToVideo(nodeMap, nodeMapTLDevice, images);

	// get image size
	*imageWidth = images[0]->GetWidth();
	*imageHeight = images[0]->GetHeight();
	unsigned int imageSize = (*imageWidth) * (*imageHeight);

	// allocate buffer for return array
	mxArray *retval = mxCreateNumericMatrix(imageSize,images.size(),mxUINT8_CLASS,mxREAL);
	// cycle through images and return into matrix
	// get pointer (matlab claims that this is no longer a good way to get
	// pointers, but the function mxSetUint8s does not compile for me
	// and also doesn't seem to allow updating the pointer, so sticking
	// to what works
	unsigned char *dataPtr = (unsigned char *)(double*)mxGetPr(retval);

	// fill the matlab pointer with images
        for (unsigned int imageCnt = 0; imageCnt < images.size(); imageCnt++) {
	  memcpy(dataPtr+imageCnt*imageSize,images[imageCnt]->GetData(),imageSize);
	}

        // Deinitialize camera
        pCam->DeInit();
	return(retval);
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return(mxCreateDoubleScalar(32));

}
// Example entry point; please see Enumeration example for more in-depth
// comments on preparing and cleaning up the system.
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // number of images to grab and camera to grab from
    unsigned int numImages = 1;
    unsigned int cameraNum = 1;

    // if passed in, get camera number
    if (nrhs > 0)
      cameraNum = (unsigned int)*(double*)mxGetPr(prhs[0]);
      
    // if passed in, get number of images
    if (nrhs > 1)
      numImages = (unsigned int)*(double*)mxGetPr(prhs[1]);

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
	plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
	plhs[1] = mxCreateDoubleMatrix(0,0,mxREAL);
	plhs[2] = mxCreateDoubleMatrix(0,0,mxREAL);
        return;
    }


    // Get images
    unsigned int imageWidth, imageHeight;
    plhs[0] = RunSingleCamera(camList.GetByIndex(cameraNum-1),numImages,&imageWidth,&imageHeight);

    // and the width and height
    plhs[1] = mxCreateDoubleScalar(imageWidth);
    plhs[2] = mxCreateDoubleScalar(imageHeight);

    // Clear camera list before releasing system
    camList.Clear();

    // Release system
    system->ReleaseInstance();

    return;
}
