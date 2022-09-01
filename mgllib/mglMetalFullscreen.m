% mglMetalFullscreen.m
%
%       usage: [ackTime, processedTime] = mglMetalFullscreen(isFullscreen, socketInfo)
%          by: Benjamin Heasly
%        date: 27 April 2022
%   copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Function to toggle the mglMetal app between windowed and
%     fullscreen.
%
%       usage:
%              By default this works on the primary mglMetal process.
%
%              % Open in windowed mode
%              mglOpen(0);
%
%              % Go fullscreen for 5 seconds then back to windowed.
%              mglMetalFullscreen(true);
%              pause(5);
%              mglMetalFullscreen(false);
%
%              To work on a specific process, pass in its socket info
%              struct.  Only the first element of socketInfo will be used.
%
%              mglMetalFullscreen(true, socketInfo);
%              pause(5);
%              mglMetalFullscreen(false, socketInfo);
function [ackTime, processedTime] = mglMetalFullscreen(isFullscreen, socketInfo)

if nargin < 1
    isFullscreen = true;
end

global mgl
if nargin < 2 || isempty(socketInfo)
    socketInfo = mgl.s;
end

if numel(socketInfo) > 1
    fprintf('(mglMetalFullscreen) Using only the first of %d elements of socketInfo\n', numel(socketInfo));
    socketInfo = socketInfo(1);
end

if isFullscreen
    mglSocketWrite(socketInfo, socketInfo.command.mglFullscreen);
else
    mglSocketWrite(socketInfo, socketInfo.command.mglWindowed);
end
ackTime = mglSocketRead(socketInfo, 'double');
processedTime = mglSocketRead(socketInfo, 'double');

% Only update the mgl context from the primary window.
if isfield(mgl, 's') && isequal(socketInfo, mgl.s)
    [displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo);
    mglSetParam('displayNumber', displayNumber);

    deviceWidth = mglGetParam('deviceWidth');
    deviceHeight = mglGetParam('deviceHeight');
    mglSetParam('screenWidth', rect(3));
    mglSetParam('screenHeight', rect(4));
    mglSetParam('xPixelsToDevice', deviceWidth / rect(3));
    mglSetParam('yPixelsToDevice', deviceHeight / rect(4));
    mglSetParam('xDeviceToPixels', rect(3) / deviceWidth);
    mglSetParam('yDeviceToPixels', rect(4)/ deviceHeight);
    mglSetParam('deviceRect', [rect(1), rect(2), rect(1)+rect(3), rect(2)+rect(4)]);
end
