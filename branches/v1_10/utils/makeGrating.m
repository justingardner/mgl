% makeGrating.m
%
%      usage: makeGrating(width,height,sf,angle,phase)
%         by: justin gardner
%       date: 09/14/06
%    purpose: create a 2D grating. You should start MGL
%             and set to visual angle coordinates frist.
%             angle and phase are in degrees
%
function m = makeGrating(width,height,sf,angle,phase)

% check arguments
if ~any(nargin == [3 4 5])
  help makeGrating
  return
end

if ~exist('sf','var'),sf = 1;end
if ~exist('angle','var'),angle = 0;end
if ~exist('phase','var'),phase = 0;end

% make it so that angle of 0 is horizontal
angle = angle-90;

global MGL;

if ~isfield(MGL,'xDeviceToPixels') || ~isfield(MGL,'yDeviceToPixels')
  disp(sprintf('(makeGrating) MGL is not initialized'));
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

% calculate image parameters
phase = pi*phase/180;
angle = pi*angle/180;
a=cos(angle)*sf*2*pi;
b=sin(angle)*sf*2*pi;
% compute grating
m = cos(a*xMesh+b*yMesh+phase);
