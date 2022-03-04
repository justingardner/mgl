% mglPoints2.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglPoints2()
%         by: justin gardner & Jonas Larsson
%       date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: plot 2D points on an OpenGL screen opened with mglOpen
%      usage: mglPoints2(x,y,size,color[,round])
%             x,y = position of dots on screen
%             size = size of dots (in pixels)
%             color of dots
%             isRound false = squares (default), true = circles
%       e.g.:
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglPoints2(16*rand(500,1)-8,12*rand(500,1)-6,2,1);
%mglFlush
function [ackTime, processedTime] = mglPoints2(x,y,size,color,varargin)

if nargin < 5
    isRound = false;
else
    isRound = logical(varargin{1}(1));
end

if numel(color) == 1
    color = [color, color, color];
end

global mgl;

% create vertices
v = [x(:) y(:)];
v(:,3) = 0;
v = v';

% write dots command
mglSocketWrite(mgl.s, mgl.command.mglDots);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, single(size(1)));
mglSocketWrite(mgl.s, single(color(1:3)));
mglSocketWrite(mgl.s, uint32(isRound(1)));
mglSocketWrite(mgl.s, uint32(length(x)));
mglSocketWrite(mgl.s, single(v(:)));
processedTime = mglSocketRead(mgl.s, 'double');
