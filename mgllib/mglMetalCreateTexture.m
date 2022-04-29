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
function [tex, ackTime, processedTime] = mglMetalCreateTexture(im, minMagFilter, mipFilter, addressMode)

if nargin < 2
    minMagFilter = 1;
end

if nargin < 3
    mipFilter = 2;
end

if nargin < 4
    addressMode = 2;
end

global mgl

[tex.imageHeight, tex.imageWidth, tex.colorDim] = size(im);
if (tex.colorDim ~= 4)
    error('(mglMetalCreateTexture) im must be mxnx4 rgba float.\n')
end

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

% send texture command
mglSocketWrite(mgl.s, mgl.command.mglCreateTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(tex.imageWidth));
mglSocketWrite(mgl.s, uint32(tex.imageHeight));
mglSocketWrite(mgl.s, single(im(:)));
tex.textureNumber = mglSocketRead(mgl.s, 'uint32');
numTextures = mglSocketRead(mgl.s, 'uint32');
processedTime = mglSocketRead(mgl.s, 'double');

mglSetParam('numTextures', numTextures);

% set the textureType (this was used in openGL to differntiate 1D and 2D textures)
tex.textureType = 1;

% set sampler configuration
tex.minMagFilter = minMagFilter;
tex.mipFilter = mipFilter;
tex.addressMode = addressMode;
