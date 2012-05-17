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
%             For fast creation (this routine can take some time to convert
%             the matlab matrix to the format necessary for OpenGL) you can
%             pass in a uint8 texture preformatted for OpenGL. This should
%             be an rgba x width x height matrix.
%       e.g.: mglOpen;
%             mglScreenCoordinates;
%             mglClearScreen;
%             r = uint8(floor(rand(3,250,150)*256));
%             r(4,:,:) = 255;
%             tex = mglCreateTexture(r);
%             mglBltTexture(tex,[mglGetParam('screenWidth')/2 mglGetParam('screenHeight')/2]);
%             mglFlush;
%
function texture = mglCreateTexture(image, axes, liveBuffer, textureParams)

global yowsa;
yowsa = image;

% create the texture
if nargin == 4
  % Verify the texture params are correct and convert them to a format that
  % the private function understands.
  textureParams = parseTextureParams(textureParams);

  texture = mglPrivateCreateTexture(image, axes, liveBuffer, textureParams);
elseif nargin == 3
  texture = mglPrivateCreateTexture(image,axes,liveBuffer);
elseif nargin == 2
  texture = mglPrivateCreateTexture(image,axes);
elseif nargin == 1
  texture = mglPrivateCreateTexture(image);
else
  help mglCreateTexture;
  return
end
if isempty(texture),return,end

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


% This function takes a cell array of texture options and then converts
% them into a format that the mex file understands (a simple array of
% values).
function tParams = parseTextureParams(textureParams)
persistent wrapStruct magFilterStruct minFilterStruct;

if isempty(wrapStruct)
	% These structs define some of the OpenGL texture parameter constants.
	wrapStruct = struct('key', {'GL_CLAMP', 'GL_REPEAT', 'GL_CLAMP_TO_EDGE'}, ...
		'value', {10496, 10497, 33071});
	magFilterStruct = struct('key', {'GL_NEAREST', 'GL_LINEAR'}, 'value', {9728, 9729});
	minFilterStruct = struct('key', {'GL_NEAREST', 'GL_LINEAR', 'GL_NEAREST_MIPMAP_NEAREST', ...
		'GL_LINEAR_MIPMAP_NEAREST', 'GL_NEAREST_MIPMAP_LINEAR', 'GL_LINEAR_MIPMAP_LINEAR'}, ...
		'value', {9728, 9729, 9984, 9985, 9986, 9987});
end

% This is the default set of texture parameters.
tParams = [33071 33071 ... % GL_CLAMP_TO_EDGE
           9729 9729];     % GL_LINEAR

% Parse the texture params if they are available and convert them into
% double values.
if ~isempty(textureParams)
	for i = 1:2:length(textureParams)
		key = textureParams{i};
		value = textureParams{i+1};
		
		switch key
			case 'GL_TEXTURE_WRAP_S'
				j = strcmp(value, {wrapStruct.key});
				tParams(1) = wrapStruct(j).value;
				
			case 'GL_TEXTURE_WRAP_T'
				j = strcmp(value, {wrapStruct.key});
				tParams(2) = wrapStruct(j).value;
				
			case 'GL_TEXTURE_MAG_FILTER'
				j = strcmp(value, {magFilterStruct.key});
				tParams(3) = magFilterStruct(j).value;
				
			case 'GL_TEXTURE_MIN_FILTER'
				j = strcmp(value, {minFilterStruct.key});
				tParams(4) = minFilterStruct(j).value;
				
			otherwise
				error('Invalid key: %s', key);
		end
		
		% Check to see if we didn't find a matching value for the selected
		% key.
		if length(tParams) ~= 4
			error('Invalid value (%s) for key (%s)', value, key);
		end
	end
end
