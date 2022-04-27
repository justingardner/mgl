% mglMetalSetRenderTarget.m
%
%      usage: [ackTime, processedTime] = mglMetalSetRenderTarget(tex)
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set mglMetal's render target -- screen or offscreen texture.
%      usage: mglMetalSetRenderTarget(tex)
%             tex -- a texture created previously with mglCreateTexture or
%             mglMetalCreateTexture.
%
% % Create and show a blank texture.
% mglOpen(0);
% mglVisualAngleCoordinates(57,[16 12]);
% image = ones(200, 200, 4);
% imageTex = mglMetalCreateTexture(image);
% mglMetalBltTexture(imageTex,[0 0]);
% mglFlush();
%
% % Render some ovals to the texture.
% mglMetalSetRenderTarget(imageTex);
% mglFillOval(-3:3, -3:3, [10 20],  [1 0 0]);
% mglFlush();
%
% % Restore the screen frame buffer as the render target.
% mglMetalSetRenderTarget();
%
% % Blt the updated texture to the screen.
% mglMetalBltTexture(imageTex,[0 0]);
% mglFlush();
%
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
