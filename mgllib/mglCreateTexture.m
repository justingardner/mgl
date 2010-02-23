% mglCreateTexture.m
%
%        $Id$
%      usage: mglCreateTexture(image)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Create a texture for display on the screen with mglBltTexture
%             image can either be grayscale nxm, color nxmx3 or
%             color+alpha nxmx4. 
% 
%       e.g.: mglOpen;
%             mglClearScreen
%             mglScreenCoordinates
%             texture = mglCreateTexture(round(rand(100,100)*255));
%             mglBltTexture(texture,[0 0]);
%             mglFlush;
%
%             Note that you can use 1D textures for example to display a 1D image like a sine wave grating
%       e.g.: mglOpen;
%             mglClearScreen(0.5)
%             mglScreenCoordinates
%             x = 0:8*pi/99:8*pi;
%             texture = mglCreateTexture(255*(sin(x)+1)/2);
%             mglBltTexture(texture,[0 0 100 500]);
%             mglFlush;
%
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

% set all the params into a single array for quick access
% note that this also keeps the device to pixel transforms
% which _could_ change if you change coordinates
texture.allParams = [texture.textureNumber texture.imageWidth ...
		    texture.imageHeight textureAxes ...
		    texture.hFlip texture.vFlip 0 0 mglGetParam('xPixelsToDevice') ...
		    mglGetParam('yPixelsToDevice') mglGetParam('deviceHDirection') ...
		    mglGetParam('deviceVDirection') mglGetParam('verbose') texture.textureType];

% increment the texture count
mglSetParam('numTextures',mglGetParam('numTextures')+1);
