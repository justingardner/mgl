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
%              struct.
%
%              mglMetalFullscreen(true, socketInfo);
%              pause(5);
%              mglMetalFullscreen(false, socketInfo);
function [ackTime, processedTime] = mglMetalFullscreen(isFullscreen, socketInfo)

if nargin < 1
    isFullscreen = true;
end

if nargin < 2
    global mgl
    socketInfo = mgl.s;
    socketInfo.command = mgl.command;
end

if isFullscreen
    mglSocketWrite(socketInfo, socketInfo.command.mglFullscreen);
else
    mglSocketWrite(socketInfo, socketInfo.command.mglWindowed);
end
ackTime = mglSocketRead(socketInfo, 'double');
processedTime = mglSocketRead(socketInfo, 'double');
