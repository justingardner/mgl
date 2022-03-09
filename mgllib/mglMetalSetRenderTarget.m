function [ackTime, processedTime] = mglMetalSetRenderTarget(tex)

if (nargin < 1)
    renderTarget = uint32(0);
else
    renderTarget = tex.textureNumber;
end

global mgl
mglSocketWrite(mgl.s, mgl.command.mglSetRenderTarget);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, renderTarget);
processedTime = mglSocketRead(mgl.s, 'double');
