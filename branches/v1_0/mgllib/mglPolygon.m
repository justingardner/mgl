%     $Id$
% program: mglPolygon.c
%      by: denis schluppeck, based on mglQuad/mglPoints by eli, 
%          justin, jonas
%    date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
% purpose: mex function to draw a polygon in an OpenGL screen
%          opened with mglOpen. 
% 	   x and y can be vectors (the polygon will be closed)
%   usage: mglPolygon(x, y, [color])
%    e.g.: 
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = [-5 -6 -3  4 5];
%y = [ 5  1 -4 -2 3];
%mglPolygon(x, y, [1 0 0]);
%mglFlush();

			   