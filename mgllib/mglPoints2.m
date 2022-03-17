% mglPoints2.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglPoints2(x, y, size, color, isRound, antialiasing)
%         by: Benjamin Heasly
%       date: 04/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: plot 2D points on an OpenGL screen opened with mglOpen
%      usage: [ackTime, processedTime] = mglPoints2(x, y, size, color, isRound, antialiasing)
%             x,y = position of dots on screen
%             size = size of dots (in pixels)
%             color of dots
%             isRound false = squares (default), true = circles
%             antialiasing = size of border for antialiasing (default = 0)
%
%             See also mglMetalDots, with additional capability.
%
%       e.g.:
%
%mglOpen();
%mglVisualAngleCoordinates(57,[16 12]);
%mglPoints2(16*rand(500,1)-8,12*rand(500,1)-6,2,1);
%mglFlush();
%mglClose();
function [ackTime, processedTime] = mglPoints2(x, y, size, color, isRound, antialiasing)

nDots = numel(x);
if ~isequal(numel(y), nDots)
    fprintf('(mglPoints2) Number of y values must match number of x values (%d)', nDots);
    help mglPoints2
    return;
end
xyz = zeros([3, nDots], 'single');
xyz(1,:) = x;
xyz(2,:) = y;

if nargin < 3
    size = 10;
end
wh = zeros([2, nDots], 'single');
wh(:) = size;

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
    isRound = false;
end
shape = zeros(1, nDots, 'single');
shape(:) = isRound;

if nargin < 6
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

[ackTime, processedTime] = mglMetalDots(xyz, rgba, wh, shape, border);