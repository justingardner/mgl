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
#include "Spinnaker.h"
#include "SpinGenApi/SpinnakerGenApi.h"
#include <iostream>
#include <sstream>
#include <mex.h>

// Define the maximum number of characters that will be printed out
 // for any information retrieved from a node.
const unsigned int maxChars = 35;
using namespace Spinnaker;
using namespace Spinnaker::GenApi;
using namespace Spinnaker::GenICam;
using namespace std;
int PrintEnumerationSelector(CNodePtr node, unsigned int level);
// Use the following enum and global constant to select whether nodes are read
// as 'value' nodes or their individual types.
enum readType
{
    VALUE,
    INDIVIDUAL
};
const readType chosenRead = VALUE;
// This helper function deals with output indentation, of which there is a lot.
void Indent(unsigned int level)
{
    for (unsigned int i = 0; i < level; i++)
    {
        cout << "   ";
    }
}
// This function retrieves and prints the display name and value of all node
// types as value nodes. A value node is a general node type that allows for
// the reading and writing of any node type as a string.
int PrintValueNode(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // If this node is a selector and is an enumeration node print out its entries and selected features
        if (node->IsSelector() && (node->GetPrincipalInterfaceType() == intfIEnumeration))
        {
            return PrintEnumerationSelector(node, level);
        }
      
        // Cast as value node
        CValuePtr ptrValueNode = static_cast<CValuePtr>(node);
        //
        // Retrieve display name
        //
        // *** NOTES ***
        // A node's 'display name' is generally more appropriate for output and
        // user interaction whereas its 'name' is what the camera understands.
        // Generally, its name is the same as its display name but without
        // spaces - for instance, the name of the node that houses a camera's
        // serial number is 'DeviceSerialNumber' while its display name is
        // 'Device Serial Number'.
        //
        gcstring displayName = ptrValueNode->GetDisplayName();
        //
        // Retrieve value of any node type as string
        //
        // *** NOTES ***
        // Because value nodes return any node type as a string, it can be much
        // easier to deal with nodes as value nodes rather than their actual
        // individual types.
        //
        gcstring value = ptrValueNode->ToString();
        // Ensure that the value length is not excessive for printing
        if (value.size() > maxChars)
        {
            value = value.substr(0, maxChars) + "...";
        }
        // Print value
        Indent(level);
        cout << displayName << ": " << value << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints the display name and value of a string
// node, limiting the number of printed characters to a maximum defined by the
// maxChars global variable. Level parameter determines the indentation level
// for the output.
int PrintStringNode(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // Cast as string node
        CStringPtr ptrStringNode = static_cast<CStringPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrStringNode->GetDisplayName();
        //
        // Retrieve string node value
        //
        // *** NOTES ***
        // The Spinnaker SDK includes its own wrapped string class, gcstring. As
        // such, there is no need to import the 'string' library when using the
        // SDK. If a standard string object is preferred, simply use a c-style
        // or static cast on the gcstring object.
        //
        gcstring value = ptrStringNode->GetValue();
        // Ensure that the value length is not excessive for printing
        if (value.size() > maxChars)
        {
            value = value.substr(0, maxChars) + "...";
        }
        // Print value; 'level' determines the indentation level of output
        Indent(level);
        cout << displayName << ": " << value << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints the display name and value of an integer
// node.
int PrintIntegerNode(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // Cast node as integer node
        CIntegerPtr ptrIntegerNode = static_cast<CIntegerPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrIntegerNode->GetDisplayName();
        //
        // Retrieve integer node value
        //
        // *** NOTES ***
        // Keep in mind that the data type of an integer node value is an
        // int64_t as opposed to a standard int. While it is true that the two
        // are often interchangeable, it is recommended to use the int64_t
        // to avoid the introduction of bugs.
        //
        // All node types except for base and port nodes include a handy
        // ToString() method which returns a value as a gcstring.
        //
        int64_t value = ptrIntegerNode->GetValue();
        // Print value
        Indent(level);
        cout << displayName << ": " << value << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints the display name and value of a float
// node.
int PrintFloatNode(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // Cast as float node
        CFloatPtr ptrFloatNode = static_cast<CFloatPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrFloatNode->GetDisplayName();
        //
        // Retrieve float node value
        //
        // *** NOTES ***
        // Please take note that floating point numbers in the Spinnaker SDK are
        // almost always represented by the larger data type double rather than
        // float.
        //
        double value = ptrFloatNode->GetValue();
        // Print value
        Indent(level);
        cout << displayName << ": " << value << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints the display name and value of a boolean,
// printing "true" for true and "false" for false rather than the corresponding
// integer value ('1' and '0', respectively).
int PrintBooleanNode(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // Cast as boolean node
        CBooleanPtr ptrBooleanNode = static_cast<CBooleanPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrBooleanNode->GetDisplayName();
        //
        // Retrieve value as a string representation
        //
        // *** NOTES ***
        // Boolean node type values are represented by the standard bool data
        // type. The boolean ToString() method returns either a '1' or '0' as
        // a string rather than a more descriptive word like 'true' or 'false'.
        //
        gcstring value = (ptrBooleanNode->GetValue() ? "true" : "false");
        // Print value
        Indent(level);
        cout << displayName << ": " << value << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints the display name and tooltip of a command
// node, limiting the number of printed characters to a defined maximum.
// The tooltip is printed below because command nodes do not have an intelligible
// value.
int PrintCommandNode(CNodePtr node, unsigned int level)
{
    try
    {
        // Cast as command node
        CCommandPtr ptrCommandNode = static_cast<CCommandPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrCommandNode->GetDisplayName();
        //
        // Retrieve tooltip
        //
        // *** NOTES ***
        // All node types have a tooltip available. Tooltips provide useful
        // information about nodes. Command nodes do not have a method to
        // retrieve values as their is no intelligible value to retrieve.
        //
        gcstring tooltip = ptrCommandNode->GetToolTip();
        // Ensure that the value length is not excessive for printing
        if (tooltip.size() > maxChars)
        {
            tooltip = tooltip.substr(0, maxChars) + "...";
        }
        // Print tooltip
        Indent(level);
        cout << displayName << ": " << tooltip << endl;
        return 0;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        return -1;
    }
}
// This function retrieves and prints the display names of an enumeration node
// and its current entry (which is actually housed in another node unto itself).
int PrintEnumerationNodeAndCurrentEntry(CNodePtr node, unsigned int level)
{
    try
    {
        // If this enumeration node is a selector, cycle through its entries and selected features
        if (node->IsSelector())
        {
            return PrintEnumerationSelector(node, level);
        }
        // Cast as enumeration node
        CEnumerationPtr ptrEnumerationNode = static_cast<CEnumerationPtr>(node);
        //
        // Retrieve current entry as enumeration node
        //
        // *** NOTES ***
        // Enumeration nodes have three methods to differentiate between: first,
        // GetIntValue() returns the integer value of the current entry node;
        // second, GetCurrentEntry() returns the entry node itself; and third,
        // ToString() returns the symbolic of the current entry.
        //
        CEnumEntryPtr ptrEnumEntryNode = ptrEnumerationNode->GetCurrentEntry();
        // Retrieve display name
        gcstring displayName = ptrEnumerationNode->GetDisplayName();
        //
        // Retrieve current symbolic
        //
        // *** NOTES ***
        // Rather than retrieving the current entry node and then retrieving its
        // symbolic, this could have been taken care of in one step by using the
        // enumeration node's ToString() method.
        //
        gcstring currentEntrySymbolic = ptrEnumEntryNode->GetSymbolic();
        // Print current entry symbolic
        Indent(level);
        cout << displayName << ": " << currentEntrySymbolic << endl;
        return 0;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        return -1;
    }
}
// Based on the read type specified, print the node using the correct print function.
int PrintNode(CNodePtr node, unsigned int level)
{
    switch (chosenRead)
    {
    case VALUE:
    {
        return PrintValueNode(node, level);
    }
    case INDIVIDUAL: // Cast all non-category nodes as actual types
    {
        switch (node->GetPrincipalInterfaceType())
        {
        case intfIString:
        {
            return PrintStringNode(node, level);
        }
        case  intfIInteger:
        {
            return PrintIntegerNode(node, level);
        }
        case intfIFloat:
        {
            return PrintFloatNode(node, level);
        }
        case intfIBoolean:
        {
            return PrintBooleanNode(node, level);
        }
        case intfICommand:
        {
            return PrintCommandNode(node, level);
        }
        case intfIEnumeration:
        {
            return PrintEnumerationNodeAndCurrentEntry(node, level);
        }
        default:
        {
            cout << "Unexpected interface type." << endl;
            return -1;
        }
        }
    }
    default:
    {
        cout << "Unexpected read type." << endl;
        return -1;
    }
    }
}
// This function retrieves and prints the display names of enumeration selector nodes.
// The selector will cycle through every selector entry and print out all the selected
// features for that selector entry. It is possible for integer nodes to be selector 
// nodes as well, but this function will only cycle through Enumeration nodes.
int PrintEnumerationSelector(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        FeatureList_t selectedFeatures;
        node->GetSelectedFeatures(selectedFeatures);
        // Cast as an enumeration node
        CEnumerationPtr ptrSelectorNode = static_cast<CEnumerationPtr>(node);
        StringList_t entries;
        ptrSelectorNode->GetSymbolics(entries);
        // Note current selector node entry
        CEnumEntryPtr ptrCurrentEntry = ptrSelectorNode->GetCurrentEntry();
        // Retrieve display name
        gcstring displayName = ptrSelectorNode->GetDisplayName();
        // Retrieve current symbolic
        gcstring currentEntrySymbolic = ptrSelectorNode->ToString();
        // Print current entry symbolic
        Indent(level);
        cout << displayName << ": " << currentEntrySymbolic << endl;
        // For every selector node entry
        for (size_t i = 0; i < entries.size(); i++)
        {
            CEnumEntryPtr selectorEntry = ptrSelectorNode->GetEntryByName(entries[i]);
            FeatureList_t::const_iterator it;
            // Go through each enum entry of the selector node
            if (IsWritable(ptrSelectorNode))
            {
                if (IsAvailable(selectorEntry) && IsReadable(selectorEntry))
                {
                    ptrSelectorNode->SetIntValue(selectorEntry->GetValue());
                    Indent(level + 1);
                    cout << displayName << ": " << ptrSelectorNode->ToString() << endl;
                }
            }
            // Look at every node that is affected by the selector node
            for (it = selectedFeatures.begin(); it != selectedFeatures.end(); ++it)
            {
                CNodePtr ptrFeatureNode = *it;
                if (!IsAvailable(ptrFeatureNode) || !IsReadable(ptrFeatureNode))
                {
                    continue;
                }
                // Print the selected feature
                else
                {
                    result = result | PrintNode(ptrFeatureNode, level + 2);
                }
            }
        }
        // Restore the selector to its original value
        if (IsWritable(ptrSelectorNode))
        {
            ptrSelectorNode->SetIntValue(ptrCurrentEntry->GetValue());
        }
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// This function retrieves and prints out the display name of a category node
// before printing all child nodes. Child nodes that are also category nodes are
// printed recursively.
int PrintCategoryNodeAndAllFeatures(CNodePtr node, unsigned int level)
{
    int result = 0;
    try
    {
        // Cast as category node
        CCategoryPtr ptrCategoryNode = static_cast<CCategoryPtr>(node);
        // Retrieve display name
        gcstring displayName = ptrCategoryNode->GetDisplayName();
        // Print display name
        Indent(level);
        cout << displayName << endl;
        //
        // Retrieve children
        //
        // *** NOTES ***
        // The two nodes that typically have children are category nodes and
        // enumeration nodes. Throughout the examples, the children of category
        // nodes are referred to as features while the children of enumeration
        // nodes are referred to as entries. Keep in mind that enumeration
        // nodes can be cast as category nodes, but category nodes cannot be
        // cast as enumerations.
        //
        FeatureList_t features;
        ptrCategoryNode->GetFeatures(features);
        //
        // Iterate through all children
        //
        // *** NOTES ***
        // If dealing with a variety of node types and their values, it may be
        // simpler to cast them as value nodes rather than as their individual
        // types. However, with this increased ease-of-use, functionality is
        // sacrificed.
        //
        FeatureList_t::const_iterator it;
        for (it = features.begin(); it != features.end(); ++it)
        {
            CNodePtr ptrFeatureNode = *it;
            // Ensure node is available and readable
            if (!IsAvailable(ptrFeatureNode) || !IsReadable(ptrFeatureNode))
            {
                continue;
            }
            // Category nodes must be dealt with separately in order to
            // retrieve subnodes recursively.
            if (ptrFeatureNode->GetPrincipalInterfaceType() == intfICategory)
            {
                result = result | PrintCategoryNodeAndAllFeatures(ptrFeatureNode, level + 1);
            }
            // Print the node
            else
            {
                result = result | PrintNode(ptrFeatureNode, level + 1);
            }
        }
        cout << endl;
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}

// This function configures the camera to add chunk data to each image. It does
// this by enabling each type of chunk data before enabling chunk data mode.
// When chunk data is turned on, the data is made available in both the nodemap
// and each image.
int ConfigureChunkData(INodeMap& nodeMap)
{
    int result = 0;
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
            cout << "\t" << ptrChunkSelectorEntry->GetSymbolic() << ": ";
            // Retrieve corresponding boolean
            CBooleanPtr ptrChunkEnable = nodeMap.GetNode("ChunkEnable");
            // Enable the boolean, thus enabling the corresponding chunk data
            if (!IsAvailable(ptrChunkEnable))
            {
                cout << "not available" << endl;
                result = -1;
            }
            else if (ptrChunkEnable->GetValue())
            {
                cout << "enabled" << endl;
            }
            else if (IsWritable(ptrChunkEnable))
            {
                ptrChunkEnable->SetValue(true);
                cout << "enabled" << endl;
            }
            else
            {
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
// This function acts as the body of the example. First nodes from the TL
// device and TL stream nodemaps are retrieved and printed. Following this,
// the camera is initialized and then nodes from the GenICam nodemap are
// retrieved and printed.
int RunSingleCamera(CameraPtr cam)
{
    int result = 0;
    unsigned int level = 0;
    try
    {
        //
        // Retrieve TL device nodemap
        //
        // *** NOTES ***
        // The TL device nodemap is available on the transport layer. As such,
        // camera initialization is unnecessary. It provides mostly immutable
        // information fundamental to the camera such as the serial number,
        // vendor, and model.
        //
        cout << endl << "*** PRINTING TRANSPORT LAYER DEVICE NODEMAP ***" << endl << endl;
        INodeMap& genTLNodeMap = cam->GetTLDeviceNodeMap();
        result = PrintCategoryNodeAndAllFeatures(genTLNodeMap.GetNode("Root"), level);
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
        cout << "*** PRINTING TL STREAM NODEMAP ***" << endl << endl;
        INodeMap& nodeMapTLStream = cam->GetTLStreamNodeMap();
        result = result | PrintCategoryNodeAndAllFeatures(nodeMapTLStream.GetNode("Root"), level);
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
        cout << "*** PRINTING GENICAM NODEMAP ***" << endl << endl;
        cam->Init();
        //
        // Retrieve GenICam nodemap
        //
        // *** NOTES ***
        // The GenICam nodemap is the primary gateway to customizing
        // and configuring the camera to suit your needs. Configuration options
        // such as image height and width, trigger mode enabling and disabling,
        // and the sequencer are found on this nodemap.
        //
        INodeMap& appLayerNodeMap = cam->GetNodeMap();
        result = result | PrintCategoryNodeAndAllFeatures(appLayerNodeMap.GetNode("Root"), level);
	// Configure chunk data
	ConfigureChunkData(appLayerNodeMap);
	DisplayChunkData(appLayerNodeMap);
        //
        // Deinitialize camera
        //
        // *** NOTES ***
        // Camera deinitialization helps ensure that devices clean up properly
        // and do not need to be power-cycled to maintain integrity.
        //
        cam->DeInit();
    }
    catch (Spinnaker::Exception& e)
    {
        cout << "Error: " << e.what() << endl;
        result = -1;
    }
    return result;
}
// Example entry point; please see Enumeration example for more in-depth
// comments on preparing and cleaning up the system.
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int result = 0;
    // Print application build information
    cout << "Application build date: " << __DATE__ << " " << __TIME__ << endl << endl;
    // Retrieve singleton reference to system object
    SystemPtr system = System::GetInstance();
    // Print out current library version
    const LibraryVersion spinnakerLibraryVersion = system->GetLibraryVersion();
    cout << "Spinnaker library version: "
        << spinnakerLibraryVersion.major << "."
        << spinnakerLibraryVersion.minor << "."
        << spinnakerLibraryVersion.type << "."
        << spinnakerLibraryVersion.build << endl << endl;
    // Retrieve list of cameras from the system
    CameraList camList = system->GetCameras();
    unsigned int numCameras = camList.GetSize();
    cout << "Number of cameras detected: " << numCameras << endl << endl;
    // Finish if there are no cameras
    if (numCameras == 0)
    {
        // Clear camera list before releasing system
        camList.Clear();
        // Release system
        system->ReleaseInstance();
        cout << "Not enough cameras!" << endl;
        cout << "Done! Press Enter to exit..." << endl;
        getchar();
        return;
    }
    //
    // Create shared pointer for camera
    //
    // *** NOTES ***
    // The CameraPtr object is a shared pointer, and will generally clean itself
    // up upon exiting its scope.
    //
    // *** LATER ***
    // However, if a shared camera pointer is created in the same scope that a
    // system object is explicitly released (i.e. this scope), the reference to
    // the camera must be broken by manually setting the pointer to nullptr.
    //
    CameraPtr pCam = nullptr;
    // Run example on each camera
    for (unsigned int i = 0; i < numCameras; i++)
    {
        // Select camera
        pCam = camList.GetByIndex(i);
        cout << endl << "Running example for camera " << i << "..." << endl;
        // Run example
        result = result | RunSingleCamera(pCam);
        cout << "Camera " << i << " example complete..." << endl << endl;
    }
    //
    // Release shared pointer reference to camera before releasing system
    //
    // *** NOTES ***
    // Had the CameraPtr object been created within the for-loop, it would not
    // be necessary to manually break its reference because the shared pointer
    // would have automatically cleaned itself up upon exiting the loop.
    //
    pCam = nullptr;
    // Clear camera list before releasing system
    camList.Clear();
    // Release system
    system->ReleaseInstance();
    return;
}
