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
xStrip = zeros(1, n);
yStrip = zeros(1, n);
if (yLeft(1) < yRight(1))
    % The left side contains the bottom vertex.
    xStrip(1:2:end) = xLeft;
    xStrip(2:2:end) = xRight;
    yStrip(1:2:end) = yLeft;
    yStrip(2:2:end) = yRight;
else
    % The right side contains the bottom vertex (or they're equal).
    xStrip(1:2:end) = xRight;
    xStrip(2:2:end) = xLeft;
    yStrip(1:2:end) = yRight;
    yStrip(2:2:end) = yLeft;
end

% Concatenate vertices as XYZRGB.
vertices = zeros(6, n, 'single');
vertices(1, 1:n) = xStrip;
vertices(2, 1:n) = yStrip;
vertices(4, 1:n) = color(1);
vertices(5, 1:n) = color(2);
vertices(6, 1:n) = color(3);

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.polygon));
mgl.s = mglSocketWrite(mgl.s,uint32(n));
mgl.s = mglSocketWrite(mgl.s,vertices);
