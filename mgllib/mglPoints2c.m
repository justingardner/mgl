% mglPoints2c.m
%
%        $Id$
%      usage: mglPoints2c()
%         by: justin gardner & Jonas Larsson
%       date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson, Dan Birman (GPL see mgl/COPYING)
%    purpose: mex function to plot 2D points on an OpenGL screen opened with mglOpen
%             allows every dot to have a different color, useful for overlapping
%             dot patches
%      usage: mglPoints2c(x,y,size,r,g,b)
%             x,y = position of dots on screen
%             size = size of dots (in pixels)
%             r,g,b = color of dots in 0->1 range
%       e.g.:
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglClearScreen
% mglPoints2c(16*rand(500,1)-8,12*rand(500,1)-6,2,rand(500,1),rand(500,1),rand(500,1));
% mglFlush
