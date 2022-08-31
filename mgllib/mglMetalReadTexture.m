% mglMetalReadTexture.m
%
%       usage: [im, ackTime, processedTime] = mglMetalReadTexture(tex)
%          by: Ben Heasly
%        date: 03/04/2022
%   copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: read texture data from mglMetal, back into a Matlab image.
%       usage:
%
%             % Create and show a random texture in mglMetal.
%             mglOpen();
%             mglVisualAngleCoordinates(57,[16 12]);
%             image = ones(256, 256, 4);
%             image(:,:,1:3) = rand([256, 256, 3]);
%             imageTex = mglMetalCreateTexture(image);
%             mglMetalBltTexture(imageTex,[0 0]);
%             mglFlush();
%
%             % Read back the same texture and display it in Matlab, too.
%             imageAgain = mglMetalReadTexture(imageTex);
%             imshow(imageAgain(:,:,1:3));
%
%             Returns a matrix of RGBA image data with size
%             [height, width, 4].
% 
%             If multiple sockets have been activated with mglMirrorOpen
%             and/or mglMirrorActivate, the returned image matrix will have
%             an extra dimension indicating which mirror the image came from
%             [height, width, 4, mirorIndex].
%
function [im, ackTime, processedTime] = mglMetalReadTexture(tex, socketInfo)

if numel(tex) > 1
    fprintf('(mglMetalReadTexture) Only using the first of %d elements of tex struct array.  To avoid this warning pass in tex(1) instead.\n', numel(tex));
    tex = tex(1);
end

if nargin < 2 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% Send the texture read command to each socket.
mglSocketWrite(socketInfo, socketInfo(1).command.mglReadTexture);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, tex.textureNumber);

% Check each socket for processing results.
responseIncoming = mglSocketRead(socketInfo, 'double');
processedTime = zeros([1, numel(socketInfo)]);
textureData = zeros([4, tex.imageWidth, tex.imageHeight, numel(socketInfo)]);
for ii = 1:numel(socketInfo)
    if (responseIncoming(ii) < 0)
        % This socket shows an error processing the command.
        processedTime(ii) = mglSocketRead(socketInfo(ii), 'double');
        fprintf("(mglMetalReadTexture) Error reading Metal texture, you might try again with Console running, or: log stream --level info --process mglMetal\n");
    else
        % This socket shows processing was OK, read the image data.
        width = mglSocketRead(socketInfo(ii), 'uint32');
        height = mglSocketRead(socketInfo(ii), 'uint32');
        if (width ~= tex.imageWidth || height ~= tex.imageHeight)
            fprintf("(mglMetalReadTexture) Unexpected size for textureNumber %d -- expected width %d but got %d, expected height %d but got %d\n", tex.textureNumber, tex.imageWidth, width, tex.imageHeight, height);
        end
        textureData(:,:,:,ii) = mglSocketRead(socketInfo(ii), 'single', 4, width, height);
        processedTime(ii) = mglSocketRead(socketInfo(ii), 'double');
    end
end


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
im = permute(textureData, [3,2,1,4]);
