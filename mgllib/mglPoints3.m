% mglPoints3.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglPoints3(x, y, z, size, color, isRound, antialiasing)
%         by: Benjamin Heasly
%       date: 04/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: plot 3D points on a screen opened with mglOpen
%      usage: [ackTime, processedTime] = mglPoints3(x, y, z, size, color, isRound, antialiasing)
%             x,y,z = position of dots on screen
%             size = size of dots (device units, not pixels)
%             color of dots
%             isRound false = squares (default), true = circles
%             antialiasing = size of border for antialiasing (default = 0)
%
%             See also mglMetalDots, with additional capability.
%       e.g.:
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglPoints3(16*rand(500,1)-8,12*rand(500,1)-6,zeros(500,1),2,1);
%mglFlush
function [ackTime, processedTime] = mglPoints3(x, y, z, size, color, isRound, antialiasing)

nDots = numel(x);
if ~isequal(numel(y), nDots)
    fprintf('(mglPoints3) Number of y values must match number of x values (%d)', nDots);
    help mglPoints3
    return;
end
if ~isequal(numel(z), nDots)
    fprintf('(mglPoints3) Number of z values must match number of x and y values (%d)', nDots);
    help mglPoints3
    return;
end
xyz = zeros([3, nDots], 'single');
xyz(1,:) = x;
xyz(2,:) = y;
xyz(3,:) = z;

if nargin < 4
    size = 1;
end
wh = zeros([2, nDots], 'single');
wh(:) = size;

if nargin < 5
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

if nargin < 6
    isRound = false;
end
shape = zeros(1, nDots, 'single');
shape(:) = isRound;

if nargin < 7
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

[ackTime, processedTime] = mglMetalDots(xyz, rgba, wh, shape, border);