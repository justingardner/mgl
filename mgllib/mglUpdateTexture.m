% mglUpdateTexture.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglUpdateTexture(texture, image)
%         by: Benjamin Heasly
%       date: 03/18/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Update an existing texture's image contents.
%             texture - a texture struct from mglCreateTexture().
%             image - a new mxnx4 image of the same size as texture.
%
function [ackTime, processedTime] = mglUpdateTexture(texture, im)

if nargin ~= 2
    help mglUpdateTexture
    return
end

[newHeight, newWidth, newSlices] = size(im);
if (newHeight ~= texture.imageHeight || newWidth ~= texture.imageWidth || newSlices ~= texture.colorDim)
    fprintf('(mglUpdateTexture) New image size [%d x %d x %d] must be match the existing texture size [%d x %d x %d].\n', ...
        newHeight, newWidth, newSlices, texture.imageHeight, texture.imageWidth, texture.colorDim)
    help mglUpdateTexture
    return
end

% Rearrange the image data into the Metal texture format.
% mglMetalCreateTexture has additional commentary on this!
im = permute(im, [3,2,1]);

global mgl
mglSocketWrite(mgl.s, mgl.command.mglUpdateTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(texture.textureNumber));
mglSocketWrite(mgl.s, uint32(newWidth));
mglSocketWrite(mgl.s, uint32(newHeight));
mglSocketWrite(mgl.s, single(im(:)));
processedTime = mglSocketRead(mgl.s, 'double');
