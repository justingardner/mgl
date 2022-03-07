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

% Rearrange the textre data into the Matlab image format.
% See the corresponding rearragement in mglMetalCreateTexture.
%
% Some explanation:
% When Metal textures are serialized they come out like this:
%   [R1, G1, B1, A1, R2, G2, B2, A1, R3, G3, B3, A3 ... ]
% This gives one complete pixel at a time.  This corresponds to a matrix
% indexing scheme like (channel, row, column), where channel is the
% fastest-moving dimension.
%
% But Matlab images are idexed by (row, column, channel).
% When serialized they would have row and column as the fastest-moving:
%   [R1, R2, R3, ..., G1, G2, G3, ..., B1, B2, B3, ..., A1, A2, A3, ... ]
% And we get a whole channel at a time.
% So we swap the dimensions to be indexed in Matlab image order.
im = permute(textureData, [3,2,1]);
