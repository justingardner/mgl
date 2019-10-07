#ifdef documentation
=========================================================================

  program: mglPrivateCameraInfo.c
       by: justin gardner
     date: 10/05/2019
copyright: (c) 2019 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose: mex function to get information from an FLIR camera
           adapted from NodeMapInfo_C

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
// Include SpinnakerC.h
// Need to temporarily redfine Boolean because
// it is already defined in another head
#define Boolean BooleanMustNotBeDefinedTwice
#include "SpinnakerC.h"
#undef Boolean
#include "stdio.h"
#include "string.h"

///////////////////////////////
//   function declarations   //
///////////////////////////////
mxArray *getSingleCameraInfo(spinCamera, spinError *);
mxArray *getCategoryNodeAndAllFeatures(spinNodeHandle , unsigned int, spinError *);

////////////////////////
//   define section   //
////////////////////////
// This macro helps with C-strings.
#define MAX_BUFF_LEN 1024
// This macro defines the maximum number of characters that will be printed out
// for any information retrieved from a node.
#define MAX_CHARS 35

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  if (nrhs > 2) {
    usageError("mglCameraInfo");
  }

  // return variable fields
  const char *fieldNames[] = {"spinnakerLibraryVersion","nCameras","info"};
  const int numFields = 3;
  const int outDims[2] = {1, 1};

  // define error values
  spinError errReturn = SPINNAKER_ERR_SUCCESS;
  spinError err = SPINNAKER_ERR_SUCCESS;
  unsigned int i = 0;

  // Retrieve singleton reference to system object
  spinSystem hSystem = NULL;

  // Get stystems intance
  err = spinSystemGetInstance(&hSystem);
  if (err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("(mglPrivateCameraInfo) Unable to retrieve system instance. Aborting with error %d\n", err);
    return;
  }

  // Get Library version
  spinLibraryVersion hLibraryVersion;
  spinSystemGetLibraryVersion(hSystem, &hLibraryVersion);

  // return info as a struct
  // create the output structure
  // return variable fields
  plhs[0] = mxCreateStructArray(1,outDims,numFields,fieldNames);

  // set fields for spinnaker library version
  mxSetField(plhs[0],0,"spinnakerLibraryVersion",mxCreateDoubleMatrix(1,4,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"spinnakerLibraryVersion")) = (double)hLibraryVersion.major;
  *((double *)mxGetPr(mxGetField(plhs[0],0,"spinnakerLibraryVersion"))+1) = (double)hLibraryVersion.minor;
  *((double *)mxGetPr(mxGetField(plhs[0],0,"spinnakerLibraryVersion"))+2) = (double)hLibraryVersion.type;
  *((double *)mxGetPr(mxGetField(plhs[0],0,"spinnakerLibraryVersion"))+3) = (double)hLibraryVersion.build;

  // Retrieve list of cameras from the system
  spinCameraList hCameraList = NULL;
  err = spinCameraListCreateEmpty(&hCameraList);
  if (err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("(mglPrivateCameraInfo) Unable to create camera list. Aborting with error %d...\n", err);
    return;
  }

  err = spinSystemGetCameras(hSystem, hCameraList);
  if (err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("(mglPrivateCameraInfo) Unable to retrieve camera list. Aborting with error %d...\n\n", err);
    return;
  }

  // Retrieve number of cameras
  size_t numCameras = 0;
  err = spinCameraListGetSize(hCameraList, &numCameras);
  if (err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("(mglPrivateCameraInfo) Unable to retrieve number of cameras. Aborting with error %d...\n", err);
    return;
  }
  
  // set number of cameras
  mxSetField(plhs[0],0,"nCameras",mxCreateDoubleMatrix(1,1,mxREAL));
  *(double *)mxGetPr(mxGetField(plhs[0],0,"nCameras")) = (double)numCameras;

  // Finish if there are no cameras
  if (numCameras == 0) {
    // Clear and destroy camera list before releasing system
    err = spinCameraListClear(hCameraList);
    if (err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo) Unable to clear camera list. Aborting with error %d...\n", err);
      return;
    }

    err = spinCameraListDestroy(hCameraList);
    if (err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo) Unable to destroy camera list. Aborting with error %d...\n", err);
      return;
    }

    // Release system
    err = spinSystemReleaseInstance(hSystem);
    if (err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo) Unable to release system instance. Aborting with error %d...\n\n", err);
      return;
    }

    // return when no cameras are found
    return;
  }

  // set the output info to be a cell array of approrpriate length
  mxSetField(plhs[0],0,"info",mxCreateCellArray(1,(const int *)&numCameras));

  // Run example on each camera
  for (i = 0; i < numCameras; i++) {
    // Select camera
    spinCamera hCamera = NULL;

    err = spinCameraListGet(hCameraList, i, &hCamera);
    if (err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo) Unable to retrieve camera from list. Aborting with error %d...\n", err);
      errReturn = err;
    }
    else {
      // Run example
      mxSetCell(mxGetField(plhs[0],0,"info"),i,getSingleCameraInfo(hCamera,&err));;

      if (err != SPINNAKER_ERR_SUCCESS) {
	errReturn = err;
      }
    }

    // Release camera
    err = spinCameraRelease(hCamera);
    if (err != SPINNAKER_ERR_SUCCESS) {
      errReturn = err;
    }

    // Clear and destroy camera list before releasing system
    err = spinCameraListClear(hCameraList);
    if (err != SPINNAKER_ERR_SUCCESS) {
      printf("(mglPrivateCameraInfo) Unable to clear camera list. Aborting with error %d...\n", err);
      return;
    }

    err = spinCameraListDestroy(hCameraList);
    if (err != SPINNAKER_ERR_SUCCESS) {
      printf("(mglPrivateCameraInfo) Unable to destroy camera list. Aborting with error %d...\n\n", err);
      return;
    }

    // Release system
    err = spinSystemReleaseInstance(hSystem);
    if (err != SPINNAKER_ERR_SUCCESS) {
      printf("(mglPrivateCameraInfo) Unable to release system instance. Aborting with error %d...\n\n", err);
      return;
    }
  }
}

