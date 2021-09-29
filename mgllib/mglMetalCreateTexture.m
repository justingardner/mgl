% mglMetalCreateTexture.m
%
%       usage: mglMetalCreateTexture(im)
%          by: justin gardner
%        date: 09/28/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Private mglMetal function to send texture information
%              to mglMetal application and return a structure to be
%              used with mglMetalBltTexture to display - these
%              functions are called by mglCreateTexture and mglBltTexture
%       e.g.:
%
function tex = mglMetalCreateTexture(im)

global mgl

[tex.imageWidth tex.imageHeight tex.colorDim] = size(im);

% for now, imageWidth needs to be 16 byte aligned to 256
imageWidth = ceil(tex.imageWidth*16/256)*16;
if imageWidth ~= tex.imageWidth
  keyboard
  newim = zeros([imageWidth tex.imageHeight tex.colorDim]);
  newim(1:tex.imageWidth,1:tex.imageHeight,:) = im;
  % and reset to this new padded image
  im = newim;
  tex.imageWidth = imageWidth;
end

% get dimensions of texture
%[tex.imageWidth tex.imageHeight tex.colorDim] = size(im);
im = shiftdim(im,2);

% send texture command
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.createTexture));

% sent texture dimensions
mgl.s = mglSocketWrite(mgl.s,uint32(tex.imageWidth));
mgl.s = mglSocketWrite(mgl.s,uint32(tex.imageHeight));

% sent texture
mglSetParam('verbose',1);
mgl.s = mglSocketWrite(mgl.s,single(im(:)));
mglSetParam('verbose',0);

% end profiling
mglProfile('end','mglCreateTexture');

% set the texture
tex.textureNumber= 1;

% set the textureType (this was used in openGL to differntiate 1D and 2D textures)
tex.textureType = 1;
