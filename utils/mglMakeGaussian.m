% mglMakeGaussian.m
%
%      usage: mglMakeGaussian(width,height,sdx,sdy,<xCenter>,<yCenter>,<xDeg2pix>,<yDeg2pix>)
%         by: justin gardner
%       date: 09/14/06
%    purpose: make a 2D gaussian, useful for making gabors for
%             instance. Set mglVisualAngleCoordinates before
%             using.
%
%             width, height, sdx and sdy are in degrees of visual angle
%
%             xcenter and ycenter are optional arguments in degrees of visual angle
%             and default to 0,0
%
%             xDeg2pix and yDeg2pix are optional arguments that specify the
%             number of pixels per visual angle in the x and y dimension, respectively.
%             If not specified, these values are derived from the open mgl screen (make
%             sure you set mglVisualAngleCoordinates).
%       e.g.:
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglClearScreen(0.5);
% grating = mglMakeGrating(10,10,1.5,45,0);
% gaussian = mglMakeGaussian(10,10,1,1); 
% gabor = 255*(grating.*gaussian+1)/2;
% tex = mglCreateTexture(gabor);
% mglBltTexture(tex,[0 0]);
% mglFlush;
function [m xMesh yMesh] = mglMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix)

% check arguments
m = [];
if ~any(nargin == [4 5 6 7 8])
  help mglMakeGaussian
  return
end

if ieNotDefined('xCenter'),xCenter = 0;end
if ieNotDefined('yCenter'),yCenter = 0;end

% defaults for xDeg2pix
if ieNotDefined('xDeg2pix')
  if isempty(mglGetParam('xDeviceToPixels'))
    disp(sprintf('(makeGrating) mgl is not initialized'));
    return
  end
  xDeg2pix = mglGetParam('xDeviceToPixels');
end

% defaults for yDeg2pix
if ieNotDefined('yDeg2pix')
  if isempty(mglGetParam('yDeviceToPixels'))
    disp(sprintf('(makeGrating) mgl is not initialized'));
    return
  end
  yDeg2pix = mglGetParam('yDeviceToPixels');
end

% get size in pixels
widthPixels = round(width*xDeg2pix);
heightPixels = round(height*yDeg2pix);
widthPixels = widthPixels + mod(widthPixels+1,2);
heightPixels = heightPixels + mod(heightPixels+1,2);

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -width/2:width/(widthPixels-1):width/2;
y = -height/2:height/(heightPixels-1):height/2;
[xMesh,yMesh] = meshgrid(x,y);

% compute gaussian window
m = exp(-(((xMesh-xCenter).^2)/(2*(sdx^2))+((yMesh-yCenter).^2)/(2*(sdy^2))));
% clamp small values to 0 so that we fade completely to gray.
m(m(:)<0.01) = 0;
