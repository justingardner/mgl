% mglMetalSetWindowFrameInDisplay.m
%
%      usage: [ackTime, processedTime] = mglMetalSetWindowFrameInDisplay(displayNumber, rect)
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set the mgl window's displayNumber and frame rectangle.
%             Display number is 1-based in Matlab.
%
% mglOpen(0);
% mglMetalSetWindowFrameInDisplay(1, [x, y, width, height])
% 
function [ackTime, processedTime] = mglMetalSetWindowFrameInDisplay(displayNumber, rect)

x = rect(1);
y = rect(2);
width = rect(3);
height = rect(4);

global mgl
mglSocketWrite(mgl.s, mgl.command.mglSetWindowFrameInDisplay);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(displayNumber));
mglSocketWrite(mgl.s, uint32(x));
mglSocketWrite(mgl.s, uint32(y));
mglSocketWrite(mgl.s, uint32(width));
mglSocketWrite(mgl.s, uint32(height));
processedTime = mglSocketRead(mgl.s, 'double');

mglSetParam('displayNumber', displayNumber);
mglSetParam('screenX', x);
mglSetParam('screenY', y);
mglSetParam('screenWidth', width);
mglSetParam('screenHeight', height);
