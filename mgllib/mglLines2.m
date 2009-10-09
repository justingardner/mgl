% mglLines2.m
%
%        $Id$
%       usage: mglLines(x0, y0, x1, y1,size,color)
%          by: justin gardner
%        date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: mex function to plot lines on an OpenGL screen opened with mglOpen.
%              x0 and y0 are starting and x1 and y1 are ending point of line
%              size is line width and color is an color value (usually an array
%              of three number between 0 and 1). 
%       e.g.: 
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglLines2(-4, -4, 4, 4, 2, [1 0.6 1]);
%mglFlush
