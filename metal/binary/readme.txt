This folder contains binaries from the mglMetal Xcode project.
This allows binaries to travel with the MGL repo, along with m-functions and mex-function binaries.

The Xcode project will copy build results into the latest/ subfolder.
When we want to make an mglMetal binary official, we can copy it into the stable/ subfolder manually.

In Matlab when we call mglMetalOpen, it will look first in the latest/ subfolder and use that binary if it's found.
Otherwise it will look in the stable/ subfolder and use that binary.

Most users can ignore the latest/ subfolder.
Git will also ignore the latest/ subfolder!
But if you're developing and running the Xcode build, the latest/ folder should make it easier to iterate on changes, while not squashing the stable/ version.

JG 1/22/2023: Not sure what the easiest way to get the build into the
Latest directory here for building in Xcode, but what I did is create
a Latest folder here and then make a soft link to where Xcode was
making my Debug executable mglMetal.app directory. You can find (and
set this), by going to the XCode directory File/Project Settings... or
XCode/Settings.../Locations and getting the location where the debug
is being made and then adding the link here as follows:
mkdir Latest
cd Latest
ln -s /Users/justin/Library/Developer/Xcode/DerivedData/Build/Products/Debug/mglMetal.app 

JG: 8/11/2023 Modified the mglGetExecutableName so that it looks for
builds in the directory noted above (DerivedData) so that you can
compile in XCode and not worry about making the soft link
