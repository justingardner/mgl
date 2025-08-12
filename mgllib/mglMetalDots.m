% mglMetalDots.m
%
%        $Id$
%      usage: results = mglMetalDots(xyz, rgba, wh, shape, border)
%         by: Benjamin heasly
%       date: 03/16/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw "vectorized" dots with xyz, rgba, width and height.
%      usage: results = mglMetalDots(xyz, rgba, wh, shape, border)
%             This is a common interface to mglMeal for points, dots, etc.
%             xyz -- 3 x n matrix of point positions [x, y, z]
%             rgba -- 4 x n matrix of point colors [r, g, b, a]
%             wh -- 2 x n matrix of point sizes [width, height] (device units, not pixels)
%             shape -- 1 x n shape 0 -> rectangle, 1-> oval
%             border-- 1 x n antialiasing pixel size
%
function results = mglMetalDots(xyz, rgba, wh, shape, border, socketInfo)

if nargin < 5
  help mglMetalDots
  return
end

if nargin < 6 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

nDots = size(xyz, 2);
if size(xyz, 1) ~= 3 ...
    || ~isequal(size(rgba), [4, nDots]) ...
    || ~isequal(size(wh), [2, nDots]) ...
    || ~isequal(size(shape), [1, nDots]) ...
    || ~isequal(size(border), [1, nDots])
    fprintf('(mglMetalDots) All args must have specific number of rows and the same number of columns(%f).\n', nDots);
      help mglMetalDots
  return
end

% Convert width and height from user device units to Metal pixels.
wh(1,:) = wh(1,:) * mglGetParam('xDeviceToPixels');
wh(2,:) = wh(2,:) * mglGetParam('yDeviceToPixels');

% Stack up all the per-vertex data as a big matrix.
vertexData = single(cat(1, xyz, rgba, wh, shape, border));

% Setup timestamp can be used for measuring MGL frame timing,
% for example with mglTestRenderingPipeline.
setupTime = mglGetSecs();
mglSocketWrite(socketInfo, socketInfo(1).command.mglDots);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nDots));
mglSocketWrite(socketInfo, vertexData);
results = mglReadCommandResults(socketInfo, ackTime, setupTime);
