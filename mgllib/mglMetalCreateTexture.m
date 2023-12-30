% mglMetalCreateTexture.m
%
%       usage: [tex, ackTime, processedTime] = mglMetalCreateTexture(im, [minMagFilter, mipFilter, addressMode])
%          by: justin gardner
%        date: 09/28/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Private mglMetal function to send texture information
%              to mglMetal application and return a structure to be
%              used with mglMetalBltTexture to display - these
%              functions are called by mglCreateTexture and mglBltTexture.
%
%              im -- m x n x 4 rgba single precision float image.
%              minMagFilter -- optional value to choose sampler filtering:
%                              0: nearest
%                              1: linear (default)
%              mipFilter -- optional value to choose sampler filtering:
%                              0: not mipmapped
%                              1: nearest
%                              2: linear (default)
%              addressMode -- optional value to choose sampler addressing:
%                              0: clamp to edge
%                              1: mirror clamp to edge
%                              2: repeat (default)
%                              3: mirror repeat
%                              4: clamp to zero
%                              5: clamp to border color
%
%              Returns a struct array of texture info for use with other
%              mgl texture functions, like mglMetalBltTexture.
% 
%              If multiple sockets have been activated with mglMirrorOpen
%              and/or mglMirrorActivate, returns a struct arrauy with one
%              element per active mirror.
%
function [tex, ackTime, processedTime] = mglMetalCreateTexture(im, minMagFilter, mipFilter, addressMode, socketInfo)

% empty image, nothing to do.
if isempty(im)
  tex = [];
  ackTime = mglGetSecs;
  processedTime = mglGetSecs;
  return
end

if nargin < 2 || isempty(minMagFilter)
    minMagFilter = 1;
end

if nargin < 3 || isempty(mipFilter)
    mipFilter = 2;
end

if nargin < 4 || isempty(addressMode)
    addressMode = 2;
end

global mgl
if nargin < 5 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

[tex.imageHeight, tex.imageWidth, tex.colorDim] = size(im);
if (tex.colorDim ~= 4)
    error('(mglMetalCreateTexture) im must be mxnx4 rgba float.\n')
end

% set the textureType (this was used in openGL to differntiate 1D and 2D textures)
tex.textureType = 1;

% set sampler configuration
tex.minMagFilter = minMagFilter;
tex.mipFilter = mipFilter;
tex.addressMode = addressMode;

% Rearrange the image data into the Metal texture format.
% See the corresponding rearragement in mglMetalReadTexture.
%
% Some explanation:
% Matlab images are idexed by (row, column, channel),
% When serialized they traverse rows and columns first and look like this:
%   [R1, R2, R3, ..., G1, G2, G3, ..., B1, B2, B3, ..., A1, A2, A3, ... ]
% The first thing that comes out complete is the entire red channel, for
% all pixels.
%
% In Metal we want to get complete pixels at a time, more like this:
%   [R1, G1, B1, A1, R2, G2, B2, A1, R3, G3, B3, A3 ... ]
% So we swap the dimensions to be indexed by (channel, column, row)
% That way when serialized we traverse channel and column first.
im = permute(im, [3,2,1]);

% Send the texture create command and image data to each socket.
mglSocketWrite(socketInfo, socketInfo(1).command.mglCreateTexture);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(tex.imageWidth));
mglSocketWrite(socketInfo, uint32(tex.imageHeight));
mglSocketWrite(socketInfo, single(im(:)));

% Check each socket for processing results.
responseIncoming = mglSocketRead(socketInfo, 'double');
tex = repmat(tex, 1, numel(socketInfo));
processedTime = zeros([1, numel(socketInfo)]);
numTextures = zeros([1, numel(socketInfo)]);
for ii = 1:numel(socketInfo)
    if (responseIncoming(ii) < 0)
        % This socket shows an error processing the command.
        tex(ii).textureNumber = -1;
        processedTime(ii) = mglSocketRead(socketInfo(ii), 'double');
        fprintf('(mglMetalCreateTexture) Error creating Metal texture, you might try again with Console running, or: log stream --level info --process mglMetal\n');
    else
        % This socket shows processing was OK, read the response.
        tex(ii).textureNumber = mglSocketRead(socketInfo(ii), 'uint32');
        numTextures(ii) = mglSocketRead(socketInfo(ii), 'uint32');
        processedTime(ii) = mglSocketRead(socketInfo(ii), 'double');
    end

    % Only update the mgl context from the primary window.
    if isequal(socketInfo(ii), mgl.s)
        mglSetParam('numTextures', numTextures(ii));
    end
end
