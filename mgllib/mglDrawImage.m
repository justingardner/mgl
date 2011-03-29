% mglDrawImage
%
%       $Id: mglDrawImage.m
%     usage: mglDrawImage(pixelData, centerPx)
%        by: Christopher Broussard
%      date: 06/08/2008
% copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%   purpose: Mex function to take draw an RGB image.
%   
%            pixelData: A MxNx3 RGB matrix in the range [0,1].
%            centerPx: The center location for the image.  Note that the
%                      coordinate system considers the upper left corner
%                      of the screen to be (0, 0).
%        eg:
% mglOpen;
% mglScreenCoordinates;
% im = rand(100, 100, 3);
% mglDrawImage(im, [0 0]);
% mglFlush;
