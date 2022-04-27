% mglMetalArcs.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglMetalArcs(xyz, rgba, wh, radii, wedge, border)
%         by: Benjamin heasly
%       date: 03/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw "vectorized" arcs with xyz, rgba, radii, wedge
%      usage: [ackTime, processedTime] = mglMetalArcs(xyz, rgba, wh, radii, wedge, border)
%             This is a common interface to mglMeal for circular arcs.
%             xyz -- 3 x n matrix of point positions [x, y, z]
%             rgba -- 4 x n matrix of point colors [r, g, b, a]
%             radii -- 2 x n matrix of annulus radii [inner, outer]
%             wedge-- 2 x n matriz of wedge angles [start, sweep]
%             border-- 1 x n antialiasing pixel size
%
%      e.g.:
% mglOpen()
% mglVisualAngleCoordinates(50, [20, 20]);
% xyz = [-5 0 0; 0 0 0; 5 0 0]';
% rgba = [1 0 0 1; 0 1 1 1; 1 1 1 0.5]';
% radii = [0 100; 0 100; 0 150]';
% wedge = [0 2*pi; pi/4 pi; 7*pi/4 pi/3]';
% border = [3 3 3];
% mglMetalArcs(xyz, rgba, radii, wedge, border);
% mglFlush();
function [ackTime, processedTime] = mglMetalArcs(xyz, rgba, radii, wedge, border)

if nargin < 5
  help mglMetalArcs
  return
end

nDots = size(xyz, 2);
if size(xyz, 1) ~= 3 ...
    || ~isequal(size(rgba), [4, nDots]) ...
    || ~isequal(size(radii), [2, nDots]) ...
    || ~isequal(size(wedge), [2, nDots]) ...
    || ~isequal(size(border), [1, nDots])
    fprintf('(mglMetalArcs) All args must have specific number of rows and the same number of columns (%f).\n', nDots);
      help mglMetalArcs
  return
end

% Stack up all the per-vertex data as a big matrix.
vertexData = single(cat(1, xyz, rgba, radii, wedge, border));

global mgl
mglSocketWrite(mgl.s, mgl.command.mglArcs);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nDots));
mglSocketWrite(mgl.s, vertexData);
processedTime = mglSocketRead(mgl.s, 'double');
