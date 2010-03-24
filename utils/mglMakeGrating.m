% mglMakeGrating.m
%
%      usage: mglMakeGrating(width,height,sf,angle,phase,<xDeg2pix>,<yDeg2pix>)
%         by: justin gardner
%       date: 09/14/06
%    purpose: create a 2D grating. You should start mgl
%             and use mglVisualAngleCoordinates before using.
%
%             width and height are in degrees of visual angle
%             sf is in cycles/degrees
%             angle and phase are in degrees
%
%             xDeg2pix and yDeg2pix are optional arguments that specify the
%             number of pixels per visual angle in the x and y dimension, respectively.
%             If not specified, these values are derived from the open mgl screen (make
%             sure you set mglVisualAngleCoordinates).
%       e.g.:
%
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% g = mglMakeGrating(16,12,1.5,45,0);
% g = 255*(g+1)/2;
% tex = mglCreateTexture(g);
% mglBltTexture(tex,[0 0]);
% mglFlush;

function m = mglMakeGrating(width,height,sf,angle,phase,xDeg2pix,yDeg2pix)

% check arguments
m = [];
if ~any(nargin == [3 4 5 6 7])
  help mglMakeGrating
  return
end

if ieNotDefined('sf'),sf = 1;end
if ieNotDefined('angle'),angle = 0;end
if ieNotDefined('phase'),phase = 0;end

% make it so that angle of 0 is horizontal
angle = angle-90;


% defaults for xDeg2pix
if ieNotDefined('xDeg2pix')
  if isempty(mglGetParam('xDeviceToPixels'))
    disp(sprintf('(mglMakeGrating) mgl is not initialized'));
    return
  end
  xDeg2pix = mglGetParam('xDeviceToPixels');
end

% defaults for yDeg2pix
if ieNotDefined('yDeg2pix')
  if isempty(mglGetParam('yDeviceToPixels'))
    disp(sprintf('(mglMakeGrating) mgl is not initialized'));
    return
  end
  yDeg2pix = mglGetParam('yDeviceToPixels');
end


% get size in pixels
widthPixels = round(width*xDeg2pix);
heightPixels = round(height*yDeg2pix);
widthPixels = widthPixels + mod(widthPixels+1,2);
heightPixels = heightPixels + mod(heightPixels+1,2);

% calculate image parameters
phase = pi*phase/180;

% if height is nan, it means we should calculate a 1 dimensional grating
if isnan(height)
  % 1D grating (note we ignore orientation)
  x = -width/2:width/(widthPixels-1):width/2;
  m = cos(x*sf*2*pi+phase);
else
  % 2D grating
  % calculate orientation
  angle = pi*angle/180;
  a=cos(angle)*sf*2*pi;
  b=sin(angle)*sf*2*pi;

  % get a grid of x and y coordinates that has 
  % the correct number of pixels
  x = -width/2:width/(widthPixels-1):width/2;
  y = -height/2:height/(heightPixels-1):height/2;
  [xMesh,yMesh] = meshgrid(x,y);

  % compute grating
  m = cos(a*xMesh+b*yMesh+phase);
end
