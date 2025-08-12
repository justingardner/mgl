% mglPoints2c.m
%
%        $Id$
%      usage: results = mglPoints2c(x, y, size, r, g, b, a, isRound, antialiasing)
%         by: Benjamin Heasly
%       date: 03/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson, Dan Birman (GPL see mgl/COPYING)
%    purpose: mex function to plot 2D points on the screen opened with mglOpen
%             allows every dot to have a different color, useful for overlapping
%             dot patches
%      usage: results = mglPoints2c(x, y, size, r, g, b, a, isRound, antialiasing)
%             x,y = position of dots on screen
%             size = size of dots (device units, not pixels)
%             r,g,b = color of dots in 0->1 range
%             isRound false = squares (default), true = circles
%             antialiasing = size of border for antialiasing (default = 0)
%
%             See also mglMetalDots, with additional capability.
%       e.g.:
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglClearScreen
% mglPoints2c(16*rand(500,1)-8,12*rand(500,1)-6,2,rand(500,1),rand(500,1),rand(500,1));
% mglFlush
function results = mglPoints2c(x, y, size, r, g, b, a, isRound, antialiasing)

nDots = numel(x);
if ~isequal(numel(y), nDots)
    fprintf('(mglPoints2c) Number of y values must match number of x values (%d)', nDots);
    help mglPoints2c
    return;
end
xyz = zeros([3, nDots], 'single');
xyz(1,:) = x;
xyz(2,:) = y;

if nargin < 3
    size = 1;
end
wh = zeros([2, nDots], 'single');
wh(:) = size;

if nargin < 4
    r = ones([1, nDots], 'single');
end
if nargin < 5
    g = ones([1, nDots], 'single');
end
if nargin < 6
    b = ones([1, nDots], 'single');
end
if nargin < 7
    a = ones([1, nDots], 'single');
end
rgba = cat(1, r, g, b, a);

if nargin < 8
    isRound = false;
end
shape = zeros(1, nDots, 'single');
shape(:) = isRound;

if nargin < 9
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

results = mglMetalDots(xyz, rgba, wh, shape, border);
