% mglMetalReadTexture.m
%
%       usage: [im, ackTime, processedTime] = mglMetalReadTexture(tex)
%          by: Ben Heasly
%        date: 03/04/2022
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: read texture data from mglMetal, back into a Matlab image.
%
function [im, ackTime, processedTime] = mglMetalReadTexture(tex)

global mgl

% Request a texture to be written to the socket.
mglSocketWrite(mgl.s, mgl.command.mglReadTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, tex.textureNumber);

% How big is the texture?
width = mglSocketRead(mgl.s, 'uint32');
height = mglSocketRead(mgl.s, 'uint32');
if (width * height == 0)
    fprintf("(mglMetalReadTexture) Invalid or empty texture for textureNumber %d -- width %d X height %d\n", tex.textureNumber, width, height);
    im = [];
    processedTime = mglSocketRead(mgl.s, 'double');
    return
end

% Read typed, sized texture matrix.
textureData = mglSocketRead(mgl.s, 'single', 4, width, height);
processedTime = mglSocketRead(mgl.s, 'double');

% Rearrange the texture data to Matlab image format.
% See the corresponding shift in mglMetalCreateTexture.
im = shiftdim(textureData, 1);
