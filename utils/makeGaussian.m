% makeGaussian.m
%
%      usage: makeGaussian(width,height,sdx,sdy)
%         by: justin gardner
%       date: 09/14/06
%    purpose: make a 2D gaussian, useful for making gabors for
%             instance. Set mglVisualAngleCoordinates before
%             using.
%
%             width, height, sdx and sdy are in degrees of visual angle
%       e.g.:
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglClearScreen(0.5);
% grating = makeGrating(10,10,1.5,45,0);
% gaussian = makeGaussian(10,10,1,1); 
% gabor = 255*(grating.*gaussian+1)/2;
% tex = mglCreateTexture(gabor);
% mglBltTexture(tex,[0 0]);
% mglFlush;
function m = makeGaussian(width,height,sdx,sdy)

% check arguments
m = [];
if ~any(nargin == [4])
  help makeGrating
  return
end

global MGL;

if ~isfield(MGL,'xDeviceToPixels') || ~isfield(MGL,'yDeviceToPixels')
  disp(sprintf('(makeGaussian) MGL is not initialized'));
  return
end

% get size in pixels
widthPixels = round(width*MGL.xDeviceToPixels);
heightPixels = round(height*MGL.yDeviceToPixels);
widthPixels = widthPixels + mod(widthPixels+1,2);
heightPixels = heightPixels + mod(heightPixels+1,2);

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -width/2:width/(widthPixels-1):width/2;
y = -height/2:height/(heightPixels-1):height/2;
[xMesh,yMesh] = meshgrid(x,y);

% compute gaussian window
m = exp(-((xMesh.^2)/(2*(sdx^2))+(yMesh.^2)/(2*(sdy^2))));
% clamp small values to 0 so that we fade completely to gray.
m(m(:)<0.01) = 0;