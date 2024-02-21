% mglFillRect3D - draw filled rectangle(s) on the screen
%
%      usage: results = mglFillRect3D(x, y, z, size, [rgb], [rotation], [antialias])
%         by: Benjamin Heasly
%       date: 03-17-2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y,z - vectors of x, y, and z coordinates of center
%             size - [width height] of oval
%             rgb - [r g b] triplet for color
%             rotation - [angle axisOfRotation] Rotation parameters
%             antialias - Toggles antialiasing
%
%    purpose: Draw filled rectangles(s) centered at x,y,z with size [xsize
%    ysize] and color [rgb]. The function is vectorized, so if you
%    provide many x/y/z coordinates (identical) rectangles will be plotted
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
function results = mglFillRect3D(x, y, z, size, rgb, rotation, antialias, socketInfo)

if nargin < 4
    help mglFillRect3D
    return
end

nRects = numel(x);
if numel(y) ~= nRects
    fprintf('(mglFillRect3D) number of y values must match number of x values (%d).\n', nRects);
    help mglFillRect3D
    return
end
if numel(z) ~= nRects
    fprintf('(mglFillRect3D) number of z values must match number of x and y values (%d).\n', nRects);
    help mglFillRect3D
    return
end

if nargin < 4
    size = [1 1];
end

if nargin < 5
    rgb = [1 1 1];
end

if nargin < 6
    rotation = [0 1 0 0];
end

if nargin == 7
    fprintf('(mglFillRect3D) Sorry, antialiasing is not implemented in Metal yet.\n');
end

if nargin < 8 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

% Pre-rotate corners to place about each xyz point.
% In MGL v2 we did this with glRotate -- which is not in Metal.
% Since we're rotating about each rect's center,
% it seems OK to pre-apply the rotation once, here in Matlab.
r = rotationMatrix(rotation(1), rotation(2:4));

% Construct four corner offsets about each xyz point.
% c2 - c3
%  | \ |
% c1 - c4
w = size(1) / 2;
h = size(2) / 2;
c1 = r*[-w -h 0 1]';
c2 = r*[-w +h 0 1]';
c3 = r*[+w +h 0 1]';
c4 = r*[+w -h 0 1]';

% Construct actual corners near the xyz points.
x1 = x + c1(1);
x2 = x + c2(1);
x3 = x + c3(1);
x4 = x + c4(1);
y1 = y + c1(2);
y2 = y + c2(2);
y3 = y + c3(2);
y4 = y + c4(2);
z1 = z + c1(3);
z2 = z + c2(3);
z3 = z + c3(3);
z4 = z + c4(3);

% Assemble the four corners into triangels, two per rectangle.
triangleX = cat(1, x1, x2, x4, x2, x3, x4);
triangleY = cat(1, y1, y2, y4, y2, y3, y4);
triangleZ = cat(1, z1, z2, z4, z2, z3, z4);

% Pack xyz-rgb vertex data.
nVertices = 6 * nRects;
vertexData = zeros([6, nVertices], 'single');
vertexData(1,:) = triangleX(:);
vertexData(2,:) = triangleY(:);
vertexData(3,:) = triangleZ(:);
vertexData(4,:) = rgb(1);
vertexData(5,:) = rgb(2);
vertexData(6,:) = rgb(3);

mglSocketWrite(socketInfo, socketInfo(1).command.mglQuad);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nVertices));
mglSocketWrite(socketInfo, vertexData);
results = mglReadCommandResults(socketInfo, ackTime);


% https://www.cs.sfu.ca/~haoz/teaching/htmlman/rotate.html
% https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/glRotate.xml
function r = rotationMatrix(degrees, xyz)
s = sind(degrees);
c = cosd(degrees);
omc = 1 - c;
xyzn = xyz ./ norm(xyz);
x = xyzn(1);
y = xyzn(2);
z = xyzn(3);
r = eye(4);
r(1,1) = x*x*omc+c;
r(2,1) = y*x*omc+z*s;
r(3,1) = x*z*omc-y*s;
r(1,2) = x*y*omc-z*s;
r(2,2) = y*y*omc+c;
r(3,2) = y*z*omc+x*s;
r(1,3) = x*z*omc+y*s;
r(2,3) = y*z*omc-x*s;
r(3,3) = z*z*omc+c;
