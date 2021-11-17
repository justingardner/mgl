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

function mglPolygon(x, y, varargin)

global mgl;

if numel(x) ~= numel(y)
    fprintf("(mglPolygon) UHOH: Number of x points (%d) must match with y (%d)\n", numel(x), numel(y));
    return;
end

color = [1 1 1]';
if nargin > 2 && isnumeric(varargin{1}) && numel(varargin{1}) == 3
    color = varargin{1}(:);
end

% Metal doesn't support "polygons" in the sense of "glBegin(GL_POLYGON)".
% But Metal does support triangle strips.
% Assuming the given polygon is convex, we can rearrange it as a strip.

% Divide vertices horizontally into left and right halves.
n = numel(x);
nHalf = ceil(n / 2);
[~, horizontally] = sort(x);
left = horizontally(1:nHalf);
right = horizontally(nHalf+1:n);
xLeft = x(left);
yLeft = y(left);
xRight = x(right);
yRight = y(right);

% Sort each half vertically.
[yLeft, vertically] = sort(yLeft);
xLeft = xLeft(vertically);

[yRight, vertically] = sort(yRight);
xRight = xRight(vertically);

% Zip the halves back together, starting at the bottom, alternating halves.
xStrip = zeros(2, nHalf);
yStrip = zeros(2, nHalf);
if (yLeft(1) < yRight(1))
    % The left side contains the bottom vertex.
    xStrip(1, 1:numel(xLeft)) = xLeft;
    xStrip(2, 1:numel(xRight)) = xRight;
    yStrip(1, 1:numel(yLeft)) = yLeft;
    yStrip(2, 1:numel(yRight)) = yRight;
else
    % The right side contains the bottom vertex (or they're equal).
    xStrip(1, 1:numel(xRight)) = xRight;
    xStrip(2, 1:numel(xLeft)) = xLeft;
    yStrip(1, 1:numel(yRight)) = yRight;
    yStrip(2, 1:numel(yLeft)) = yLeft;
end

% Concatenate vertices as XYZRGB.
vertices = zeros(6, n, 'single');
vertices(1, 1:n) = xStrip(1:n);
vertices(2, 1:n) = yStrip(1:n);
vertices(4, 1:n) = color(1);
vertices(5, 1:n) = color(2);
vertices(6, 1:n) = color(3);

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.polygon));
mgl.s = mglSocketWrite(mgl.s,uint32(n));
mgl.s = mglSocketWrite(mgl.s,vertices);