/////////////////////////////
//   getSingleCameraInfo   //
/////////////////////////////
// This function acts as the body of the example. First the TL device and
// TL stream nodemaps are retrieved and their nodes printed. Following this,
// the camera is initialized and then the GenICam node is retrieved
// and its nodes printed.
mxArray *getSingleCameraInfo(spinCamera hCam, spinError *err)
{
  *err = SPINNAKER_ERR_SUCCESS;
  unsigned int level = 0;

  //
  // Retrieve TL device nodemap
  //
  // *** NOTES ***
  // The TL device nodemap is available on the transport layer. As such,
  // camera initialization is unnecessary. It provides mostly immutable
  // information fundamental to the camera such as the serial number,
  // vendor, and model.
  //
  
  spinNodeMapHandle hNodeMapTLDevice = NULL;
  spinNodeHandle hTLDeviceRoot = NULL;

  // Retrieve nodemap from camera
  *err = spinCameraGetTLDeviceNodeMap(hCam, &hNodeMapTLDevice);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("(mglPrivateCameraInfo) Unable to retrieve TL device nodemap (nodemap retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }
  mxArray *TLDeviceNodeMap = getCategoryNodeAndAllFeatures(hTLDeviceRoot, level, err);

  // Retrieve root node from nodemap
  *err = spinNodeMapGetNode(hNodeMapTLDevice, "Root", &hTLDeviceRoot);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to print TL device nodemap (root node retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  // Get values recursively
  mxArray *nodeMap = getCategoryNodeAndAllFeatures(hTLDeviceRoot, level, err);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    return mxCreateDoubleMatrix(0,0,0);
  }
  //
  // Retrieve TL stream nodemap
  //
  // *** NOTES ***
  // The TL stream nodemap is also available on the transport layer. Camera
  // initialization is again unnecessary. As you can probably guess, it
  // provides information on the camera's streaming performance at any
  // given moment. Having this information available on the transport
  // layer allows the information to be retrieved without affecting camera
  // performance.
  //
  spinNodeMapHandle hNodeMapStream = NULL;
  spinNodeHandle hStreamRoot = NULL;

  // Retrieve nodemap from camera
  *err = spinCameraGetTLStreamNodeMap(hCam, &hNodeMapStream);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to print TL stream nodemap (nodemap retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  // Retrieve root node from nodemap
  *err = spinNodeMapGetNode(hNodeMapStream, "Root", &hStreamRoot);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to print TL stream nodemap (root node retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  mxArray *streamNode = getCategoryNodeAndAllFeatures(hStreamRoot, level, err);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    return mxCreateDoubleMatrix(0,0,0);
  }

  //
  // Initialize camera
  //
  // *** NOTES ***
  // The camera becomes connected upon initialization. This provides
  // access to configurable options and additional information, accessible
  // through the GenICam nodemap.
  //
  // *** LATER ***
  // Cameras should be deinitialized when no longer needed.
  //
  *err = spinCameraInit(hCam);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to initialize camera. Aborting with error %d...\n", err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  //
  // Retrieve GenICam nodemap
  //
  // *** NOTES ***
  // The GenICam nodemap is the primary gateway to customizing and
  // configuring the camera to suit your needs. Configuration options such
  // as image height and width, trigger mode enabling and disabling, and the
  // sequencer are found on this nodemap.
  //

  spinNodeMapHandle hNodeMap = NULL;
  spinNodeHandle hRoot = NULL;

  // Retrieve nodemap from camera
  *err = spinCameraGetNodeMap(hCam, &hNodeMap);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to print GenICam nodemap (nodemap retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  // Retrieve root node from nodemap
  *err = spinNodeMapGetNode(hNodeMap, "Root", &hRoot);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to print GenICam nodemap (root node retrieval). Aborting with error %d...\n", *err);
    return mxCreateDoubleMatrix(0,0,0);
  }

  //  mxArray *genICamNodeMap = getCategoryNodeAndAllFeatures(hRoot, level, err);
  //  if (*err != SPINNAKER_ERR_SUCCESS) {
  //    return mxCreateDoubleMatrix(0,0,0);
  //  }

  //
  // Deinitialize camera
  //
  // *** NOTES ***
  // Camera deinitialization helps ensure that devices clean up properly
  // and do not need to be power-cycled to maintain integrity.
  //
  *err = spinCameraDeInit(hCam);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    mexPrintf("Unable to deinitialize camera. Non-fatal error %d...\n", err);
  }

  // set fields for return structure
  const char *fieldNames[] = {"TLDeviceNodeMap","nodeMap","streamNode","genICamNodeMap"};
  const int numFields = 4;
  const int outDims[2] = {1, 1};

  // create return structure
  mxArray *retval = mxCreateStructArray(1,outDims,numFields,fieldNames);
  mxSetField(retval,0,"TLDeviceNodeMap",TLDeviceNodeMap);
  mxSetField(retval,0,"nodeMap",nodeMap);
  mxSetField(retval,0,"streamNode",streamNode);
  //  mxSetField(retval,0,"genICamNodeMap",genICamNodeMap);

  // and return it
  return(retval);
}

///////////////////////////////////////
//   getCategoryNodeAndAllFeatures   //
///////////////////////////////////////
// This function retrieves and prints out the display name of a category node
// before printing all child nodes. Child nodes that are also category nodes are
// printed recursively.
mxArray *getCategoryNodeAndAllFeatures(spinNodeHandle hCategoryNode, unsigned int level, spinError *err)
{
  *err = SPINNAKER_ERR_SUCCESS;
  unsigned int i = 0;
  unsigned int iFeature = 0;

  // Retrieve display name
  char displayName[MAX_BUFF_LEN];
  size_t displayNameLength = MAX_BUFF_LEN;

  *err = spinNodeGetDisplayName(hCategoryNode, displayName, &displayNameLength);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    return mxCreateDoubleMatrix(0,0,0);
  }
  mexPrintf("Display name: %s\n",displayName);
  //
  // Retrieve number of children
  //
  // *** NOTES ***
  // The two nodes that typically have children are category nodes and
  // enumeration nodes. Throughout the examples, the children of category
  // nodes are referred to as features while the children of enumeration
  // nodes are referred to as entries. Further, it might be important to
  // note that enumeration nodes can be cast as category nodes, but
  // category nodes cannot be cast as enumeration nodes.
  //
  size_t numberOfFeatures = 0;

  *err = spinCategoryGetNumFeatures(hCategoryNode, &numberOfFeatures);
  if (*err != SPINNAKER_ERR_SUCCESS) {
    return mxCreateDoubleMatrix(0,0,0);
  }

  // fieldNames for output structure
  char **fieldNames = (char **)malloc(numberOfFeatures * sizeof(char *));
  int numFields = 0;
  const int outDims[2] = {1, 1};
  const int nArrayElements = numberOfFeatures;
  mexPrintf("numFeatures: %i\n",nArrayElements);
  mxArray *vals = mxCreateCellArray(1, &nArrayElements);

  // for holding values of fields
  int64_t integerValue = 0;
  char stringValue[MAX_BUFF_LEN];
  size_t stringValueLength = MAX_BUFF_LEN;
  const unsigned int k_maxChars = MAX_CHARS;
  double floatValue = 0.0;
  bool8_t booleanValue = False;
  char value[MAX_BUFF_LEN];
  size_t valueLength = MAX_BUFF_LEN;
  char nodeName[MAX_BUFF_LEN];
  size_t nodeNameLength = MAX_BUFF_LEN;

  // Retrieve child
  spinNodeHandle hFeatureNode = NULL;
  //
  // Iterate through all children
  //
  // *** NOTES ***
  // It is important to note that the children of an enumeration nodes
  // may be of any node type.
  //
  for (iFeature = 0; iFeature < numberOfFeatures; iFeature++) {

    *err = spinCategoryGetFeatureByIndex(hCategoryNode, iFeature, &hFeatureNode);
    if (*err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo:spinCategoryGetFeatureByIndex) Error code: %i\n",*err);
      continue;
    }

    bool8_t featureNodeIsAvailable = False;
    bool8_t featureNodeIsReadable = False;

    *err = spinNodeIsAvailable(hFeatureNode, &featureNodeIsAvailable);
    if (*err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo:spinNodeIsAvaialble) Error code: %i\n",*err);
      continue;
    }

    *err = spinNodeIsReadable(hFeatureNode, &featureNodeIsReadable);
    if (*err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo:spinNodeIsReadable) Error code: %i\n",*err);
      continue;
    }

    if (!featureNodeIsAvailable || !featureNodeIsReadable) {
      mexPrintf("(mglPrivateCameraInfo) Feature node unavailable or unreadable\n");
      continue;
    }

    spinNodeType type = UnknownNode;

    *err = spinNodeGetType(hFeatureNode, &type);
    if (*err != SPINNAKER_ERR_SUCCESS) {
      mexPrintf("(mglPrivateCameraInfo:spinNodeGetType) Error code: %i\n",*err);
      continue;
    }

    // Category nodes must be dealt with separately in order to
    // retrieve subnodes recursively.
    if (type == CategoryNode) {
      mexPrintf("%i/%i l%i: Category node\n",iFeature,numberOfFeatures,level);
      // set the field name
      fieldNames[numFields] = (char *)malloc(strlen(displayName)+1);
      sprintf(fieldNames[numFields],"%s",displayName);
      // call recursively
      mexPrintf("%i/%i l%i: Recursive: %s level: %i\n",iFeature,numberOfFeatures,level,fieldNames[numFields],level+1);
      mxSetCell(vals,numFields++,getCategoryNodeAndAllFeatures(hFeatureNode, level + 1, err));
      mexPrintf("%i/%i l%i: Returned from recursive\n",iFeature,numberOfFeatures,level);
    }
    // Read all non-category nodes using spinNodeToString() function
    else {
      mexPrintf("%i/%i l%i: Non-Category node ",iFeature,numberOfFeatures,level);
      //      *err = spinNodeGetDisplayName(hFeatureNode, nodeName, &nodeNameLength);
      *err = spinNodeGetDisplayName(hFeatureNode, nodeName, &nodeNameLength);
      if (*err != SPINNAKER_ERR_SUCCESS) {

	mexPrintf("%i/%i l%i: ERROR spinNodeGetName ERROR: %i (%s)\n",iFeature,numberOfFeatures,level,*err,nodeName);
	//	continue;
      }
      // set the field with the display name
      mexPrintf("(%s) strlen: %i ",nodeName,strlen(nodeName));
      fieldNames[numFields] = (char *)malloc(strlen(nodeName)+1);
      sprintf(fieldNames[numFields++],"%s",nodeName);

      switch (type){
        case StringNode:
	  mexPrintf("string ");
	  // get string value
	  // Ensure allocated buffer is large enough for storing the string
	  *err = spinStringGetValue(hFeatureNode, NULL, &stringValueLength);
	  if ((*err == SPINNAKER_ERR_SUCCESS) && (stringValueLength <= k_maxChars)) {
            *err = spinNodeToString(hFeatureNode, stringValue, &stringValueLength);
	  }
	  mexPrintf("\"%s\"\n",stringValue);
	  // if all was ok, then set the output val
	  if (*err == SPINNAKER_ERR_SUCCESS) {
	    mxSetCell(vals,numFields-1,mxCreateString(stringValue));
	  }
	  break;

        case IntegerNode:
	  mexPrintf("Int ");
	  // get integer value
	  *err = spinIntegerGetValue(hFeatureNode, &integerValue);
	  if (*err == SPINNAKER_ERR_SUCCESS) {
	    mxSetCell(vals,numFields-1,mxCreateDoubleScalar((double)integerValue));
	  }
	  mexPrintf("%i\n",(int)integerValue);
	  break;

        case FloatNode:
	  mexPrintf("Float ");
	  // get float value
	  *err = spinFloatGetValue(hFeatureNode, &floatValue);
	  if (*err == SPINNAKER_ERR_SUCCESS) {
	    mxSetCell(vals,numFields-1,mxCreateDoubleScalar((double)floatValue));
	  }
	  mexPrintf("%d\n",(double)floatValue);
	  break;

        case BooleanNode:
	  mexPrintf("Boolean ");
	  // get boolean value
	  *err = spinBooleanGetValue(hFeatureNode, &booleanValue);
	  if (*err == SPINNAKER_ERR_SUCCESS) {
	    mxSetCell(vals,numFields-1,mxCreateDoubleScalar((double)booleanValue));
	  }
	  mexPrintf("%i\n",(int)booleanValue);
	  break;

        case CommandNode:
        case EnumerationNode:
        case ValueNode:
        case BaseNode:
        case RegisterNode:
        case EnumEntryNode:
        case CategoryNode:
        case PortNode:
        case UnknownNode:

	  mexPrintf("Other ");
	  // Ensure allocated buffer is large enough for storing the string
	  *err = spinNodeToString(hFeatureNode, NULL, &valueLength);

	  if (*err == SPINNAKER_ERR_SUCCESS) {
	    const unsigned int k_maxChars = MAX_CHARS;
	    if (valueLength <= k_maxChars) {
	      *err = spinNodeToString(hFeatureNode, value, &valueLength);
	      mexPrintf("valueLen: %i (%s) numFields: %i\n",valueLength,value,numFields);
	      if (*err == SPINNAKER_ERR_SUCCESS) {
		mxSetCell(vals,numFields-1,mxCreateString(value));
	      }
	    }
	  }
	  break;
      }
    }
  }

  // create output structure
  if (numFields > 0) {
    // create return structure
    mxArray *retval = mxCreateStructArray(1,outDims,numFields,(const char **)fieldNames);
    mexPrintf("%i/%i l%i: Creating output structures of %i fields: ",iFeature,numberOfFeatures,level,numFields);
    // cycle through and set values of structure
    for (iFeature = 0; iFeature < numFields; iFeature++) {
      mexPrintf("%s ",fieldNames[iFeature]);
      //mxSetField(retval,0,fieldNames[iFeature],mxGetCell(vals,iFeature));
    }
    mexPrintf("\nFinish level: %i\n",level);

    // free up string error
    //    for (iFeature = 0;iFeature<numFields;iFeature++) {
    //      free(fieldNames[iFeature]);
    //    }
    //    free(fieldNames);
    // return the structure
    return(mxCreateDoubleMatrix(0,0,0));
  }

  // nothing was created, return empty
  return(mxCreateDoubleMatrix(0,0,0));
}



