% mglMetalSetRenderTarget.m
%
%      usage: results = mglMetalSetRenderTarget(tex)
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
function results = mglMetalSetRenderTarget(tex, socketInfo)

if (nargin < 1)
    renderTarget = uint32(0);
else
    if numel(tex) > 1
        fprintf('(mglMetalSetRenderTarget) Only using the first of %d elements of tex struct array.  To avoid this warning pass in tex(1) instead.\n', numel(tex));
        tex = tex(1);
    end
    renderTarget = tex.textureNumber;
end

if nargin < 2 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglSetRenderTarget);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, renderTarget);
results = mglReadCommandResults(socketInfo, ackTime);
