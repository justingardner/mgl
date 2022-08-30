% mglMetalSetWindowFrameInDisplay.m
%
%      usage: [ackTime, processedTime] = mglMetalSetWindowFrameInDisplay(displayNumber, rect, socketInfo)
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set the mgl window's displayNumber and frame rectangle.
%             Display number is 1-based in Matlab.
%
%             By default this works on the primary mglMetal process.
%
%             mglOpen(0);
%             mglMetalSetWindowFrameInDisplay(1, [100, 200, 64, 48]);
%
%             To work on a specific process, pass in its socket info
%             struct. Only the first element of socketInfo is used.
%
%             mglMetalSetWindowFrameInDisplay(1, [100, 200, 64, 48], socketInfo);
%
function [ackTime, processedTime] = mglMetalSetWindowFrameInDisplay(displayNumber, rect, socketInfo)

if nargin < 3 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.s;
end

if numel(socketInfo) > 0
    fprintf('(mglMetalSetWindowFrameInDisplay) Using only the first of %d elements of socketInfo\n', numel(socketInfo));
    socketInfo = socketInfo(1);
end

x = rect(1);
y = rect(2);
width = rect(3);
height = rect(4);

mglSocketWrite(socketInfo, socketInfo.command.mglSetWindowFrameInDisplay);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(displayNumber));
mglSocketWrite(socketInfo, uint32(x));
mglSocketWrite(socketInfo, uint32(y));
mglSocketWrite(socketInfo, uint32(width));
mglSocketWrite(socketInfo, uint32(height));
processedTime = mglSocketRead(socketInfo, 'double');
