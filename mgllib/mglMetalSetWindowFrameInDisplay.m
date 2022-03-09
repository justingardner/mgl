function [ackTime, processedTime] = mglMetalSetWindowFrameInDisplay(displayNumber, x, y, width, height)

global mgl
mglSocketWrite(mgl.s, mgl.command.mglSetWindowFrameInDisplay);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(displayNumber));
mglSocketWrite(mgl.s, uint32(x));
mglSocketWrite(mgl.s, uint32(y));
mglSocketWrite(mgl.s, uint32(width));
mglSocketWrite(mgl.s, uint32(height));
processedTime = mglSocketRead(mgl.s, 'double');
