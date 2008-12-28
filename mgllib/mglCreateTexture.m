% mglCreateTexture.m
%
%        $Id$
%      usage: mglCreateTexture(image)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Create a texture for display on the screen with mglBltTexture
%             image can either be grayscale nxm, color nxmx3 or
%             color+alpha nxmx4
% 
%       e.g.: mglOpen;
%             mglClearScreen
%             mglScreenCoordinates
%             texture = mglCreateTexture(round(rand(100,100)*255));
%             mglBltTexture(texture,[0 0]);
%             mglFlush;
function texture = mglCreateTexture(image,axes)

% create the texture
if nargin == 2
  texture = mglPrivateCreateTexture(image,axes);
elseif nargin == 1
  texture = mglPrivateCreateTexture(image);
else
  help mglCreateTexture;
  return
end

% add some fields that are only used by mglText.c
texture.textImageRect = [0 0 0 0];
texture.hFlip = 0;
texture.vFlip = 0;
texture.isText = 0;

% convert texture string into a nummber
if strcmp(texture.textureAxes,'xy')
  textureAxes = 1;
else
  textureAxes = 0;
end

% MGL global
global MGL;

% set all the params into a single array for quick access
% note that this also keeps the device to pixel transforms
% which _could_ change if you change coordinates
texture.allParams = [texture.textureNumber texture.imageWidth ...
		    texture.imageHeight textureAxes ...
		    texture.hFlip texture.vFlip 0 0 MGL.xPixelsToDevice ...
		    MGL.yPixelsToDevice MGL.deviceHDirection ...
		    MGL.deviceVDirection MGL.verbose];

% increment the texture count
MGL.numTextures = MGL.numTextures+1;
