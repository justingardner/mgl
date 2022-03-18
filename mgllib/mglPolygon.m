%     $Id$
%
%      by: Benjamin Heasly
%    date: 03/18/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
% purpose: Function to draw a polygon in a screen opened with mglOpen.
% 	       x and y can be vectors (the polygon will be closed)
%
%          Note for MGL v3 with Metal:
%          Metal doesn't support polygons quite like OpenGL GL_POLYGON.
%          GL_POLYGON is fairly general and can support convex polygons.
%          Metal only supports triangle strips.
%          This works out fine as long as:
%           - The given polygon is convex.
%           - The given x,y pairs are wound sequentially, clockwise or
%             counterclockwise around the polygon's perimiter.
%          The code below assumes this is the case!
%
%   usage: mglPolygon(x, y, [color])
%    e.g.:
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = [-5 -6 -3  4 5];
%y = [ 5  1 -4 -2 3];
%mglPolygon(x, y, [1 0 0]);
%mglFlush();

function [ackTime, processedTime] = mglPolygon(x, y, varargin)

global mgl;

if numel(x) ~= numel(y)
    fprintf("(mglPolygon) UHOH: Number of x points (%d) must match with y (%d)\n", numel(x), numel(y));
    return;
end

color = [1 1 1];
if nargin > 2 && isnumeric(varargin{1})
    color = varargin{1};
end
if numel(color) == 1
    color = [color, color, color];
end

% Divide the vertices into halves, working from the front and the back.
n = numel(x);
nHalf = ceil(n / 2);
front = 1:nHalf;
back = n:-1:nHalf+1;

% Zip the halves back together, alternating front and back.
xStrip = zeros(2, nHalf);
xStrip(1, 1:numel(front)) = x(front);
xStrip(2, 1:numel(back)) = x(back);
yStrip = zeros(2, nHalf);
yStrip(1, 1:numel(front)) = y(front);
yStrip(2, 1:numel(back)) = y(back);

% Concatenate vertices as XYZRGB.
vertices = zeros(6, n, 'single');
vertices(1, 1:n) = xStrip(1:n);
vertices(2, 1:n) = yStrip(1:n);
vertices(4, 1:n) = color(1);
vertices(5, 1:n) = color(2);
vertices(6, 1:n) = color(3);

% Send vertices over to the rendering app.
mglSocketWrite(mgl.s, mgl.command.mglPolygon);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(n));
mglSocketWrite(mgl.s, vertices);
processedTime = mglSocketRead(mgl.s, 'double');
