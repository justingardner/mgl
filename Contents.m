%MGL library functions
%
%Main screen functions
%  mglOpen                   : Opens the screen
%  mglFlush                  : Flips front and back buffer
%  mglClose                  : Closes the screen
%
%Functions to adjust coordinate frame
%  mglVisualAngleCoordinates : Visual angle coordinates
%  mglScreenCoordinates      : Pixel coordinate frame
%  mglTransform              : Low-level function to adjust transforms
%  mglHFlip                  : Horizontally flip coordinates
%  mglVFlip                  : Vertically flip coordinates
%
%Texture functions used for displaing images
%  mglCreateTexture          : Create a texture from a matrix
%  mglBltTexture             : Draw the texture to the screen
%
%Drawing text
%  mglTextSet                : Set parameters for drawing text
%  mglText                   : Create a texture from a string
%  mglTextDraw               : Draws text directly to screen (slow)
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
%Test/Demo programs
%  mglTestAlignment          : Alignment of textures
%  mglTestDots               : Draws dots
%  mglTestGamma              : GUI controlled gamma
%  mglTestLUTAnimation       : Gamma LUT animation
%  mglTestStencil            : Demonstrates stencil functions
%  mglTestTex                : Draws a gabor
%  mglTestTexMulti           : Draws many small images to screen
%  mglTestText               : Draws text

