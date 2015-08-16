%MGL library functions
%
%Main screen functions
%  mglOpen                   : Opens the screen
%  mglFlush                  : Flips front and back buffer
%  mglClose                  : Closes the screen
%  mglResolution             : Sets the resolution of a display
%
%Other screen functions
%  mglSwitchDisplay          : Switches between multiple monitors
%  mglMoveWindow             : Moves windows created by mglOpen(0);
%  mglDescribeDisplays       : Gets info about displays
%  mglFrameGrab              : Frame grab to a matlab matrix
%
%mgl global parameters
% mglSetParam                : Sets an mgl global parameter
% mglGetParam                : Gets an mgl global parameter
%
%Functions to adjust the coordinate frame
%  mglVisualAngleCoordinates : Visual angle coordinates
%  mglScreenCoordinates      : Pixel coordinate frame
%  mglTransform              : Low-level function to adjust transforms
%  mglHFlip                  : Horizontally flip coordinates
%  mglVFlip                  : Vertically flip coordinates
%
%Texture functions used for displaing images
%  mglCreateTexture          : Create a texture from a matrix
%  mglBltTexture             : Draw the texture to the screen
%  mglDeleteTexture          : Delete the texture
%
%Drawing text
%  mglTextSet                : Set parameters for drawing text
%  mglText                   : Create a texture from a string
%  mglTextDraw               : Draws text to screen (simple but slow)
%  mglStrokeText             : Simple text for systems w/out text support
%
%Gamma tables
%  mglSetGammaTable          : Sets the display card gamma table
%  mglGetGammaTable          : Gets the current gamma table
%
%Drawing different shapes
%  mglPoints2                : 2D points
%  mglPoints3                : 3D points
%  mglLines2                 : 2D lines
%  mglLines3                 : 3D lines
%  mglFillOval               : Ovals
%  mglFillRect               : Rectangles
%  mglFixationCross          : Cross
%  mglGluDisk                : Circular dots
%  mglPolygon                : Polygons
%  mglQuads                  : Quads
%
%Stencils to control drawing only to specific parts of screen
%  mglStencilCreateBegin     : Start drawing a stencil
%  mglStencilCreateEnd       : End drawing a stencil
%  mglStencilSelect          : Select a stencil 
%
%Keyboard and mouse functions
%  mglGetKeys                : Get keyboard state
%  mglGetMouse               : Get mouse state
%  mglGetKeyEvent            : Get a key down event off of queue
%  mglGetMouseEvent          : Get a mouse button down event off of queue
%  mglPostEvent              : Post a keyboard event to happen in the future (mac only)
%  mglSimulateRun            : Post a series of keyboard backticks 
%  mglEatKeys                : Prevent unneeded key presses from being sent to application (mac only)
%
%Timing functions
%  mglGetSecs                : Get time in seconds
%  mglWaitSecs               : Wait for a time in seconds
%
%Sound functions
%  mglInstallSound           : Install an .aiff file or matlab array for playing with mglPlaySound
%  mglPlaySound              : Play a system sound
%  mglDeleteSound            : Delete a previously created sound
%
%Movies
%  mglMovie                  : Function to play quicktime movies (mac 64bit only)
%
%Eyelink
%  mglEyelinkOpen            : Open a link to eye-tracker
%  mglEyelinkClose           : Close the link to eye-tracker
%  mglEyelinkSetup           : Puts tracker in setup mode
%  mglEyelinkRecordingStart  : Start recording
%  mglEyelinkRecordingStop   : Stop recording
%  mglEyelinkCMDPrintF       : Send a command to the eye tracker
%  mglEyelinkEDFPrintF       : Put a message into recorded data-stream
%  mglEyelinkRecordingCheck  : Check to see if eye-tracker is recording
%  mglEyelinkEDFOpen         : Opens a new datafile to store eye data
%  mglEyelikGetCurrentEyePos : Get current eye position
%  
%Test/Demo programs
%  mglTestAlignment          : Alignment of textures
%  mglTestDots               : Draws dots
%  mglTestEyelink            : Test the eyelink eye-tracker
%  mglTestGamma              : GUI controlled gamma
%  mglTestLUTAnimation       : Gamma LUT animation
%  mglTestStencil            : Demonstrates stencil functions
%  mglTestTex                : Draws a gabor
%  mglTestTexMulti           : Draws many small images to screen
%  mglTestText               : Draws text
%  mglTestKeys               : Returns keyboard codes

