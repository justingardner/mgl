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
