% mglCreateTexture.m
%
%        $Id$
%      usage: [texture, ackTime, processedTime] = mglCreateTexture(image)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Create a texture for display on the screen.
%             Image should be m x n x 4 RGBA.
%             Please seen mglMetalCreateTexture().
%
function [texture, ackTime, processedTime] = mglCreateTexture(image, axes, liveBuffer, textureParams)

persistent warnOnce
if nargin > 1 && warnOnce
    fprintf('(mglCreateTexture) mglCreateTexture no longer supports arguments axes, liveBuffer, or textureParams.  Please see mglMetalCreateTexture.\n');
    warnOnce = false;
end

[texture, ackTime, processedTime] = mglMetalCreateTexture(image);
