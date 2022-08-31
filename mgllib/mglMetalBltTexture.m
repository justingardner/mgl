% mglMetalBltTexture.m
%
%       usage: [ackTime, processedTime, setupTime] = mglMetalBltTexture(tex)
%          by: justin gardner
%        date: 09/28/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Private mglMetal function to blt texture created by
%              mglMetalCreateTexture.  These these functions are
%              called by mglCreateTexture and mglBltTexture.
%       usage:
%
% mglOpen();
% mglVisualAngleCoordinates(57,[16 12]);
% image = ones(200, 200, 4);
% image(:,:,1:3) = rand([200, 200, 3]);
% imageTex = mglMetalCreateTexture(image);
% mglMetalBltTexture(imageTex,[0 0]);
% mglFlush();
%
function [ackTime, processedTime, setupTime] = mglMetalBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height, socketInfo)

if numel(tex) > 1
    fprintf('(mglMetalBltTexture) Only using the first of %d elements of tex struct array.  To avoid this warning pass in tex(1) instead.\n', numel(tex));
    tex = tex(1);
end

% default arguments
if nargin < 2, position = [0 0]; end
if nargin < 3, hAlignment = 0; end
if nargin < 4, vAlignment = 0; end
if nargin < 5, rotation = 0; end
if nargin < 6, phase = 0; end
if nargin < 7
    if length(position)<3
        % get width in device coordinates
        width = tex.imageWidth*mglGetParam('xPixelsToDevice');
    else
        width = position(3);
    end
end
if nargin < 8
    if length(position)<4
        % get height in device coordinates
        height = tex.imageHeight*mglGetParam('yPixelsToDevice');
    else
        height = position(4);
    end
end

if nargin < 9 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% get coordinates for each corner
% of the rectangle we are going
% to put the texture on
coords =[width/2 height/2;
    -width/2 height/2;
    -width/2 -height/2;
    width/2 -height/2]';

% rotate coordinates if needed
if ~isequal(mod(rotation,360),0)
    r = pi*rotation/180;
    rotmatrix = [cos(r) -sin(r);sin(r) cos(r)];
    coords = rotmatrix * coords;
end

% handle alignment
switch(hAlignment)
    case {-1}
        position(1) = position(1)+width/2;
    case {1}
        position(1) = position(1)-width/2;
end
switch(vAlignment)
    case {1}
        position(2) = position(2)+height/2;
    case {-1}
        position(2) = position(2)-height/2;
end

% set translation
coords(1,:) = coords(1,:)+position(1);
coords(2,:) = coords(2,:)+position(2);

% now create vertices for 2 triangles to
% represent the rectangle for the texture
% with appropriate texture coordinates
% Note: Metal texture coordinates have +Y going down, opposite of vertices!
verticesWithTextureCoordinates = [...
    coords(1,1) coords(2,1) 0 1 0;
    coords(1,2) coords(2,2) 0 0 0;
    coords(1,3) coords(2,3) 0 0 1;

    coords(1,1) coords(2,1) 0 1 0;
    coords(1,3) coords(2,3) 0 0 1;
    coords(1,4) coords(2,4) 0 1 1;
    ]';

% number of vertices
nVertices = 6;

% Default to linear min/mag and mip filtering.
minMagFilter = 1;
if (isfield(tex, 'minMagFilter'))
    minMagFilter = tex.minMagFilter;
end

mipFilter = 2;
if (isfield(tex, 'mipFilter'))
    mipFilter = tex.mipFilter;
end

% Default to wrapping address mode.
addressMode = 2;
if (isfield(tex, 'addressMode'))
    addressMode = tex.addressMode;
end

% Setup timestamp can be used for measuring MGL frame timing,
% for example with mglTestRenderingPipeline.
setupTime = mglGetSecs();

% send blt command
mglSocketWrite(socketInfo, socketInfo(1).command.mglBltTexture);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(minMagFilter));
mglSocketWrite(socketInfo, uint32(mipFilter));
mglSocketWrite(socketInfo, uint32(addressMode));
mglSocketWrite(socketInfo, uint32(nVertices));
mglSocketWrite(socketInfo, single(verticesWithTextureCoordinates));
mglSocketWrite(socketInfo, single(phase));
mglSocketWrite(socketInfo, tex.textureNumber);
processedTime = mglSocketRead(socketInfo, 'double');
