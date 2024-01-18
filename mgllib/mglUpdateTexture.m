% mglUpdateTexture.m
%
%        $Id$
%      usage: results = mglUpdateTexture(texture, image)
%         by: Benjamin Heasly
%       date: 03/18/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Update an existing texture's image contents.
%             texture - a texture struct from mglCreateTexture().
%             image - a new mxnx4 image of the same size as texture.
%
%             This is indended for when you want to update a texture as
%             fast as possible, say once per frame.  We can't avoid sending
%             the new image contents, but we can avoid allocating and
%             deleting a texture each time, which should improve speed and
%             memory usage.
%
%      usage:
%             mglOpen();
%
%             % Create a blank texture to start with.
%             blankImage = ones([480, 640, 4], 'single');
%             tex = mglMetalCreateTexture(blankImage);
%             mglBltTexture(tex,[0 0]);
%             mglFlush();
%
%             % Update the texture image contents.
%             x = linspace(0, 1, 640);
%             y = linspace(0, 1, 480);
%             gradient= y'*x;
%             newImage = ones([480, 640, 4], 'single');
%             newImage(:,:,1) = gradient;
%             newImage(:,:,2) = flipud(gradient);
%             newImage(:,:,3) = fliplr(gradient);
%             mglUpdateTexture(tex, newImage);
%             mglBltTexture(tex,[0 0]);
%             mglFlush();
%
function results = mglUpdateTexture(tex, im, socketInfo)

if numel(tex) > 1
    fprintf('(mglUpdateTexture) Only using the first of %d elements of tex struct array.  To avoid this warning pass in tex(1) instead.\n', numel(tex));
    tex = tex(1);
end

if nargin < 2
    help mglUpdateTexture
    return
end

if nargin < 3 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

[newHeight, newWidth, newSlices] = size(im);
if (newHeight ~= tex.imageHeight || newWidth ~= tex.imageWidth || newSlices ~= tex.colorDim)
    fprintf('(mglUpdateTexture) New image size [%d x %d x %d] must match the existing texture size [%d x %d x %d].\n', ...
        newHeight, newWidth, newSlices, tex.imageHeight, tex.imageWidth, tex.colorDim)
    help mglUpdateTexture
    return
end

% Rearrange the image data into the Metal texture format.
% mglMetalCreateTexture has additional commentary on this!
im = permute(im, [3,2,1]);

mglSocketWrite(socketInfo, socketInfo(1).command.mglUpdateTexture);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(tex.textureNumber));
mglSocketWrite(socketInfo, uint32(newWidth));
mglSocketWrite(socketInfo, uint32(newHeight));
mglSocketWrite(socketInfo, single(im(:)));
results = mglReadCommandResults(socketInfo, ackTime);

