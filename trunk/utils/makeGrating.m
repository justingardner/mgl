% makeGrating.m
%
%      usage: makeGrating()
%         by: justin gardner
%       date: 09/14/06
%    purpose: 
%
function m = makeGrating(width,height,angle,phase,sf)

% check arguments
if ~any(nargin == [5])
  help makeGrating
  return
end

global MGL;

if ~isfield(MGL,'xDeviceToPixels') || ~isfield(MGL,'yDeviceToPixels')
  disp(sprintf('(makeGrating) MGL is not initialized'));
  return
end

% get size in pixels
widthPixels = round(width*MGL.xDeviceToPixels);
heightPixels = round(height*MGL.yDeviceToPixels);

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -width/2:width/(widthPixels-1):width/2;
y = -height/2:height/(heightPixels-1):height/2;
[xMesh,yMesh] = meshgrid(x,y);

% calculate image parameters
phase = pi*phase/180;
angle = pi*angle/180;
a=cos(angle)*sf*2*pi;
b=sin(angle)*sf*2*pi;
% compute grating
m = sin(a*xMesh+b*yMesh+phase);
m = 255*(m+1)/2;
% compute gaussian window
%win = exp(-((xMesh.^2)/((texWidth/5)^2)+(yMesh.^2)/((texHeight/5)^2)));
% clamp small values to 0 so that we fade completely to gray.
%win(win(:)<0.01) = 0;
% now create and RGB + alpha image with the gaussian window
% as the alpha channel
%  m4(:,:,1) = m;
%  m4(:,:,2) = m;
%  m4(:,:,3) = m;
%  m4(:,:,4) = 255*win;
% now create the texture
%tex(i) = mglCreateTexture(m4);
