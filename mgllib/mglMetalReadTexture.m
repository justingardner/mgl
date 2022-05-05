% mglMetalReadTexture.m
%
%       usage: [im, ackTime, processedTime] = mglMetalReadTexture(tex)
%          by: Ben Heasly
%        date: 03/04/2022
%   copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: read texture data from mglMetal, back into a Matlab image.
%       usage:
%
% % Create and show a random texture in mglMetal.
% mglOpen();
% mglVisualAngleCoordinates(57,[16 12]);
% image = ones(256, 256, 4);
% image(:,:,1:3) = rand([256, 256, 3]);
% imageTex = mglMetalCreateTexture(image);
% mglMetalBltTexture(imageTex,[0 0]);
% mglFlush();
%
% % Read back the same texture and display it in Matlab, too.
% imageAgain = mglMetalReadTexture(imageTex);
% imshow(imageAgain(:,:,1:3));
%
function [im, ackTime, processedTime] = mglMetalReadTexture(tex)

global mgl

% Request a texture to be written to the socket.
mglSocketWrite(mgl.s, mgl.command.mglReadTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, tex.textureNumber);

% Check if the command was processed OK or with error.
responseIncoming = mglSocketRead(mgl.s, 'double');
if (responseIncoming < 0)
    im = [];
    processedTime = mglSocketRead(mgl.s, 'double');
    disp('Error reading Metal texture, you might try again with Console running, or: log stream --level info --process mglMetal')
    return
end

% Processing was OK, read the response.

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
% indexing scheme like (channel, column, row), where channel is the
% fastest-moving dimension, then column, then row.
%
% But Matlab images are idexed by (row, column, channel).
% When serialized they would have row and column as the fastest-moving:
%   [R1, R2, R3, ..., G1, G2, G3, ..., B1, B2, B3, ..., A1, A2, A3, ... ]
% And we get a whole channel at a time.
% So we swap the dimensions to be indexed in Matlab image order.
im = permute(textureData, [3,2,1]);
