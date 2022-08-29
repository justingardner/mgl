% mglMetalGetWindowFrameInDisplay.m
%
%      usage: [displayNumber, rect, ackTime, processedTime] = mglMetalGetWindowFrameInDisplay(socketInfo)
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns current mgl displayNumber and window frame rectangle.
%
%             % Get info for the primary window
%             mglOpen(0);
%             [displayNumber, rect] = mglMetalGetWindowFrameInDisplay()
%
%             % Get info a mirrored window, by index
%             % mglOpen(0);
%             % socketInfo = mglMirrorOpen(0);
%             [displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo)
%
function [displayNumber, rect, ackTime, processedTime] = mglMetalGetWindowFrameInDisplay(socketInfo)

global mgl
if nargin < 1 || isempty(socketInfo)
    socketInfo = mgl.s;
end

mglSocketWrite(socketInfo, socketInfo.command.mglGetWindowFrameInDisplay);
ackTime = mglSocketRead(socketInfo, 'double');

% Check if the command was processed OK or with error.
responseIncoming = mglSocketRead(socketInfo, 'double');
if (responseIncoming < 0)
    displayNumber = 0;
    rect = [0 0 0 0];
    processedTime = mglSocketRead(socketInfo, 'double');
    disp('Error getting Metal window and display info, you might try again with Console running, or: log stream --level info --process mglMetal')
    return
end

% Processing was OK, read the response.
displayNumber = mglSocketRead(socketInfo, 'uint32');
x = mglSocketRead(socketInfo, 'uint32');
y = mglSocketRead(socketInfo, 'uint32');
width = mglSocketRead(socketInfo, 'uint32');
height = mglSocketRead(socketInfo, 'uint32');
processedTime = mglSocketRead(socketInfo, 'double');

rect = [x, y, width, height];

% Only update the mgl context from the primary window.
if isequal(socketInfo, mgl.s)
    mglSetParam('displayNumber', displayNumber);
    mglSetParam('screenX', x);
    mglSetParam('screenY', y);
    mglSetParam('screenWidth', width);
    mglSetParam('screenHeight', height);
end
