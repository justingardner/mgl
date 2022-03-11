% mglMetalGetWindowFrameInDisplay.m
%
%      usage: [displayNumber, rect, ackTime, processedTime] = mglMetalGetWindowFrameInDisplay()
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns current mgl displayNumber and window frame rectangle.
%
% mglOpen(0);
% [displayNumber, rect] = mglMetalGetWindowFrameInDisplay()
% 
function [displayNumber, rect, ackTime, processedTime] = mglMetalGetWindowFrameInDisplay()

global mgl

mglSocketWrite(mgl.s, mgl.command.mglGetWindowFrameInDisplay);
ackTime = mglSocketRead(mgl.s, 'double');
displayNumber = mglSocketRead(mgl.s, 'uint32');
x = mglSocketRead(mgl.s, 'uint32');
y = mglSocketRead(mgl.s, 'uint32');
width = mglSocketRead(mgl.s, 'uint32');
height = mglSocketRead(mgl.s, 'uint32');
processedTime = mglSocketRead(mgl.s, 'double');

rect = [x, y, width, height];

mglSetParam('displayNumber', displayNumber);
mglSetParam('screenX', x);
mglSetParam('screenY', y);
mglSetParam('screenWidth', width);
mglSetParam('screenHeight', height);
