This folder contains binaries from the mglMetal Xcode project.
This allows binaries to travel with the MGL repo, along with m-functions and mex-function binaries.

The Xcode project will copy build results into the latest/ subfolder.
When we want to make an mglMetal binary official, we can copy it into the stable/ subfolder manually.

In Matlab when we call mglMetalOpen, it will look first in the latest/ subfolder and use that binary if it's found.
Otherwise it will look in the stable/ subfolder and use that binary.

Most users can ignore the latest/ subfolder.
Git will also ignore the latest/ subfolder!
But if you're developing and running the Xcode build, the latest/ folder should make it easier to iterate on changes, while not squashing the stable/ version.

