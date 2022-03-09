% mglMetalBltTexture.m
%
%       usage: [ackTime, processedTime] = mglMetalBltTexture(tex)
%          by: justin gardner
%        date: 09/28/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Private mglMetal function to blt texture created by
%              mglMetalBltTexture these functions are
%              called by mglCreateTexture and mglBltTexture
%       e.g.:
%
function [ackTime, processedTime] = mglMetalBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height)

global mgl

% default arguments
if nargin < 2, position = [0 0]; end
if nargin < 3, hAlignment = 0; end
if nargin < 4, vAlignment = 0; end
if nargin < 5, rotation = 0; end
if nargin < 6, phase = 0; end
if nargin < 7, width = 1; end
if nargin < 8, height = 1; end

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

% send blt command
mglSocketWrite(mgl.s, mgl.command.mglBltTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nVertices));
mglSocketWrite(mgl.s, single(verticesWithTextureCoordinates));
mglSocketWrite(mgl.s, single(phase));
mglSocketWrite(mgl.s, tex.textureNumber);
processedTime = mglSocketRead(mgl.s, 'double');
