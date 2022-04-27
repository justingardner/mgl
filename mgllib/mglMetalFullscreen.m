% mglMetalFullscreen.m
%
%       usage: [ackTime, processedTime] = mglMetalFullscreen(isFullscreen)
%          by: Benjamin Heasly
%        date: 27 April 2022
%   copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Function to toggle the mglMetal app between windowed and
%     fullscreen.
%
%       usage:
%              % Open in windowed mode
%              mglOpen(0);
%
%              % Go fullscreen for 5 seconds then back to windowed.
%              mglMetalFullscreen(true);
%              pause(5);
%              mglMetalFullscreen(false);
%
function [ackTime, processedTime] = mglMetalFullscreen(isFullscreen)

if nargin < 1
    isFullscreen = true;
end

global mgl;

if isFullscreen
    mglSocketWrite(mgl.s, mgl.command.mglFullscreen);
else
    mglSocketWrite(mgl.s, mgl.command.mglWindowed);
end
ackTime = mglSocketRead(mgl.s, 'double');
processedTime = mglSocketRead(mgl.s, 'double');
