% mglLines2.m
%
%        $Id$
%       usage: mglLines(x0, y0, x1, y1,size,color,<anti-aliasing>)
%          by: justin gardner
%        date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: mex function to plot lines on an OpenGL screen opened with mglOpen.
%              x0 and y0 are starting and x1 and y1 are ending point of line
%              size is line width and color is an color value (usually an array
%              of three number between 0 and 1). 
%              Set anti-alising to 1 (defaults to 0) if you want the line to be antialiased.
%       e.g.: 
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglLines2(-4, -4, 4, 4, 2, [1 0.6 1]);
%mglFlush
%
%To draw multiple lines at once:
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglLines2(rand(1,100)*5-2.5, rand(1,100)*10-5, rand(1,100)*5-2.5, rand(1,100)*3-1.5, 3, [0 0.6 1],1);
%mglFlush
%
