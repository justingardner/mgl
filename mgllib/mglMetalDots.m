% mglMetalDots.m
%
%        $Id$
%      usage: [ackTime, processedTime, setupTime] = mglMetalDots(xyz, rgba, wh, shape, border)
%         by: Benjamin heasly
%       date: 03/16/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw "vectorized" dots with xyz, rgba, width and height.
%      usage: [ackTime, processedTime] = mglMetalDots(xyz, rgba, wh, shape, border)
%             This is a common interface to mglMeal for points, dots, etc.
%             xyz -- 3 x n matrix of point positions [x, y, z]
%             rgba -- 4 x n matrix of point colors [r, g, b, a]
%             wh -- 2 x n matrix of point sizes [width, height] (device units, not pixels)
%             shape -- 1 x n shape 0 -> rectangle, 1-> oval
%             border-- 1 x n antialiasing pixel size
%
function [ackTime, processedTime, setupTime] = mglMetalDots(xyz, rgba, wh, shape, border)

if nargin < 5
  help mglMetalDots
  return
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

global mgl

% Setup timestamp can be used for measuring MGL frame timing,
% for example with mglTestRenderingPipeline.
setupTime = mglGetSecs();
mglSocketWrite(mgl.s, mgl.command.mglDots);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nDots));
mglSocketWrite(mgl.s, vertexData);
processedTime = mglSocketRead(mgl.s, 'double');
