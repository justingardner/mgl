% mglFillRect3D - draw filled rectangle(s) on the screen
%
%        $Id: mglFillRect3D.m 18 2006-09-13 15:41:18Z justin $
%      usage: mglFillRect3D(x, y, z, size, [rgb], [rotation], [antialias])
%         by: Christopher Broussard
%       date: 05/10/2011
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y,z - vectors of x, y, and z coordinates of center
%             size - [width height] of oval
%             rgb - [r g b] triplet for color
%             rotation - [angle axisOfRotation] Rotation parameters
%             antialias - Toggles antialiasing
%
%    purpose: Draw filled rectangles(s) centered at x,y,z with size [xsize
%    ysize] and color [rgb]. The function is vectorized, so if you
%    provide many x/y/z coordinates (identical) ovals will be plotted
%    at all those locations.  Rotation is a 4 element vector that specifies
%    the amount of rotation in degrees and the vector about which it rotates.
%    Rotation is performed about the center of each rectangle.
%
%       e.g.: 
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% x = [-1 -4 -3 0 3 4 1];
% y = [-1 -4 -3 0 3 4 1];
% z = [-1 -4 -3 0 3 4 1];
% sz = [1 1]; 
% rotData = [45 0 1 0];  % 45 degrees about the y-axis.
% mglFillRect3D(x, y, z, sz, [1 1 0], rotData);
% mglFlush();
