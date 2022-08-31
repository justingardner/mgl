% mglCreateTexture.m
%
%        $Id$
%      usage: [texture, ackTime, processedTime] = mglCreateTexture(image)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Create a texture for display on the screen.
%             Image should be m x n x 4 RGBA.
%             Please see mglMetalCreateTexture().
%       e.g.: mglOpen;
%             mglClearScreen
%             mglScreenCoordinates
%             texture = mglCreateTexture(round(rand(100,100)*255));
%             mglBltTexture(texture,[0 0]);
%             mglFlush;
%
%             *******************
%             The below are included for backwards compatibilty, but are
%             not yet fully functioning in metal (i.e. they just convert
%             the image to the standard format and render)
%             *******************
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
function [texture, ackTime, processedTime] = mglCreateTexture(image, axes, liveBuffer, textureParams, socketInfo)

persistent warnOnce
if isempty(warnOnce) warnOnce = true; end
if nargin > 1 && warnOnce
    fprintf('(mglCreateTexture) mglCreateTexture no longer supports arguments axes, liveBuffer, or textureParams.  Please see mglMetalCreateTexture.\n');
    warnOnce = false;
end

if nargin < 5 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% check for uint textures (not yet supported by mglMetal
if isequal(class(image),'uint8')
    % shift dimensions as unit8 was 4xnxm (since that was the direct format
    % supported by OpenGL
    image = shiftdim(image,1);
    
    % need to convert to double
    disp(sprintf('(mglCreateTexture) uint8 images not yet supported in metal, converting to double'));
    image = double(image)/255;
end

% create texture used to be values from 0 - 255
maxVal = max(image(:));
if maxVal > 1
    % JG: THis is not a warning - this was the default behavior of mglCreateTexture
    %fprintf('(mglCreateTexture) image shold be float-valued with elements in [0 1].  Normalizing by 255\n');
    image = image / 255;
end

% check for grayscale image and convert to RGBA image
[imageHeight, imageWidth, imageSlices] = size(image);
if imageSlices == 1
    % JG: THis is not a warning - this was the default behavior to do
    % grayscale images
    %fprintf('(mglCreateTexture) image shold be h x w x 4 rgba.  Resizing (%d x %d) -> (%d x %d x 4).\n', imageHeight, imageWidth, imageHeight, imageWidth);
    image = cat(3, image, image, image, ones(size(image)));
elseif imageSlices == 3
    % convert RGB into RGBA
    image = cat(3, image, ones(size(image,1:2)));
end

[texture, ackTime, processedTime] = mglMetalCreateTexture(image, [], [], [], socketInfo);
