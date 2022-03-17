% mglFillRect - draw filled rectangle(s) on the screen
%
%        $Id$
%      usage: [ackTime, processedTime] = mglFillRect(x, y, size, color, antialiasing)
%         by: Benjamin Heasly
%       date: 03-17--2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y - vectors of x and y coordinates of center
%             size - [width height] of oval
%             color - [r g b] triplet for color
%             antialiasing = size of border for antialiasing (default = 0)
%
%             See also mglMetalDots, with additional capability.
%    purpose: draw filled rectangles(s) centered at x,y with size [xsize
%    ysize] and color [rgb]. the function is vectorized, so if you
%    provide many x/y coordinates (identical) ovals will be plotted
%    at all those locations. 
%
%       e.g.: 
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = [-1 -4 -3 0 3 4 1];
%y = [-1 -4 -3 0 3 4 1];
%sz = [1 1]; 
%mglFillRect(x, y, sz,  [1 1 0]);
%mglFlush();
%
function [ackTime, processedTime] = mglFillRect(x, y, size, color, antialiasing)

nDots = numel(x);
if ~isequal(numel(y), nDots)
    fprintf('(mglFillRect) Number of y values must match number of x values (%d)', nDots);
    help mglFillRect
    return;
end
xyz = zeros([3, nDots], 'single');
xyz(1,:) = x;
xyz(2,:) = y;

if nargin < 3
    size = [10, 10];
end
wh = zeros([2, nDots], 'single');
wh(1,:) = size(1);
wh(2,:) = size(2);

if nargin < 4
    color = [1 1 1 1];
end
if numel(color) == 3
    color = [color, 1];
end
if numel(color) < 3
    color = [color(1), color(1), color(1), 1];
end
rgba = zeros(4, nDots, 'single');
rgba(1,:) = color(1);
rgba(2,:) = color(2);
rgba(3,:) = color(3);
rgba(4,:) = color(4);

if nargin < 5
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

shape = zeros(1, nDots);
[ackTime, processedTime] = mglMetalDots(xyz, rgba, wh, shape, border);


